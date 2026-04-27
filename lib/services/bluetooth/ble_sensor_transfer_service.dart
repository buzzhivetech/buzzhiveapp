import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../core/constants/ble_protocol.dart';
import '../../core/utils/app_logger.dart';

/// Low-level BLE operations: scan, connect, send commands, receive data frames.
/// No persistence or domain logic — that belongs in the repository.
class BleSensorTransferService {
  BleSensorTransferService({FlutterReactiveBle? ble})
      : _ble = ble ?? FlutterReactiveBle();

  final FlutterReactiveBle _ble;
  static const _log = 'BLE';

  // --- Adapter state ---

  Stream<BleStatus> get statusStream => _ble.statusStream;
  BleStatus get currentStatus => _ble.status;

  // --- Scanning ---

  /// Scan for BuzzHive sensors.
  ///
  /// Matches both V0 hardware (Battery Service 180F, name "BuzzHive_Sensor")
  /// and future firmware using the custom BEE5 service UUID.  V0 advertises
  /// the standard Battery Service which many devices use, so results are
  /// filtered by name prefix to avoid noise.
  Stream<DiscoveredDevice> scanForSensors() {
    AppLogger.info('Starting BLE scan for BuzzHive sensors', name: _log);
    return _ble.scanForDevices(
      withServices: [BleProtocol.serviceUuid, BleProtocol.v0ServiceUuid],
      scanMode: ScanMode.lowLatency,
    ).where((d) =>
        d.name.startsWith('BuzzHive') ||
        d.serviceUuids.contains(BleProtocol.serviceUuid));
  }

  // --- Connection ---

  /// Connect to a V0 sensor (Battery Service 180F).
  Stream<ConnectionStateUpdate> connectToV0Device(String deviceId) {
    AppLogger.info('Connecting to V0 BLE device $deviceId', name: _log);
    return _ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [BleProtocol.v0ServiceUuid],
      prescanDuration: BleProtocol.prescanDuration,
      connectionTimeout: BleProtocol.connectionTimeout,
      servicesWithCharacteristicsToDiscover: {
        BleProtocol.v0ServiceUuid: [BleProtocol.v0DataCharUuid],
      },
    );
  }

  /// Connect to a device running the future framed protocol (BEE5 service).
  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    AppLogger.info('Connecting to BLE device $deviceId', name: _log);
    return _ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [BleProtocol.serviceUuid],
      prescanDuration: BleProtocol.prescanDuration,
      connectionTimeout: BleProtocol.connectionTimeout,
      servicesWithCharacteristicsToDiscover: {
        BleProtocol.serviceUuid: [
          BleProtocol.controlCharUuid,
          BleProtocol.dataCharUuid,
          BleProtocol.statusCharUuid,
        ],
      },
    );
  }

  /// Negotiate MTU after connection.  Returns the actual negotiated MTU.
  Future<int> requestMtu(String deviceId) async {
    final mtu = await _ble.requestMtu(
      deviceId: deviceId,
      mtu: BleProtocol.desiredMtu,
    );
    AppLogger.info('Negotiated MTU: $mtu for $deviceId', name: _log);
    return mtu;
  }

  // --- Characteristics ---

  QualifiedCharacteristic _char(String deviceId, Uuid charUuid) =>
      QualifiedCharacteristic(
        serviceId: BleProtocol.serviceUuid,
        characteristicId: charUuid,
        deviceId: deviceId,
      );

  /// Subscribe to raw protobuf notifications from a V0 sensor (2A19 char).
  Stream<List<int>> subscribeToV0Data(String deviceId) {
    return _ble.subscribeToCharacteristic(
      QualifiedCharacteristic(
        serviceId: BleProtocol.v0ServiceUuid,
        characteristicId: BleProtocol.v0DataCharUuid,
        deviceId: deviceId,
      ),
    );
  }

  /// Subscribe to data notifications from the sensor (framed protocol).
  Stream<List<int>> subscribeToData(String deviceId) {
    return _ble.subscribeToCharacteristic(
      _char(deviceId, BleProtocol.dataCharUuid),
    );
  }

  /// Subscribe to status notifications from the sensor.
  Stream<List<int>> subscribeToStatus(String deviceId) {
    return _ble.subscribeToCharacteristic(
      _char(deviceId, BleProtocol.statusCharUuid),
    );
  }

  /// Read the current status characteristic value.
  Future<List<int>> readStatus(String deviceId) {
    return _ble.readCharacteristic(
      _char(deviceId, BleProtocol.statusCharUuid),
    );
  }

  /// Write a command to the control characteristic.
  Future<void> writeCommand(String deviceId, Uint8List command) async {
    await _ble.writeCharacteristicWithResponse(
      _char(deviceId, BleProtocol.controlCharUuid),
      value: command,
    );
  }

  // --- Convenience command builders ---

  Future<void> sendStartTransfer(String deviceId) =>
      writeCommand(deviceId, Uint8List.fromList([BleProtocol.cmdStartTransfer]));

  Future<void> sendAckBatch(String deviceId, int lastSeq) =>
      writeCommand(deviceId, Uint8List.fromList([
        BleProtocol.cmdAckBatch,
        (lastSeq >> 8) & 0xFF,
        lastSeq & 0xFF,
      ]));

  Future<void> sendResume(String deviceId, int fromSeq) =>
      writeCommand(deviceId, Uint8List.fromList([
        BleProtocol.cmdResume,
        (fromSeq >> 8) & 0xFF,
        fromSeq & 0xFF,
      ]));

  Future<void> sendAbort(String deviceId) =>
      writeCommand(deviceId, Uint8List.fromList([BleProtocol.cmdAbort]));

  Future<void> sendDeleteConfirmed(String deviceId) =>
      writeCommand(deviceId, Uint8List.fromList([BleProtocol.cmdDeleteConfirmed]));

  // =====================================================================
  // Receiver WiFi provisioning
  // =====================================================================

  /// Scan for BuzzHive receivers in setup mode.
  Stream<DiscoveredDevice> scanForReceivers() {
    AppLogger.info('Starting BLE scan for BuzzHive receivers', name: _log);
    return _ble.scanForDevices(
      withServices: [BleProtocol.receiverServiceUuid],
      scanMode: ScanMode.lowLatency,
    ).where((d) => BleProtocol.isReceiverDevice(d));
  }

  /// Connect to a receiver in setup mode.
  Stream<ConnectionStateUpdate> connectToReceiver(String deviceId) {
    AppLogger.info('Connecting to receiver $deviceId', name: _log);
    return _ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [BleProtocol.receiverServiceUuid],
      prescanDuration: BleProtocol.prescanDuration,
      connectionTimeout: BleProtocol.connectionTimeout,
      servicesWithCharacteristicsToDiscover: {
        BleProtocol.receiverServiceUuid: [
          BleProtocol.receiverCredCharUuid,
          BleProtocol.receiverStatusCharUuid,
        ],
      },
    );
  }

  QualifiedCharacteristic _receiverChar(String deviceId, Uuid charUuid) =>
      QualifiedCharacteristic(
        serviceId: BleProtocol.receiverServiceUuid,
        characteristicId: charUuid,
        deviceId: deviceId,
      );

  /// Subscribe to provisioning status notifications from the receiver.
  /// Values are UTF-8 strings: READY, WIFI_OK, WIFI_FAIL, etc.
  Stream<String> subscribeToReceiverStatus(String deviceId) {
    return _ble
        .subscribeToCharacteristic(
          _receiverChar(deviceId, BleProtocol.receiverStatusCharUuid),
        )
        .map((bytes) => utf8.decode(bytes));
  }

  /// Write WiFi credentials (and optional sensor IDs) to the receiver.
  /// Payload format: "SSID\nPASS\nID1,ID2,ID3"
  Future<void> writeWifiCredentials(
    String deviceId, {
    required String ssid,
    required String password,
    List<String> sensorIds = const [],
  }) async {
    final payload = StringBuffer()
      ..write(ssid)
      ..write('\n')
      ..write(password);
    if (sensorIds.isNotEmpty) {
      payload
        ..write('\n')
        ..write(sensorIds.join(','));
    }
    final bytes = utf8.encode(payload.toString());
    AppLogger.info(
      'Writing WiFi credentials to receiver (${bytes.length} bytes)',
      name: _log,
    );
    await _ble.writeCharacteristicWithResponse(
      _receiverChar(deviceId, BleProtocol.receiverCredCharUuid),
      value: bytes,
    );
  }
}
