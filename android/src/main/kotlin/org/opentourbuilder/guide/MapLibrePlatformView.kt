package org.opentourbuilder.guide

import android.content.Context
import android.view.View
import com.mapbox.android.gestures.MoveGestureDetector
import com.mapbox.android.gestures.RotateGestureDetector
import com.mapbox.android.gestures.StandardScaleGestureDetector
import com.mapbox.geojson.FeatureCollection
import io.flutter.plugin.platform.PlatformView
import com.mapbox.mapboxsdk.maps.MapView
import com.mapbox.mapboxsdk.camera.CameraPosition
import com.mapbox.mapboxsdk.Mapbox
import com.mapbox.mapboxsdk.camera.CameraUpdate
import com.mapbox.mapboxsdk.camera.CameraUpdateFactory
import com.mapbox.mapboxsdk.geometry.LatLng
import com.mapbox.mapboxsdk.maps.MapboxMap
import com.mapbox.mapboxsdk.maps.MapboxMapOptions
import com.mapbox.mapboxsdk.maps.Style
import com.mapbox.mapboxsdk.plugins.annotation.CircleManager
import com.mapbox.mapboxsdk.style.sources.GeoJsonSource
import com.mapbox.mapboxsdk.style.sources.VectorSource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.IllegalArgumentException

class MapLibrePlatformView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger
) : PlatformView {
    private val mapView: MapView
    private val channel = MethodChannel(messenger, "opentourbuilder.org/guide/map")
    private lateinit var locationSource: GeoJsonSource
    private var map: MapboxMap? = null

    private var stylePath: String
    private var pathGeoJson: String
    private var pointsGeoJson: String
    private var locationGeoJson: String? = null

    override fun getView(): View {
        return mapView
    }

    override fun dispose() {
        mapView.onDestroy()
    }

    init {
        if (creationParams == null) {
            throw IllegalArgumentException()
        }

        channel.setMethodCallHandler { call, result -> handleMethodCall(call, result) }

        // Initialize MapLibre
        Mapbox.getInstance(context)

        stylePath = creationParams["stylePath"] as String
        pathGeoJson = creationParams["pathGeoJson"] as String
        pointsGeoJson = creationParams["pointsGeoJson"] as String

        var centerMap = creationParams["center"] as Map<*, *>

        val options = MapboxMapOptions
            .createFromAttributes(context)
            .textureMode(true)
            .attributionEnabled(false)
            .logoEnabled(false)
            .compassEnabled(false)
        mapView = MapView(context, options)
        mapView.getMapAsync { map ->
            handleMapLoaded(
                map = map,
                stylePath = stylePath,
                lat = centerMap["lat"] as Double,
                lng = centerMap["lng"] as Double,
                zoom = creationParams["zoom"] as Double
            )
        }
    }

    private fun handleMapLoaded(
        map: MapboxMap,
        stylePath: String,
        lat: Double,
        lng: Double,
        zoom: Double
    ) {
        this.map = map

        map.cameraPosition = CameraPosition.Builder()
            .target(LatLng(lat, lng))
            .zoom(zoom - 1)
            .build()

        locationSource = GeoJsonSource("current_location")
        map.setStyle(Style.Builder()
            .fromUri("file://$stylePath")
            .withSource(locationSource)
            .withSource(GeoJsonSource("tour_path",
                FeatureCollection.fromJson(pathGeoJson)))
            .withSource(GeoJsonSource("tour_points",
                FeatureCollection.fromJson(pointsGeoJson)))) { style ->
            val circleManager = CircleManager(mapView, map, style)
            val fc = FeatureCollection.fromJson(pointsGeoJson)
            for (feature in fc.features()!!) {
                feature.addNumberProperty("circle-radius", 32)
                feature.addNumberProperty("circle-opacity", 0.0)
            }
            val ids = circleManager.create(fc).map { it.id }
            circleManager.addClickListener { circle ->
                val index = ids.indexOf(circle.id)
                channel.invokeMethod("pointClick", mapOf("index" to index))
                return@addClickListener true
            }
        }

        map.addOnCameraMoveListener {
            val cameraPosition = map.cameraPosition
            channel.invokeMethod(
                "updateCameraPosition", mapOf(
                    "lat" to cameraPosition.target.latitude,
                    "lng" to cameraPosition.target.longitude,
                    "zoom" to cameraPosition.zoom + 1,
                )
            )
        }

        map.addOnMoveListener(object : MapboxMap.OnMoveListener {
            override fun onMove(detector: MoveGestureDetector) {
                channel.invokeMethod("moveUpdate", null)
            }

            override fun onMoveBegin(detector: MoveGestureDetector) {
                channel.invokeMethod("moveBegin", null)
            }

            override fun onMoveEnd(detector: MoveGestureDetector) {
                channel.invokeMethod("moveEnd", null)
            }
        })

        map.addOnScaleListener(object : MapboxMap.OnScaleListener {
            override fun onScale(detector: StandardScaleGestureDetector) {
                channel.invokeMethod("moveUpdate", null)
            }

            override fun onScaleBegin(detector: StandardScaleGestureDetector)  {
                channel.invokeMethod("moveBegin", null)
            }

            override fun onScaleEnd(detector: StandardScaleGestureDetector)  {
                channel.invokeMethod("moveEnd", null)
            }
        })
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateLocation" -> {
                locationGeoJson = call.arguments as String
                locationSource.setGeoJson(locationGeoJson)
                result.success(null)
            }
            "moveCamera" -> {
                val args = call.arguments as Map<*, *>
                val lat = args["lat"] as Double
                val lng = args["lng"] as Double
                val duration = args["duration"] as Int
                map!!.easeCamera(CameraUpdateFactory.newLatLng(LatLng(lat, lng)), duration)
                result.success(null)
            }
            "setStyle" -> {
                stylePath = call.arguments as String
                // locationSource MUST be reassigned to prevent a segfault. I love MapLibre!
                if (locationGeoJson != null) {
                    locationSource = GeoJsonSource("current_location", locationGeoJson)
                } else {
                    locationSource = GeoJsonSource("current_location")
                }
                map!!.setStyle(Style.Builder()
                    .fromUri("file://$stylePath")
                    .withSource(locationSource)
                    .withSource(GeoJsonSource("tour_path",
                        FeatureCollection.fromJson(pathGeoJson)))
                    .withSource(GeoJsonSource("tour_points",
                        FeatureCollection.fromJson(pointsGeoJson))))
                result.success(null)
            }
        }
    }
}
