import 'package:flutter/material.dart';

/// Hive location map (dashboard parity).
class HiveMapScreen extends StatelessWidget {
  const HiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: const Center(child: Text('Map – hive location')),
    );
  }
}
