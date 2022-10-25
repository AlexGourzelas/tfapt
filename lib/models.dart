import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

String? _toursBasePathCurrent;
Future<String>? _toursBasePathFut;
Future<String> get _toursBasePath async {
  return _toursBasePathFut ??= getApplicationSupportDirectory()
      .then((value) => p.join(value.path, "tours"))
      .then((value) => _toursBasePathCurrent = value);
}

const _hostUri = "https://evresi.netlify.app";

class TourSummary {
  TourSummary._({
    required this.id,
    required this.name,
    required this.thumbnail,
  });

  static final Uri _toursJsonUri = Uri.parse("$_hostUri/tours.json");

  static Future<List<TourSummary>> list() async {
    Response res = await get(_toursJsonUri);

    if (res.statusCode != 200) {
      throw Exception("Failed to get tours.json");
    }

    var json = jsonDecode(res.body);

    return TourSummary._parse(json);
  }

  static List<TourSummary> _parse(dynamic json) =>
      List.unmodifiable((json! as List<dynamic>).map(
        (eJson) => TourSummary._(
          id: eJson["id"]! as String,
          name: eJson["name"]! as String,
          thumbnail:
              AssetModel._parse(eJson["id"]! as String, eJson["thumbnail"]),
        ),
      ));

  final String id;
  final String name;
  final AssetModel? thumbnail;
}

class TourModel {
  TourModel._({
    required this.id,
    required this.name,
    required this.desc,
    required this.waypoints,
    required this.gallery,
    required this.pois,
    required this.path,
  });

  static Future<TourModel> load(String id) async {
    if (!await isDownloaded(id)) {
      await _download(id);
    }

    var tourJsonContent =
        await File(p.join(await _toursBasePath, id, "tour.json"))
            .readAsString();

    return TourModel._parse(id, jsonDecode(tourJsonContent));
  }

  static Future<bool> isDownloaded(String id) async {
    return await Directory(p.join(await _toursBasePath, id)).exists();
  }

  static Future<void> _download(String id) async {
    if (await isDownloaded(id)) {
      return;
    }

    var base = await _toursBasePath;

    await Directory(p.join(base, "$id.part", "assets")).create(recursive: true);

    await (_downloadToFile(Uri.parse("$_hostUri/$id/tiles.mbtiles"),
        outPath: p.join(base, "$id.part", "tiles.mbtiles")));
    var tourJsonStr =
        await _downloadToMemory(Uri.parse("$_hostUri/$id/tour.json"));
    await (_writeToFile(tourJsonStr,
        outPath: p.join(base, "$id.part", "tour.json")));
    var tour = _parse(id, jsonDecode(tourJsonStr));
    // now recursively download assets
    var assets = tour.gallery.followedBy(tour.waypoints
        .map((e) => [...e.gallery, if (e.narration != null) e.narration!])
        .reduce((a, b) => a + b));
    for (var asset in assets) {
      await (_downloadToFile(Uri.parse("$_hostUri/$id/assets/${asset.name}"),
          outPath: p.join(base, "$id.part", "assets", asset.name)));
    }

    await Directory(p.join(base, "$id.part")).rename(p.join(base, id));
  }

  static TourModel _parse(String tourId, dynamic json) => TourModel._(
        id: tourId,
        name: json["name"]! as String,
        desc: json["desc"]! as String,
        waypoints: List<WaypointModel>.unmodifiable(
            (json["waypoints"]! as List<dynamic>)
                .map((e) => WaypointModel._parse(tourId, e))),
        gallery: List<AssetModel>.unmodifiable(
            (json["gallery"]! as List<dynamic>)
                .map((e) => AssetModel._parse(tourId, e))),
        pois: List<PoiModel>.unmodifiable((json["pois"]! as List<dynamic>)
            .map((e) => PoiModel._parse(tourId, e))),
        path: List.unmodifiable(mtk.PolygonUtil.decode(json["path"]! as String)
            .map((e) => LatLng(e.latitude, e.longitude))),
      );

  final String id;
  final String name;
  final String desc;
  final List<WaypointModel> waypoints;
  final List<AssetModel> gallery;
  final List<PoiModel> pois;
  final List<LatLng> path;

  String get tilesPath => p.join(_toursBasePathCurrent!, id, "tiles.mbtiles");
}

class WaypointModel {
  WaypointModel._({
    required this.name,
    required this.desc,
    required this.lat,
    required this.lng,
    required this.narration,
    required this.gallery,
  });

  static WaypointModel _parse(String tourName, dynamic json) => WaypointModel._(
        name: json["name"]! as String,
        desc: json["desc"]! as String,
        lat: json["lat"]! as double,
        lng: json["lng"]! as double,
        narration: AssetModel._parse(tourName, json["narration"]),
        gallery: List<AssetModel>.unmodifiable(
            (json["gallery"]! as List<dynamic>)
                .map((e) => AssetModel._parse(tourName, e))),
      );

  final String name;
  final String desc;
  final double lat;
  final double lng;
  final AssetModel? narration;
  final List<AssetModel> gallery;
}

class PoiModel {
  PoiModel._({
    required this.name,
    required this.desc,
    required this.lat,
    required this.lng,
    required this.gallery,
  });

  static PoiModel _parse(String tourName, dynamic json) => PoiModel._(
        name: json["name"]! as String,
        desc: json["desc"]! as String,
        lat: json["lat"]! as double,
        lng: json["lng"]! as double,
        gallery: List<AssetModel>.unmodifiable(
            (json["gallery"]! as List<dynamic>)
                .map((e) => AssetModel._parse(tourName, e))),
      );

  final String name;
  final String desc;
  final double lat;
  final double lng;
  final List<AssetModel> gallery;
}

class AssetModel {
  AssetModel._(this._tourId, this.name);

  static AssetModel? _parse(String tourName, dynamic name) =>
      name != null ? AssetModel._(tourName, name as String) : null;

  final String _tourId;
  final String name;

  String get fullPath =>
      p.join(_toursBasePathCurrent!, _tourId, "assets", name);
}

Future<void> _downloadToFile(Uri uri, {required String outPath}) async {
  if (await File(outPath).exists()) {
    return;
  }

  var outFile = File("$outPath.part");
  if (await outFile.exists()) {
    await outFile.delete();
  }

  var outSink = outFile.openWrite();
  var client = HttpClient();
  var req = await client.getUrl(uri);
  var resp = await req.close();
  await outSink.addStream(resp).then((_) async {
    await outSink.flush();
    await outSink.close();

    await outFile.rename(outPath);
  });

  return;
}

Future<String> _downloadToMemory(Uri uri) async {
  return (await get(uri)).body;
}

Future<void> _writeToFile(String s, {required String outPath}) async {
  var outFile = File("$outPath.part");
  if (await outFile.exists()) {
    outFile.delete();
  }
  await outFile.writeAsString(s);
  await outFile.rename(outPath);
}
