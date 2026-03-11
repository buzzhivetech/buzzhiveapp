import 'package:flutter/material.dart';

/// Analytics: time range, charts (temp, humidity, audio, motion, gas).
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(child: Text('Analytics – time range + charts')),
    );
  }
}
