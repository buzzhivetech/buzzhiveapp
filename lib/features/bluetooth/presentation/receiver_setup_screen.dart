import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../core/constants/ble_protocol.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/ble_permissions.dart';
import '../../../providers/ble_providers.dart';

/// Multi-phase BLE receiver setup flow.
///
/// Phases:
///   1. Scan   -- discover nearby BuzzHive receivers in setup mode
///   2. Connect -- establish BLE connection
///   3. Ready  -- subscribe to status char, wait for READY signal
///   4. Credentials -- user enters/confirms WiFi password (SSID pre-filled)
///   5. Provisioning -- write credentials, wait for WIFI_OK / FIREBASE_OK
///   6. Done   -- receiver confirmed Firebase, show success
///   7. Error  -- show failure with retry option
class ReceiverSetupScreen extends ConsumerStatefulWidget {
  const ReceiverSetupScreen({super.key});

  @override
  ConsumerState<ReceiverSetupScreen> createState() =>
      _ReceiverSetupScreenState();
}

enum _Phase {
  scanning,
  connecting,
  waitingReady,
  credentials,
  provisioning,
  done,
  error,
}

class _ReceiverSetupScreenState extends ConsumerState<ReceiverSetupScreen> {
  _Phase _phase = _Phase.scanning;
  String? _error;

  final _discovered = <String, DiscoveredDevice>{};
  StreamSubscription<DiscoveredDevice>? _scanSub;

  DiscoveredDevice? _selectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<String>? _statusSub;

  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sensorIdsController = TextEditingController();
  bool _obscurePassword = true;
  bool _sendInProgress = false;

  String? _provisioningStatus;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _statusSub?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    _sensorIdsController.dispose();
    super.dispose();
  }

  // ---- Phase 1: Scan ----

  Future<void> _startScan() async {
    setState(() {
      _phase = _Phase.scanning;
      _error = null;
      _discovered.clear();
    });

    final granted = await ensureBlePermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _error = 'Bluetooth and location permissions are required to scan '
              'for receivers. Please grant them in Settings.';
          _phase = _Phase.error;
        });
      }
      return;
    }

    _scanSub?.cancel();
    final ble = ref.read(bleSensorTransferServiceProvider);
    _scanSub = ble.scanForReceivers().listen(
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

  // ---- Phase 2: Connect ----

  void _selectDevice(DiscoveredDevice device) {
    _scanSub?.cancel();
    setState(() {
      _selectedDevice = device;
      _phase = _Phase.connecting;
      _error = null;
    });

    final ble = ref.read(bleSensorTransferServiceProvider);
    final connCompleter = Completer<void>();

    _connSub = ble.connectToReceiver(device.id).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected &&
          !connCompleter.isCompleted) {
        connCompleter.complete();
      }
      if (update.connectionState == DeviceConnectionState.disconnected &&
          !connCompleter.isCompleted) {
        connCompleter.completeError(
          const BleTransferException(
              'Receiver disconnected during connection'),
        );
      }
    }, onError: (Object e) {
      if (!connCompleter.isCompleted) connCompleter.completeError(e);
    });

    connCompleter.future.then((_) {
      if (mounted) _waitForReady();
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

  // ---- Phase 3: Wait for READY ----

  void _waitForReady() {
    setState(() {
      _phase = _Phase.waitingReady;
      _error = null;
    });

    final ble = ref.read(bleSensorTransferServiceProvider);
    _statusSub?.cancel();
    _statusSub = ble
        .subscribeToReceiverStatus(_selectedDevice!.id)
        .listen((status) {
      if (!mounted) return;
      if (status == BleProtocol.statusReady) {
        _prepareCredentials();
      }
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() {
        _error = e is BleTransferException ? e.message : e.toString();
        _phase = _Phase.error;
      });
    });
  }

  // ---- Phase 4: Credentials ----

  Future<void> _prepareCredentials() async {
    String? ssid;
    try {
      ssid = await NetworkInfo().getWifiName();
      // iOS/Android may wrap the SSID in quotes
      if (ssid != null && ssid.startsWith('"') && ssid.endsWith('"')) {
        ssid = ssid.substring(1, ssid.length - 1);
      }
    } on Object catch (_) {
      // Permission denied or WiFi off — user will type manually
    }

    if (!mounted) return;
    setState(() {
      _phase = _Phase.credentials;
      _error = null;
      if (ssid != null && ssid.isNotEmpty) {
        _ssidController.text = ssid;
      }
    });
  }

  // ---- Phase 5: Send credentials ----

  Future<void> _sendCredentials() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) {
      setState(() => _error = 'Enter a WiFi network name');
      return;
    }

    final sensorIds = _sensorIdsController.text
        .trim()
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      _phase = _Phase.provisioning;
      _sendInProgress = true;
      _error = null;
      _provisioningStatus = 'Sending WiFi credentials...';
    });

    try {
      final ble = ref.read(bleSensorTransferServiceProvider);

      _statusSub?.cancel();
      _statusSub = ble
          .subscribeToReceiverStatus(_selectedDevice!.id)
          .listen(_onProvisioningStatus, onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _error = e is BleTransferException ? e.message : e.toString();
          _phase = _Phase.error;
          _sendInProgress = false;
        });
      });

      await ble.writeWifiCredentials(
        _selectedDevice!.id,
        ssid: ssid,
        password: password,
        sensorIds: sensorIds,
      );

      if (mounted) {
        setState(
            () => _provisioningStatus = 'Credentials sent. Connecting to WiFi...');
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e is BleTransferException
              ? e.message
              : 'Failed to send credentials. Try again.';
          _phase = _Phase.credentials;
          _sendInProgress = false;
        });
      }
    }
  }

  void _onProvisioningStatus(String status) {
    if (!mounted) return;
    switch (status) {
      case BleProtocol.statusWifiOk:
        setState(() =>
            _provisioningStatus = 'WiFi connected! Verifying Firebase...');
      case BleProtocol.statusWifiFail:
        setState(() {
          _error = 'Receiver could not connect to that WiFi network. '
              'Check the SSID and password and try again.';
          _phase = _Phase.credentials;
          _sendInProgress = false;
        });
      case BleProtocol.statusFirebaseOk:
        setState(() {
          _phase = _Phase.done;
          _sendInProgress = false;
        });
      case BleProtocol.statusFirebaseFail:
        setState(() {
          _error = 'WiFi connected, but the receiver could not reach Firebase. '
              'Check your internet connection and try again.';
          _phase = _Phase.credentials;
          _sendInProgress = false;
        });
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Receiver')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (_phase) {
          _Phase.scanning => _buildScanning(theme),
          _Phase.connecting => _buildConnecting(theme),
          _Phase.waitingReady => _buildWaitingReady(theme),
          _Phase.credentials => _buildCredentials(theme),
          _Phase.provisioning => _buildProvisioning(theme),
          _Phase.done => _buildDone(theme),
          _Phase.error => _buildError(theme),
        },
      ),
    );
  }

  // ---- Scanning ----

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
            Text('Scanning for receivers...', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Power-cycle your receiver to enter setup mode, then wait for it to appear here.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_discovered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No receivers found yet...')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _discovered.length,
              itemBuilder: (_, i) {
                final device = _discovered.values.elementAt(i);
                return ListTile(
                  leading: Icon(Icons.router,
                      color: theme.colorScheme.primary),
                  title: Text(device.name.isNotEmpty
                      ? device.name
                      : 'Unknown Receiver'),
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

  // ---- Connecting ----

  Widget _buildConnecting(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Connecting to receiver...', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _selectedDevice?.name ?? 'Receiver',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Waiting for READY ----

  Widget _buildWaitingReady(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Waiting for receiver to be ready...',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The receiver is preparing for WiFi setup.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Credentials ----

  Widget _buildCredentials(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.wifi, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Enter WiFi Credentials',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The receiver needs WiFi to upload sensor data to the cloud.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'WiFi Network (SSID)',
              prefixIcon: Icon(Icons.wifi),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'WiFi Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sensorIdsController,
            decoration: const InputDecoration(
              labelText: 'Allowed Sensor IDs (optional)',
              hintText: 'e.g. 1,2,3',
              prefixIcon: Icon(Icons.sensors),
              border: OutlineInputBorder(),
            ),
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
            onPressed: _sendInProgress ? null : _sendCredentials,
            child: _sendInProgress
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send to Receiver'),
          ),
        ],
      ),
    );
  }

  // ---- Provisioning ----

  Widget _buildProvisioning(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Setting up receiver...', style: theme.textTheme.titleMedium),
          if (_provisioningStatus != null) ...[
            const SizedBox(height: 12),
            Text(
              _provisioningStatus!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ---- Done ----

  Widget _buildDone(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Receiver is ready!', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'WiFi and Firebase are connected. The receiver will now '
            'listen for sensor data over LoRa and upload it automatically.',
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

  // ---- Error ----

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
            onPressed: () {
              _connSub?.cancel();
              _statusSub?.cancel();
              _startScan();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
