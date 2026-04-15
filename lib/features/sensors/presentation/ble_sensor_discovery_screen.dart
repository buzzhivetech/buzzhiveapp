import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/remembered_sensor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ble_providers.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/sensor_readings_provider.dart';

/// Multi-phase BLE sensor discovery and linking flow.
///
/// Phases:
///   1. Scan -- discover nearby BuzzHive BLE sensors
///   2. Verify -- connect to the selected device
///   3. Identity -- user enters the Firebase sensor node ID
///   4. Link -- validate in RTDB + link in Supabase + remember BLE identity
///   5. Done -- send START_TRANSFER signal, show success
class BleSensorDiscoveryScreen extends ConsumerStatefulWidget {
  const BleSensorDiscoveryScreen({super.key});

  @override
  ConsumerState<BleSensorDiscoveryScreen> createState() =>
      _BleSensorDiscoveryScreenState();
}

enum _Phase { scanning, verifying, identity, linking, done, error }

class _BleSensorDiscoveryScreenState
    extends ConsumerState<BleSensorDiscoveryScreen> {
  _Phase _phase = _Phase.scanning;
  String? _error;

  final _discovered = <String, DiscoveredDevice>{};
  StreamSubscription<DiscoveredDevice>? _scanSub;

  DiscoveredDevice? _selectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  final _nodeIdController = TextEditingController();
  bool _linkInProgress = false;

  Set<String> _knownBleIds = {};

  @override
  void initState() {
    super.initState();
    _loadRemembered();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _nodeIdController.dispose();
    super.dispose();
  }

  Future<void> _loadRemembered() async {
    final sensors =
        await ref.read(rememberedSensorStoreProvider).getAll();
    if (mounted) {
      setState(() {
        _knownBleIds = sensors.map((s) => s.bleDeviceId).toSet();
      });
    }
  }

  // ---- Phase 1: Scan ----

  void _startScan() {
    setState(() {
      _phase = _Phase.scanning;
      _error = null;
      _discovered.clear();
    });
    _scanSub?.cancel();
    _scanSub = ref
        .read(bleTransferRepositoryProvider)
        .scanForSensors()
        .listen(
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

  // ---- Phase 2: Verify connection ----

  void _selectDevice(DiscoveredDevice device) {
    _scanSub?.cancel();
    setState(() {
      _selectedDevice = device;
      _phase = _Phase.verifying;
      _error = null;
    });

    final ble = ref.read(bleSensorTransferServiceProvider);
    final connCompleter = Completer<void>();

    _connSub = ble.connectToDevice(device.id).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected &&
          !connCompleter.isCompleted) {
        connCompleter.complete();
      }
      if (update.connectionState == DeviceConnectionState.disconnected &&
          !connCompleter.isCompleted) {
        connCompleter.completeError(
          const BleTransferException('Device disconnected during verification'),
        );
      }
    }, onError: (Object e) {
      if (!connCompleter.isCompleted) connCompleter.completeError(e);
    });

    connCompleter.future.then((_) {
      if (mounted) setState(() => _phase = _Phase.identity);
    }).catchError((Object e) {
      _connSub?.cancel();
      if (mounted) {
        setState(() {
          _error = e is BleTransferException ? e.message : e.toString();
          _phase = _Phase.error;
        });
      }
    });
  }

  // ---- Phase 3 → 4: Identity + Link ----

  Future<void> _linkSensor() async {
    final nodeId = _nodeIdController.text.trim();
    if (nodeId.isEmpty) {
      setState(() => _error = 'Enter a sensor ID');
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() => _error = 'You must be signed in');
      return;
    }

    setState(() {
      _phase = _Phase.linking;
      _linkInProgress = true;
      _error = null;
    });

    try {
      final dataRepo = ref.read(sensorDataRepositoryProvider);
      final exists = await dataRepo.sensorExists(nodeId);
      if (!exists) {
        if (mounted) {
          setState(() {
            _error = 'Sensor not found. Check the ID and try again.';
            _phase = _Phase.identity;
            _linkInProgress = false;
          });
        }
        return;
      }

      final linkRepo = ref.read(sensorLinkRepositoryProvider);
      await linkRepo.linkSensor(userId, nodeId);

      final store = ref.read(rememberedSensorStoreProvider);
      final now = DateTime.now().toUtc();
      await store.save(RememberedSensor(
        firebaseSensorId: nodeId,
        bleDeviceId: _selectedDevice!.id,
        deviceName: _selectedDevice!.name.isNotEmpty
            ? _selectedDevice!.name
            : 'BuzzHive Sensor',
        addedAt: now,
        lastSeenAt: now,
      ));

      // Send START_TRANSFER to kick off data reception
      final ble = ref.read(bleSensorTransferServiceProvider);
      try {
        await ble.sendStartTransfer(_selectedDevice!.id);
      } on Object catch (_) {
        // Non-fatal: the sensor will still be remembered
      }

      ref.invalidate(linkedSensorsProvider);
      ref.invalidate(latestReadingsProvider);
      ref.invalidate(rememberedSensorsProvider);

      if (mounted) {
        setState(() {
          _phase = _Phase.done;
          _linkInProgress = false;
        });
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _phase = _Phase.identity;
          _linkInProgress = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _phase = _Phase.identity;
          _linkInProgress = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _phase = _Phase.identity;
          _linkInProgress = false;
        });
      }
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Sensor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (_phase) {
          _Phase.scanning => _buildScanning(theme),
          _Phase.verifying => _buildVerifying(theme),
          _Phase.identity => _buildIdentity(theme),
          _Phase.linking => _buildLinking(theme),
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
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Scanning for BuzzHive sensors...',
                style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure your sensor is powered on and nearby.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_discovered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No sensors found yet...')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _discovered.length,
              itemBuilder: (_, i) {
                final device = _discovered.values.elementAt(i);
                final isKnown = _knownBleIds.contains(device.id);
                return ListTile(
                  leading: Icon(
                    isKnown ? Icons.sensors : Icons.bluetooth_searching,
                    color: isKnown
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(device.name.isNotEmpty
                            ? device.name
                            : 'Unknown Sensor'),
                      ),
                      if (isKnown)
                        Chip(
                          label: const Text('Recognized'),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  subtitle: Text('RSSI: ${device.rssi} dBm'),
                  trailing: FilledButton(
                    onPressed: () => _selectDevice(device),
                    child: const Text('Select'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVerifying(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Verifying connection...',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _selectedDevice?.name ?? 'Sensor',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Connected to ${_selectedDevice?.name ?? 'sensor'}',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Enter the sensor ID printed on your sensor to link it to your account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nodeIdController,
            decoration: const InputDecoration(
              labelText: 'Sensor ID',
              hintText: 'e.g. 10001',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _linkSensor(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _linkInProgress ? null : _linkSensor,
            child: _linkInProgress
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Link Sensor'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinking(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Linking sensor...'),
        ],
      ),
    );
  }

  Widget _buildDone(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Sensor linked successfully!',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Your sensor has been remembered and is ready to use.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
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
          Text('Something went wrong', style: theme.textTheme.titleLarge),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
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
