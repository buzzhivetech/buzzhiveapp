import 'package:flutter/material.dart';

/// List linked sensors; add sensor flow.
class MySensorsScreen extends StatelessWidget {
  const MySensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sensors')),
      body: const Center(child: Text('My sensors – list + add sensor')),
    );
  }
}
