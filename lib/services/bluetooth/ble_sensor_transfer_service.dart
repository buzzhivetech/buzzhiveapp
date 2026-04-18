import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../core/utils/app_logger.dart';

/// Low-level BLE operations: scan, connect, subscribe to notifications.
///
/// This service targets the **current** firmware protocol: the sensor
/// advertises the standard Battery Service (`0x180F`) and pushes a single
/// protobuf-encoded [BuzzHiveMessage] on characteristic `0x2A19` whenever a
/// client subscribes. No commands are sent from the phone.
///
/// No persistence or domain logic lives here — that belongs in the
/// repository.
class BleSensorTransferService {
  BleSensorTransferService({FlutterReactiveBle? ble})
      : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;
  static const _log = 'BLE';

  /// Battery Service UUID advertised by the current sensor firmware.
  static final legacyServiceUuid = Uuid.parse('180F');

  /// Battery Level characteristic used by the firmware as the payload pipe.
  static final legacyCharacteristicUuid = Uuid.parse('2A19');

  /// Desired MTU. Current firmware payload is ~70 bytes, so 185 is plenty and
  /// stays under Android's default 517 cap.
  static const int _desiredMtu = 185;

  /// How long we prescan before opening a connection.
  static const Duration _prescanDuration = Duration(seconds: 5);

  /// How long we wait for the OS to open the connection.
  static const Duration _connectionTimeout = Duration(seconds: 15);

  // --- Adapter state ---

  Stream<BleStatus> get statusStream => _ble.statusStream;
  BleStatus get currentStatus => _ble.status;

  // --- Scanning ---

  /// Scan for in-the-field BuzzHive sensors using the current firmware's
  /// advertisement (Battery Service `180F`). The caller should further
  /// filter by local-name prefix (`BuzzHive`) to drop non-BuzzHive
  /// battery devices (headphones, wearables, etc.).
  Stream<DiscoveredDevice> scanForUnclaimedSensors() {
    AppLogger.info('Starting BLE scan for BuzzHive sensors (180F)',
        name: _log);
    return _ble.scanForDevices(
      withServices: [legacyServiceUuid],
      scanMode: ScanMode.lowLatency,
    );
  }

  // --- Connection ---

  /// Connect to a device. Returns a stream of connection state updates;
  /// the caller should wait for [DeviceConnectionState.connected] before
  /// subscribing to characteristics.
  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    AppLogger.info('Connecting to BLE device $deviceId', name: _log);
    return _ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [legacyServiceUuid],
      prescanDuration: _prescanDuration,
      connectionTimeout: _connectionTimeout,
      servicesWithCharacteristicsToDiscover: {
        legacyServiceUuid: [legacyCharacteristicUuid],
      },
    );
  }

  /// Negotiate MTU after connection.  Returns the actual negotiated MTU.
  /// No-op on iOS (handled by the OS) but important on Android where the
  /// default 23-byte MTU would truncate our ~70-byte protobuf payload.
  Future<int> requestMtu(String deviceId) async {
    try {
      final mtu = await _ble.requestMtu(
        deviceId: deviceId,
        mtu: _desiredMtu,
      );
      AppLogger.info('Negotiated MTU: $mtu for $deviceId', name: _log);
      return mtu;
    } on Object catch (e) {
      AppLogger.warn('MTU negotiation failed (continuing): $e', name: _log);
      return 23;
    }
  }

  // --- Characteristics ---

  /// Subscribe to the legacy Battery-Level characteristic. The firmware
  /// pushes one [BuzzHiveMessage] protobuf payload on subscription.
  Stream<List<int>> subscribeToLegacyPayload(String deviceId) {
    final qc = QualifiedCharacteristic(
      serviceId: legacyServiceUuid,
      characteristicId: legacyCharacteristicUuid,
      deviceId: deviceId,
    );
    return _ble.subscribeToCharacteristic(qc);
  }
}
