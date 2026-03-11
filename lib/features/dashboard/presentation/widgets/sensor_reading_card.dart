import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:buzzhive_app/core/constants/app_constants.dart';
import 'package:buzzhive_app/models/sensor_reading.dart';
import 'reading_metric_card.dart';

/// One card per sensor: title + latest reading metrics + last updated.
class SensorReadingCard extends StatelessWidget {
  const SensorReadingCard({
    super.key,
    required this.sensorLabel,
    required this.reading,
  });

  final String sensorLabel;
  final SensorReading reading;

  bool get isStale =>
      DateTime.now().difference(reading.timestamp).inMilliseconds >
      AppConstants.connectionStaleMs;

  static final _timeFormat = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sensorLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isStale)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No recent data',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ReadingMetricCard(
                  label: 'Temperature',
                  value: reading.tempF.toStringAsFixed(1),
                  unit: '°F',
                  icon: Icons.thermostat,
                ),
                ReadingMetricCard(
                  label: 'Humidity',
                  value: reading.hum.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.water_drop,
                ),
                ReadingMetricCard(
                  label: 'Sound',
                  value: reading.db.toStringAsFixed(1),
                  unit: 'dB',
                  icon: Icons.volume_up,
                ),
                ReadingMetricCard(
                  label: 'Frequency',
                  value: reading.mic.toStringAsFixed(0),
                  unit: 'Hz',
                  icon: Icons.graphic_eq,
                ),
                ReadingMetricCard(
                  label: 'VOC',
                  value: reading.gas.toStringAsFixed(1),
                  icon: Icons.air,
                ),
                ReadingMetricCard(
                  label: 'Motion (X/Y/Z)',
                  value: '${reading.ax.toStringAsFixed(0)} / ${reading.ay.toStringAsFixed(0)} / ${reading.az.toStringAsFixed(0)}',
                  icon: Icons.vibration,
                ),
                ReadingMetricCard(
                  label: 'Force (X/Y/Z)',
                  value: '${reading.fx.toStringAsFixed(1)} / ${reading.fy.toStringAsFixed(1)} / ${reading.fz.toStringAsFixed(1)}',
                  icon: Icons.speed,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Updated ${_timeFormat.format(reading.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
