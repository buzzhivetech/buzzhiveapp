import 'dart:async';
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

  /// Scan for BuzzHive sensors advertising our service UUID.
  Stream<DiscoveredDevice> scanForSensors() {
    AppLogger.info('Starting BLE scan for BuzzHive sensors', name: _log);
    return _ble.scanForDevices(
      withServices: [BleProtocol.serviceUuid],
      scanMode: ScanMode.lowLatency,
    );
  }

  // --- Connection ---

  /// Connect to a device and negotiate MTU.  Returns a stream of connection
  /// state updates; the caller should wait for [DeviceConnectionState.connected]
  /// before issuing commands.
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

  /// Subscribe to data notifications from the sensor.
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
}
