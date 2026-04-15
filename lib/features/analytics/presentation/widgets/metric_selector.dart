import 'package:flutter/material.dart';

import '../../../../models/sensor_reading.dart';

/// Available metrics that can be plotted on the line chart.
enum SensorMetric {
  temperature('Temperature', '°F', Icons.thermostat),
  humidity('Humidity', '%', Icons.water_drop),
  voc('VOC / Gas', '', Icons.air),
  soundLevel('Sound Level', 'dB', Icons.volume_up),
  microphone('Microphone', 'Hz', Icons.mic),
  accelMag('Acceleration', 'g', Icons.speed),
  forceMag('Force', '', Icons.fitness_center);

  const SensorMetric(this.label, this.unit, this.icon);

  final String label;
  final String unit;
  final IconData icon;

  /// Extract the numeric value for this metric from a [SensorReading].
  double valueFrom(SensorReading r) => switch (this) {
        SensorMetric.temperature => r.tempF,
        SensorMetric.humidity => r.hum,
        SensorMetric.voc => r.gas,
        SensorMetric.soundLevel => r.db,
        SensorMetric.microphone => r.mic,
        SensorMetric.accelMag =>
          _magnitude(r.ax, r.ay, r.az),
        SensorMetric.forceMag =>
          _magnitude(r.fx, r.fy, r.fz),
      };

  static double _magnitude(double x, double y, double z) {
    return (x * x + y * y + z * z);
  }
}

/// Horizontal scrollable chip row for choosing which metric to display.
class MetricSelector extends StatelessWidget {
  const MetricSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SensorMetric selected;
  final ValueChanged<SensorMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: SensorMetric.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = SensorMetric.values[index];
          final isSelected = metric == selected;
          return FilterChip(
            avatar: Icon(metric.icon, size: 16),
            label: Text(metric.label),
            selected: isSelected,
            onSelected: (_) => onChanged(metric),
          );
        },
      ),
    );
  }
}
