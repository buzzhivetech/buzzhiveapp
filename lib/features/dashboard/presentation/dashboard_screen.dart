import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../models/sensor_reading.dart';
import '../../../models/user_sensor_link.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/sensor_readings_provider.dart';
import 'package:buzzhive_app/features/dashboard/presentation/widgets/sensor_reading_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linkedSensorsProvider);
    final readingsAsync = ref.watch(latestReadingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: AsyncValueWidget<List<UserSensorLink>>(
        value: linksAsync,
        loadingMessage: 'Loading sensors…',
        onRetry: () => ref.invalidate(linkedSensorsProvider),
        data: (links) {
          if (links.isEmpty) {
            return _EmptyState(onAddSensor: () => context.push(Routes.addSensor));
          }
          return readingsAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading readings…'),
            error: (err, _) => ErrorDisplay(
              error: err,
              onRetry: () {
                ref.invalidate(linkedSensorsProvider);
                ref.invalidate(latestReadingsProvider);
              },
            ),
            data: (readingsMap) => _DashboardContent(
              links: links,
              readingsMap: readingsMap,
              onRefresh: () {
                ref.invalidate(linkedSensorsProvider);
                ref.invalidate(latestReadingsProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddSensor});

  final VoidCallback onAddSensor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No sensors linked',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Link a sensor from My Sensors to see live data here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddSensor,
              icon: const Icon(Icons.add),
              label: const Text('Link a sensor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.links,
    required this.readingsMap,
    required this.onRefresh,
  });

  final List<UserSensorLink> links;
  final Map<String, SensorReading?> readingsMap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final link in links)
            _SensorSection(
              link: link,
              reading: readingsMap[link.sensor.firebaseSensorId],
            ),
        ],
      ),
    );
  }
}

class _SensorSection extends StatelessWidget {
  const _SensorSection({
    required this.link,
    required this.reading,
  });

  final UserSensorLink link;
  final SensorReading? reading;

  @override
  Widget build(BuildContext context) {
    final label = link.displayName ??
        link.sensor.displayName ??
        'Sensor ${link.sensor.firebaseSensorId}';

    if (reading == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.sensors, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Waiting for data…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SensorReadingCard(sensorLabel: label, reading: reading!);
  }
}
