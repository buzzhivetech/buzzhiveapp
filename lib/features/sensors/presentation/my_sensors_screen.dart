import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../models/user_sensor_link.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/sensor_readings_provider.dart';

class MySensorsScreen extends ConsumerWidget {
  const MySensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linkedSensorsProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Sensors')),
      body: linksAsync.when(
        data: (links) {
          if (links.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sensors_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sensors linked yet',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to link a sensor by its ID',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: links.length,
            itemBuilder: (context, index) {
              return _SensorListTile(
                link: links[index],
                userId: userId!,
                onUnlink: () => ref.invalidate(linkedSensorsProvider),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  err.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(linkedSensorsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.addSensor),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SensorListTile extends ConsumerStatefulWidget {
  const _SensorListTile({
    required this.link,
    required this.userId,
    required this.onUnlink,
  });

  final UserSensorLink link;
  final String userId;
  final VoidCallback onUnlink;

  @override
  ConsumerState<_SensorListTile> createState() => _SensorListTileState();
}

class _SensorListTileState extends ConsumerState<_SensorListTile> {
  bool _unlinking = false;

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink sensor?'),
        content: Text(
          'Remove "${widget.link.displayName ?? widget.link.sensor.firebaseSensorId}" from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _unlinking = true);
    try {
      await ref.read(sensorLinkRepositoryProvider).unlinkSensor(
            widget.userId,
            widget.link.sensor.id,
          );
      ref.invalidate(linkedSensorsProvider);
      ref.invalidate(latestReadingsProvider);
      if (mounted) widget.onUnlink();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlink')),
        );
      }
    } finally {
      if (mounted) setState(() => _unlinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.link.displayName ??
        widget.link.sensor.displayName ??
        widget.link.sensor.firebaseSensorId;
    final subtitle = 'ID: ${widget.link.sensor.firebaseSensorId}';

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          Icons.sensors,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _unlinking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _unlink,
              tooltip: 'Unlink',
            ),
    );
  }
}
