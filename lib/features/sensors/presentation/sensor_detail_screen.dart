import 'package:flutter/material.dart';

/// Single sensor detail and latest readings.
class SensorDetailScreen extends StatelessWidget {
  const SensorDetailScreen({super.key, required this.sensorId});

  final String sensorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensor $sensorId')),
      body: Center(child: Text('Detail for sensor $sensorId')),
    );
  }
}
