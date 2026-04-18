import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/ble_providers.dart';
import '../../application/device_claim_controller.dart';
import '../../domain/ble_advertisement.dart';

/// Secondary onboarding path: scan for nearby BuzzHive advertisements and
/// claim the selected device with its sticker claim code.
///
/// The device ID is parsed from the advertisement name (`BuzzHive-<id>`) so
/// no firmware change is required; just the sticker claim code.
class BleScanTab extends ConsumerStatefulWidget {
  const BleScanTab({super.key});

  @override
  ConsumerState<BleScanTab> createState() => _BleScanTabState();
}

class _BleScanTabState extends ConsumerState<BleScanTab> {
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final Map<String, _DiscoveredSensor> _sensors = {};
  BleStatus? _adapterStatus;
  String? _scanError;

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _startScan() {
    final service = ref.read(bleSensorTransferServiceProvider);
    setState(() {
      _scanError = null;
      _sensors.clear();
    });
    _scanSub?.cancel();
    _scanSub = service.scanForSensors().listen(
      (device) {
        final identity = BleAdvertisementIdentity.tryParse(device.name);
        if (identity == null) return;
        setState(() {
          _sensors[device.id] = _DiscoveredSensor(
            device: device,
            identity: identity,
          );
        });
      },
      onError: (Object err) {
        setState(() => _scanError = err.toString());
      },
    );
  }

  void _stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  Future<void> _onSensorTapped(_DiscoveredSensor sensor) async {
    _stopScan();
    final claimCode = await showDialog<String>(
      context: context,
      builder: (ctx) => _ClaimCodeDialog(deviceId: sensor.identity.deviceId),
    );
    if (claimCode == null) return;
    ref.read(deviceClaimControllerProvider.notifier).claim(
          deviceId: sensor.identity.deviceId,
          claimCode: claimCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(bleAdapterStatusProvider);

    statusAsync.whenData((status) {
      // Kick off a scan the first time the adapter is reported as ready.
      if (status == BleStatus.ready &&
          _adapterStatus != BleStatus.ready &&
          _scanSub == null) {
        _startScan();
      }
      _adapterStatus = status;
    });

    final claimState = ref.watch(deviceClaimControllerProvider);

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _Message(
        icon: Icons.error_outline,
        message: 'Bluetooth error: $err',
      ),
      data: (status) {
        if (status != BleStatus.ready) {
          return _Message(
            icon: Icons.bluetooth_disabled,
            message: switch (status) {
              BleStatus.poweredOff =>
                'Turn on Bluetooth to scan for nearby sensors.',
              BleStatus.unauthorized =>
                'BuzzHive needs Bluetooth permission. Enable it in Settings.',
              BleStatus.unsupported =>
                'Bluetooth LE is not supported on this device.',
              BleStatus.locationServicesDisabled =>
                'Enable Location Services to scan for Bluetooth devices.',
              _ => 'Bluetooth is unavailable.',
            },
          );
        }
        return _buildScanList(claimState);
      },
    );
  }

  Widget _buildScanList(DeviceClaimState claimState) {
    final submitting = claimState is DeviceClaimSubmitting;
    final sensors = _sensors.values.toList()
      ..sort((a, b) =>
          (b.device.rssi).compareTo(a.device.rssi)); // strongest first

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Hold your phone near the sensor. It will appear here within a few seconds.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Rescan',
                onPressed: submitting ? null : _startScan,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_scanError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _scanError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: sensors.isEmpty
              ? const _Message(
                  icon: Icons.bluetooth_searching,
                  message: 'Searching for nearby BuzzHive sensors…',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: sensors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final s = sensors[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.sensors),
                        title: Text(s.identity.localName),
                        subtitle: Text(
                          'Device ID: ${s.identity.deviceId}    RSSI: ${s.device.rssi}',
                        ),
                        trailing: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: submitting ? null : () => _onSensorTapped(s),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DiscoveredSensor {
  _DiscoveredSensor({required this.device, required this.identity});

  final DiscoveredDevice device;
  final BleAdvertisementIdentity identity;
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ClaimCodeDialog extends StatefulWidget {
  const _ClaimCodeDialog({required this.deviceId});

  final String deviceId;

  @override
  State<_ClaimCodeDialog> createState() => _ClaimCodeDialogState();
}

class _ClaimCodeDialogState extends State<_ClaimCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Claim ${widget.deviceId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the claim code printed on the sensor sticker.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Claim code',
              hintText: '8 characters',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Claim'),
        ),
      ],
    );
  }
}
