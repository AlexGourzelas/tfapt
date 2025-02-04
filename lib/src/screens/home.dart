import 'package:flutter/material.dart';
import 'package:tourforge_baseline/src/asset_garbage_collector.dart';
import 'package:tourforge_baseline/src/config.dart';

import '/src/data.dart';
import '/src/screens/tour_details.dart';
import '/src/widgets/asset_image_builder.dart';
import 'about.dart';
import 'Howto.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<Project> tourIndex;

  @override
  void initState() {
    super.initState();

    tourIndex = Project.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tourForgeConfig.appName),
        actions: [
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            tooltip: 'More',
            elevation: 1.0,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "About",
                child: Text("About"),
              ),
              const PopupMenuItem(
                value: "How to",
                child: Text("How to"),
                ),
            ],
            onSelected: (value) {
              switch (value) {
                case "About":
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const About()));
                  break;
                  case "How to":
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const Howto()));
                  break;
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Material(
            type: MaterialType.card,
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "To travel is to Live - Hans Christian Andersen",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    "Embark on a journey through the picturesque villages and towns of Greece, each with its own charm!"
                    "Capture stunning photographs of Greece's iconic landmarks and breathtaking landscapes."
                    "Greco is your AI tour partner."
                    "Below, you will find a list containing available tours "
                    "in ${tourForgeConfig.appName}. Tap on one to take a look!",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          FutureBuilder<Project>(
            future: tourIndex,
            builder: (context, snapshot) {
              var tours = snapshot.data?.tours;

              if (tours != null) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: tours.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _TourListItem(tours[index]),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(32.0),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TourListItem extends StatefulWidget {
  const _TourListItem(this.tour);

  final TourModel tour;

  @override
  State<_TourListItem> createState() => _TourListItemState();
}

class _TourListItemState extends State<_TourListItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
          type: MaterialType.card,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          elevation: 3,
          shadowColor: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => TourDetails(widget.tour)));
            },
            onLongPress: () {
              showDialog<bool>(
                context: context,
                builder: (BuildContext context) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24.0),
                        const Text(
                          "By deleting the tour files you will free-up space in your mobile phone\n\n"
                          "You will still be able to redownload this tour in the future.",
                          softWrap: true,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await AssetGarbageCollector.run(ignoredTours: {widget.tour.id});
      
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                ),
              );
            },
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: widget.tour.gallery.isNotEmpty
                        ? AssetImageBuilder(
                            widget.tour.gallery[0],
                            builder: (image) {
                              return Image(
                                image: image,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : const SizedBox(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 8.0,
                  ),
                  child: Text(
                    widget.tour.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Wrap(
                    spacing: 4.0,
                    runSpacing: 8.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.download,
                        size: 20,
                        color: Color.fromARGB(255, 160, 160, 160),
                      ),
                      Text(
                        "Download",
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: const Color.fromARGB(255, 160, 160, 160)),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(
                        widget.tour.type == "driving"
                            ? Icons.directions_car
                            : Icons.directions_walk,
                        size: 20,
                        color: const Color.fromARGB(255, 160, 160, 160),
                      ),
                      Text(
                        widget.tour.type == "driving"
                            ? "Driving Tour"
                            : "Walking Tour",
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: const Color.fromARGB(255, 160, 160, 160)),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.route,
                        size: 20,
                        color: Color.fromARGB(255, 160, 160, 160),
                      ),
                      Text(
                        "${widget.tour.route.length} Stops",
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: const Color.fromARGB(255, 160, 160, 160)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
