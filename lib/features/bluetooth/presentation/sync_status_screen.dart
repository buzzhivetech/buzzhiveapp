import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../providers/ble_providers.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _syncing = false;
  bool _wifiOnly = false;
  String? _message;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _message = null;
    });
    try {
      final count = await ref.read(syncRepositoryProvider).syncNow(wifiOnly: _wifiOnly);
      ref.invalidate(pendingSyncCountProvider);
      if (mounted) {
        setState(() {
          _message = count > 0
              ? '$count readings uploaded successfully.'
              : 'Nothing to upload.';
        });
      }
    } on SyncException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } on Object catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _purge() async {
    final count = await ref.read(syncRepositoryProvider).purgeOldSyncedReadings();
    ref.invalidate(pendingSyncCountProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purged $count old readings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingAsync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  pendingAsync.when(
                    data: (count) => Text(
                      '$count',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text('Error', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'readings pending upload',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Wi-Fi only'),
            subtitle: const Text('Only upload when connected to Wi-Fi'),
            value: _wifiOnly,
            onChanged: (v) => setState(() => _wifiOnly = v),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_syncing ? 'Uploading...' : 'Sync now'),
          ),

          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _purge,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Purge old synced data'),
          ),
        ],
      ),
    );
  }
}
