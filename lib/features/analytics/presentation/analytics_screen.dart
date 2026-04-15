import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/user_sensor_link.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/sensor_readings_provider.dart';
import 'widgets/metric_selector.dart';
import 'widgets/sensor_line_chart.dart';

/// Analytics screen: sensor selector, time range picker, metric chips,
/// and a time-series line chart.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedSensorId;
  String _selectedRange = AppConstants.range24h;
  SensorMetric _selectedMetric = SensorMetric.temperature;

  int get _startMs {
    final now = DateTime.now().millisecondsSinceEpoch;
    return switch (_selectedRange) {
      AppConstants.range24h => now - const Duration(hours: 24).inMilliseconds,
      AppConstants.range7d => now - const Duration(days: 7).inMilliseconds,
      AppConstants.range30d => now - const Duration(days: 30).inMilliseconds,
      _ => 0,
    };
  }

  int get _endMs => DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linksAsync = ref.watch(linkedSensorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (links) {
          if (links.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No sensors linked',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Link a sensor to start seeing analytics.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          _selectedSensorId ??= links.first.sensor.firebaseSensorId;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSensorDropdown(theme, links),
              const SizedBox(height: 8),
              _buildTimeRangePicker(theme),
              const SizedBox(height: 8),
              MetricSelector(
                selected: _selectedMetric,
                onChanged: (m) => setState(() => _selectedMetric = m),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildChart(theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorDropdown(ThemeData theme, List<UserSensorLink> links) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSensorId,
        decoration: const InputDecoration(
          labelText: 'Sensor',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: links.map((link) {
          final label = link.displayName ??
              link.sensor.displayName ??
              link.sensor.firebaseSensorId;
          return DropdownMenuItem(
            value: link.sensor.firebaseSensorId,
            child: Text(label),
          );
        }).toList(),
        onChanged: (id) {
          if (id != null) setState(() => _selectedSensorId = id);
        },
      ),
    );
  }

  Widget _buildTimeRangePicker(ThemeData theme) {
    const ranges = [
      (key: AppConstants.range24h, label: '24h'),
      (key: AppConstants.range7d, label: '7d'),
      (key: AppConstants.range30d, label: '30d'),
      (key: AppConstants.rangeAll, label: 'All'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        segments: ranges
            .map((r) => ButtonSegment(value: r.key, label: Text(r.label)))
            .toList(),
        selected: {_selectedRange},
        onSelectionChanged: (s) => setState(() => _selectedRange = s.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    if (_selectedSensorId == null) {
      return const Center(child: Text('Select a sensor'));
    }

    final params =
        ReadingsRangeParams(_selectedSensorId!, _startMs, _endMs);
    final readingsAsync = ref.watch(readingsInRangeProvider(params));

    return readingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text('Failed to load data: $err',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      data: (readings) {
        if (readings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart,
                    size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text('No data in this time range',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: SensorLineChart(
            readings: readings,
            metric: _selectedMetric,
          ),
        );
      },
    );
  }
}
