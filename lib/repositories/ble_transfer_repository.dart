import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../features/sensors/domain/ble_advertisement.dart';
import '../generated/proto/buzzhive.pb.dart';
import '../models/ble_transfer_session.dart';
import '../services/bluetooth/ble_sensor_transfer_service.dart';
import '../services/local/local_packet_store.dart';

/// State emitted by [BleTransferRepository.syncSingleReading] as it walks
/// through the one-shot BLE pull lifecycle.
sealed class SensorSyncState {
  const SensorSyncState();
}

class SensorSyncIdle extends SensorSyncState {
  const SensorSyncIdle();
}

/// Scanning for the targeted sensor by its advertised name.
class SensorSyncScanning extends SensorSyncState {
  const SensorSyncScanning();
}

/// Found the device and opening the GATT connection.
class SensorSyncConnecting extends SensorSyncState {
  const SensorSyncConnecting();
}

/// Connected and subscribed; waiting for the firmware's push.
class SensorSyncWaiting extends SensorSyncState {
  const SensorSyncWaiting();
}

/// One reading was decoded and persisted locally. The caller should now
/// trigger an upload (e.g. `SyncRepository.syncNow()`).
class SensorSyncSuccess extends SensorSyncState {
  const SensorSyncSuccess({
    required this.firebaseSensorId,
    required this.sensorTimestampMs,
  });

  final String firebaseSensorId;
  final int sensorTimestampMs;
}

/// Terminal failure state; [message] is safe to surface to the user.
class SensorSyncFailure extends SensorSyncState {
  const SensorSyncFailure(this.message, {this.code});

  final String message;
  final String? code;
}

/// Orchestrates a single-shot BLE pull from the currently-shipping firmware:
///   1. scan for the sensor by advertised name
///   2. connect + negotiate MTU
///   3. subscribe to `180F/2A19` and wait for the first protobuf frame
///   4. decode, map to `PendingReading`, and persist locally
///
/// Emits progress as [SensorSyncState] on the returned stream and closes it
/// on either success or failure. Cancelling the subscription aborts the
/// session and releases the BLE connection.
class BleTransferRepository {
  BleTransferRepository(this._ble, this._store);

  final BleSensorTransferService _ble;
  final LocalPacketStore _store;
  static const _log = 'BleTransfer';

  Stream<BleStatus> get adapterStatus => _ble.statusStream;
  BleStatus get currentAdapterStatus => _ble.currentStatus;

  /// Pull one reading from the sensor advertised as [advertisedName]
  /// (e.g. `BuzzHive-15`). Persists the reading into the local SQLite
  /// queue and emits [SensorSyncSuccess] when done.
  Stream<SensorSyncState> syncSingleReading({
    required String advertisedName,
    required String sensorId,
    required String firebaseSensorId,
    Duration timeout = const Duration(seconds: 90),
  }) async* {
    StreamSubscription<DiscoveredDevice>? scanSub;
    StreamSubscription<ConnectionStateUpdate>? connSub;
    StreamSubscription<List<int>>? payloadSub;

    try {
      yield const SensorSyncScanning();

      // 1. Scan until we see a device whose name matches our target.
      final device = await _findDevice(
        advertisedName: advertisedName,
        timeout: timeout,
        onSub: (s) => scanSub = s,
      );
      await scanSub?.cancel();
      scanSub = null;

      // 2. Connect.
      yield const SensorSyncConnecting();
      final connected = Completer<void>();
      connSub = _ble.connectToDevice(device.id).listen(
        (update) {
          switch (update.connectionState) {
            case DeviceConnectionState.connected:
              if (!connected.isCompleted) connected.complete();
            case DeviceConnectionState.disconnected:
              if (!connected.isCompleted) {
                connected.completeError(
                  const BleTransferException(
                    'Device disconnected before handshake',
                  ),
                );
              }
            case DeviceConnectionState.connecting:
            case DeviceConnectionState.disconnecting:
              break;
          }
        },
        onError: (Object e) {
          if (!connected.isCompleted) connected.completeError(e);
        },
      );
      await connected.future.timeout(
        timeout,
        onTimeout: () => throw const BleTransferException(
          'Timed out connecting to sensor',
        ),
      );
      await _ble.requestMtu(device.id);

      // 3. Subscribe and wait for the first protobuf push.
      yield const SensorSyncWaiting();
      final payload = Completer<List<int>>();
      payloadSub = _ble.subscribeToLegacyPayload(device.id).listen(
        (bytes) {
          if (!payload.isCompleted) payload.complete(bytes);
        },
        onError: (Object e) {
          if (!payload.isCompleted) payload.completeError(e);
        },
      );
      final bytes = await payload.future.timeout(
        timeout,
        onTimeout: () => throw const BleTransferException(
          'Sensor did not push a reading in time',
        ),
      );

      // 4. Decode + persist.
      final reading = _decode(bytes);
      if (reading == null) {
        throw const BleTransferException(
          'Received payload but could not decode sensor data',
        );
      }
      final sessionId = await _store.createSession(
        sensorId: sensorId,
        firebaseSensorId: firebaseSensorId,
        expectedCount: 1,
      );
      final timestampMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _store.insertReading(
        sessionId: sessionId,
        firebaseSensorId: firebaseSensorId,
        sequence: 0,
        temp: reading.temp,
        hum: reading.humid,
        gas: reading.gas,
        mic: reading.micFreq,
        db: reading.micDb,
        ax: reading.maxX,
        ay: reading.maxY,
        az: reading.maxZ,
        fx: reading.freqX,
        fy: reading.freqY,
        fz: reading.freqZ,
        sensorTimestampMs: timestampMs,
      );
      await _store.updateSessionProgress(sessionId, receivedCount: 1);
      await _store.completeSession(sessionId, TransferSessionStatus.complete);
      AppLogger.info(
        'BLE pull complete for $firebaseSensorId (session $sessionId)',
        name: _log,
      );

      yield SensorSyncSuccess(
        firebaseSensorId: firebaseSensorId,
        sensorTimestampMs: timestampMs,
      );
    } on BleTransferException catch (e) {
      AppLogger.warn('BLE pull failed: ${e.message}', name: _log);
      yield SensorSyncFailure(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('BLE pull errored', name: _log, error: e, stackTrace: st);
      yield SensorSyncFailure(e.toString());
    } finally {
      await payloadSub?.cancel();
      await connSub?.cancel();
      await scanSub?.cancel();
    }
  }

  Future<DiscoveredDevice> _findDevice({
    required String advertisedName,
    required Duration timeout,
    required void Function(StreamSubscription<DiscoveredDevice>) onSub,
  }) {
    final completer = Completer<DiscoveredDevice>();
    // Case-insensitive match to be resilient to OS quirks on iOS which
    // sometimes reports a cached, differently-cased local name.
    final target = advertisedName.toLowerCase();
    final sub = _ble.scanForUnclaimedSensors().listen(
      (device) {
        if (completer.isCompleted) return;
        final name = device.name.trim();
        if (name.toLowerCase() == target) {
          completer.complete(device);
          return;
        }
        // Fallback: legacy firmware without NODE_ID in the name advertises
        // as `BuzzHive_Sensor`. Accept the first such match — the caller
        // has already resolved the target sensor contextually.
        final parsed = BleAdvertisementIdentity.tryParse(name);
        if (parsed != null && !parsed.isIdentified) {
          completer.complete(device);
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    onSub(sub);
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        sub.cancel();
        throw BleTransferException(
          'Could not find sensor "$advertisedName" nearby',
        );
      },
    );
  }

  /// Decode a protobuf push into its [SensorData] payload, or null if the
  /// message did not carry sensor data (e.g. ScaleData variant).
  SensorData? _decode(List<int> bytes) {
    try {
      final msg = BuzzHiveMessage.fromBuffer(bytes);
      if (msg.whichPayload() == BuzzHiveMessage_Payload.sensorData) {
        return msg.sensorData;
      }
      return null;
    } on Object catch (e) {
      AppLogger.warn('Protobuf decode failed: $e', name: _log);
      return null;
    }
  }
}
