import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../repositories/ble_transfer_repository.dart';
import '../application/sensor_sync_controller.dart';

/// One-shot BLE pull screen. Walks the user through the phases of a single
/// `syncSingleReading` attempt (scanning → connecting → waiting → captured
/// or failed) and hands back control when the user taps Done.
class BleDownloadScreen extends ConsumerStatefulWidget {
  const BleDownloadScreen({required this.args, super.key});

  final BleDownloadArgs? args;

  @override
  ConsumerState<BleDownloadScreen> createState() => _BleDownloadScreenState();
}

class _BleDownloadScreenState extends ConsumerState<BleDownloadScreen> {
  BleDownloadArgs? get _args => widget.args;

  @override
  void initState() {
    super.initState();
    final args = _args;
    if (args == null) return;
    // Kick off the sync once the first frame is scheduled so the controller
    // and its stream are wired up before state transitions arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sensorSyncControllerProvider(args).notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sync sensor')),
        body: const Center(
          child: Text('Missing sensor context. Tap a sensor card to retry.'),
        ),
      );
    }

    final state = ref.watch(sensorSyncControllerProvider(args));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Sync: ${args.sensorName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: switch (state) {
            SensorSyncIdle() || SensorSyncScanning() =>
              _buildStatus(theme, 'Searching for your sensor…',
                  hint: 'Keep the sensor within a few meters.'),
            SensorSyncConnecting() =>
              _buildStatus(theme, 'Connecting…'),
            SensorSyncWaiting() => _buildStatus(
                theme,
                'Waiting for the next reading…',
                hint: 'Your sensor will push a sample in a moment.',
              ),
            SensorSyncSuccess() => _buildSuccess(theme, args),
            SensorSyncFailure(:final message) =>
              _buildFailure(theme, args, message),
          },
        ),
      ),
    );
  }

  Widget _buildStatus(ThemeData theme, String title, {String? hint}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(title,
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, BleDownloadArgs args) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline,
            size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Reading received',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'We captured one sample from ${args.sensorName} and queued it for upload.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildFailure(
      ThemeData theme, BleDownloadArgs args, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline,
            size: 72, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Could not sync',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => ref
                  .read(sensorSyncControllerProvider(args).notifier)
                  .start(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ],
    );
  }
}
