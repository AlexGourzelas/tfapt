import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/src/config.dart';
import '/src/oss_licenses.dart';
import '/src/widgets/collapsible_section.dart';

class Howto extends StatelessWidget {
  const Howto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("How to"),
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
          icon: Icon(Icons.adaptive.arrow_back),
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          InstructionCard(
            step: 'Step 1: Follow Introductory Slides- Make sure you Enable GPS',
            description: 'Ensure your phone\'s GPS is turned on to get accurate location.',
            imageUrl: 'assets/enable_gps.png', // Add your image path here
          ),
          InstructionCard(
            step: 'Step 2: Choose your Destination / tour',
            description: 'Choose your desired destination from the available tours and click on download button.',
            imageUrl: 'assets/set_destination.png', // Add your image path here
          ), 
          InstructionCard(
            step: 'Step 3: Start Navigation',
            description: 'Press the start button to start your journey.',
            imageUrl: 'assets/start_navigation.png', // Add your image path here
          ),
          InstructionCard(
            step: 'Step 4: Change Map rendering',
            description: 'We recommend to change the map appearance.During map navigation, click on the midle icon (tiles) in the bottom right (3 icons).',
            imageUrl: 'assets/set_render.png', // Add your image path here
          ),
          InstructionCard(
            step: 'Step 5: Directions',
            description: 'If not close to tour, Choose your desired tour. Click on first stop. Click on directions to reach destination and start the tour.',
            imageUrl: 'assets/set_tour.png', // Add your image path here
          ), 
        ],
      ),
    );
  }
}

class InstructionCard extends StatelessWidget {
  final String step;
  final String description;
  final String imageUrl;

  InstructionCard({required this.step, required this.description, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(description),
            SizedBox(height: 8.0),
            Image.asset(imageUrl), // Display the image
          ],
        ),
      ),
    );
  }
}
