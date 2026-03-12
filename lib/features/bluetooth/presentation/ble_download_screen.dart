import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../providers/ble_providers.dart';

class BleDownloadScreen extends ConsumerStatefulWidget {
  const BleDownloadScreen({
    required this.sensorId,
    required this.firebaseSensorId,
    required this.sensorName,
    super.key,
  });

  final String sensorId;
  final String firebaseSensorId;
  final String sensorName;

  @override
  ConsumerState<BleDownloadScreen> createState() => _BleDownloadScreenState();
}

class _BleDownloadScreenState extends ConsumerState<BleDownloadScreen> {
  _Phase _phase = _Phase.scanning;
  String? _error;
  DiscoveredDevice? _selectedDevice;
  final _discovered = <String, DiscoveredDevice>{};
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<int>? _downloadSub;
  int _receivedCount = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _downloadSub?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _phase = _Phase.scanning;
      _error = null;
      _discovered.clear();
    });
    _scanSub?.cancel();
    _scanSub = ref.read(bleTransferRepositoryProvider).scanForSensors().listen(
      (device) {
        if (!mounted) return;
        setState(() => _discovered[device.id] = device);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e is BleTransferException ? e.message : e.toString();
          _phase = _Phase.error;
        });
      },
    );
  }

  void _connectAndDownload(DiscoveredDevice device) {
    _scanSub?.cancel();
    setState(() {
      _selectedDevice = device;
      _phase = _Phase.downloading;
      _receivedCount = 0;
      _error = null;
    });

    _downloadSub = ref
        .read(bleTransferRepositoryProvider)
        .downloadSession(
          deviceId: device.id,
          sensorId: widget.sensorId,
          firebaseSensorId: widget.firebaseSensorId,
        )
        .listen(
      (count) {
        if (mounted) setState(() => _receivedCount = count);
      },
      onDone: () {
        if (mounted) {
          setState(() => _phase = _Phase.done);
          ref.invalidate(pendingSyncCountProvider);
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _error = e is BleTransferException ? e.message : e.toString();
            _phase = _Phase.error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Download: ${widget.sensorName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (_phase) {
          _Phase.scanning => _buildScanning(theme),
          _Phase.downloading => _buildDownloading(theme),
          _Phase.done => _buildDone(theme),
          _Phase.error => _buildError(theme),
        },
      ),
    );
  }

  Widget _buildScanning(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Scanning for nearby sensors...', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),
        if (_discovered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Make sure the sensor is powered on and nearby.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _discovered.length,
              itemBuilder: (_, i) {
                final device = _discovered.values.elementAt(i);
                return ListTile(
                  leading: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
                  title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
                  subtitle: Text('RSSI: ${device.rssi} dBm'),
                  trailing: FilledButton(
                    onPressed: () => _connectAndDownload(device),
                    child: const Text('Download'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDownloading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Downloading from ${_selectedDevice?.name ?? 'sensor'}...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$_receivedCount readings received',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep the app open and stay near the sensor.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Download complete', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '$_receivedCount readings saved locally.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'They will upload to the cloud when you have internet.',
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
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Transfer failed', style: theme.textTheme.titleLarge),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
          if (_receivedCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$_receivedCount readings were saved before the error.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _startScan,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

enum _Phase { scanning, downloading, done, error }
