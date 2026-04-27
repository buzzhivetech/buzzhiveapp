import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../core/constants/ble_protocol.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/crc16.dart';
import '../models/ble_transfer_session.dart';
import '../proto/buzzhive_telemetry.pb.dart';
import '../proto/buzzhive_v0.pb.dart';
import '../services/bluetooth/ble_sensor_transfer_service.dart';
import '../services/local/local_packet_store.dart';

/// Orchestrates a BLE download session: connect, receive frames, parse, persist.
class BleTransferRepository {
  BleTransferRepository(this._ble, this._store);

  final BleSensorTransferService _ble;
  final LocalPacketStore _store;
  static const _log = 'BleTransfer';

  Stream<BleStatus> get adapterStatus => _ble.statusStream;
  BleStatus get currentAdapterStatus => _ble.currentStatus;

  Stream<DiscoveredDevice> scanForSensors() => _ble.scanForSensors();

  /// Run a full download session. Yields progress updates (received count).
  /// The caller should listen to the stream; on completion it closes.
  Stream<int> downloadSession({
    required String deviceId,
    required String sensorId,
    required String firebaseSensorId,
  }) async* {
    StreamSubscription<ConnectionStateUpdate>? connSub;
    StreamSubscription<List<int>>? dataSub;
    int? sessionId;

    try {
      // 1. Connect
      final connCompleter = Completer<void>();
      connSub = _ble.connectToDevice(deviceId).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected &&
            !connCompleter.isCompleted) {
          connCompleter.complete();
        }
        if (update.connectionState == DeviceConnectionState.disconnected &&
            !connCompleter.isCompleted) {
          connCompleter.completeError(
            const BleTransferException('Device disconnected during setup'),
          );
        }
      }, onError: (Object e) {
        if (!connCompleter.isCompleted) connCompleter.completeError(e);
      });

      await connCompleter.future;
      AppLogger.info('Connected to $deviceId', name: _log);

      await _ble.requestMtu(deviceId);

      // 2. Create local session
      sessionId = await _store.createSession(
        sensorId: sensorId,
        firebaseSensorId: firebaseSensorId,
      );

      // 3. Subscribe to data notifications
      var receivedCount = 0;
      var lastSeq = -1;
      final transferDone = Completer<void>();

      dataSub = _ble.subscribeToData(deviceId).listen((raw) async {
        final frame = Uint8List.fromList(raw);
        if (frame.length < BleProtocol.frameOverheadBytes) return;

        if (!Crc16.verify(frame)) {
          AppLogger.warn('CRC mismatch on frame, skipping', name: _log);
          return;
        }

        final type = frame[0];
        final seq = (frame[1] << 8) | frame[2];
        final payload = frame.sublist(3, frame.length - 2);

        switch (type) {
          case BleProtocol.frameTypeSessionStart:
            final expectedCount = payload.length >= 2
                ? (payload[0] << 8) | payload[1]
                : 0;
            await _store.updateSessionProgress(sessionId!, receivedCount: 0);
            AppLogger.info(
              'Session start: expecting $expectedCount readings',
              name: _log,
            );

          case BleProtocol.frameTypeData:
            final reading = _parseDataPayload(payload);
            if (reading != null) {
              await _store.insertReading(
                sessionId: sessionId!,
                firebaseSensorId: firebaseSensorId,
                sequence: seq,
                temp: reading['temp']!,
                hum: reading['hum']!,
                gas: reading['gas']!,
                mic: reading['mic']!,
                db: reading['db']!,
                ax: reading['ax']!,
                ay: reading['ay']!,
                az: reading['az']!,
                fx: reading['fx']!,
                fy: reading['fy']!,
                fz: reading['fz']!,
                vbat: reading['vbat'] ?? 0,
                weightKg: reading['weight_kg'] ?? 0,
                sensorTimestampMs: reading['ts']!.toInt(),
              );
              receivedCount++;
              lastSeq = seq;
              await _store.updateSessionProgress(
                sessionId,
                receivedCount: receivedCount,
                lastSeq: lastSeq,
              );
            }

          case BleProtocol.frameTypeSessionEnd:
            AppLogger.info('Session end received ($receivedCount readings)', name: _log);
            if (!transferDone.isCompleted) transferDone.complete();
        }
      }, onError: (Object e) {
        if (!transferDone.isCompleted) transferDone.completeError(e);
      });

      // 4. Tell sensor to start
      await _ble.sendStartTransfer(deviceId);

      // 5. Yield progress periodically while waiting for completion
      while (!transferDone.isCompleted) {
        await Future.delayed(const Duration(milliseconds: 250));
        yield receivedCount;
        if (transferDone.isCompleted) break;
      }
      await transferDone.future;
      yield receivedCount;

      // 6. ACK and finalize
      if (lastSeq >= 0) {
        await _ble.sendAckBatch(deviceId, lastSeq);
      }
      await _store.completeSession(sessionId, TransferSessionStatus.complete);
      AppLogger.info('Download session $sessionId complete: $receivedCount readings', name: _log);
    } on BleTransferException {
      if (sessionId != null) {
        await _store.completeSession(sessionId, TransferSessionStatus.failed);
      }
      rethrow;
    } on Object catch (e, st) {
      AppLogger.error('Download session failed', name: _log, error: e, stackTrace: st);
      if (sessionId != null) {
        await _store.completeSession(sessionId, TransferSessionStatus.failed);
      }
      throw BleTransferException(e.toString());
    } finally {
      await dataSub?.cancel();
      await connSub?.cancel();
    }
  }

  /// Receive live readings from a V0 sensor (raw protobuf on BLE notify).
  ///
  /// V0 sensors transmit the latest reading automatically on connect, then
  /// keep sending fresh data every ~10 s while the phone stays connected.
  /// Yields the running count of received readings.  The stream completes
  /// after [timeout] of silence (no new notifications).
  Stream<int> v0ReceiveSession({
    required String deviceId,
    required String sensorId,
    required String firebaseSensorId,
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    StreamSubscription<ConnectionStateUpdate>? connSub;
    StreamSubscription<List<int>>? dataSub;
    int? sessionId;

    try {
      // 1. Connect via V0 (Battery Service 180F)
      final connCompleter = Completer<void>();
      connSub = _ble.connectToV0Device(deviceId).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected &&
            !connCompleter.isCompleted) {
          connCompleter.complete();
        }
        if (update.connectionState == DeviceConnectionState.disconnected &&
            !connCompleter.isCompleted) {
          connCompleter.completeError(
            const BleTransferException('V0 device disconnected during setup'),
          );
        }
      }, onError: (Object e) {
        if (!connCompleter.isCompleted) connCompleter.completeError(e);
      });

      await connCompleter.future;
      AppLogger.info('Connected to V0 device $deviceId', name: _log);

      await _ble.requestMtu(deviceId);

      // 2. Create local session
      sessionId = await _store.createSession(
        sensorId: sensorId,
        firebaseSensorId: firebaseSensorId,
      );

      // 3. Subscribe to raw protobuf notifications on 2A19
      var receivedCount = 0;
      var sequence = 0;
      final done = Completer<void>();
      Timer? silenceTimer;

      void resetSilenceTimer() {
        silenceTimer?.cancel();
        silenceTimer = Timer(timeout, () {
          if (!done.isCompleted) {
            AppLogger.info(
              'V0 silence timeout — closing session ($receivedCount readings)',
              name: _log,
            );
            done.complete();
          }
        });
      }

      resetSilenceTimer();

      dataSub = _ble.subscribeToV0Data(deviceId).listen((raw) async {
        final payload = Uint8List.fromList(raw);
        final reading = _parseProtobufPayload(payload);
        if (reading != null) {
          await _store.insertReading(
            sessionId: sessionId!,
            firebaseSensorId: firebaseSensorId,
            sequence: sequence,
            temp: reading['temp']!,
            hum: reading['hum']!,
            gas: reading['gas']!,
            mic: reading['mic']!,
            db: reading['db']!,
            ax: reading['ax']!,
            ay: reading['ay']!,
            az: reading['az']!,
            fx: reading['fx']!,
            fy: reading['fy']!,
            fz: reading['fz']!,
            vbat: reading['vbat'] ?? 0,
            weightKg: reading['weight_kg'] ?? 0,
            sensorTimestampMs: reading['ts']!.toInt(),
          );
          receivedCount++;
          sequence++;
          resetSilenceTimer();
          await _store.updateSessionProgress(
            sessionId,
            receivedCount: receivedCount,
            lastSeq: sequence,
          );
        }
      }, onError: (Object e) {
        if (!done.isCompleted) done.completeError(e);
      });

      // 4. Yield progress while waiting
      while (!done.isCompleted) {
        await Future.delayed(const Duration(milliseconds: 250));
        yield receivedCount;
        if (done.isCompleted) break;
      }
      await done.future;
      yield receivedCount;

      silenceTimer?.cancel();
      await _store.completeSession(sessionId, TransferSessionStatus.complete);
      AppLogger.info(
        'V0 session $sessionId complete: $receivedCount readings',
        name: _log,
      );
    } on BleTransferException {
      if (sessionId != null) {
        await _store.completeSession(sessionId, TransferSessionStatus.failed);
      }
      rethrow;
    } on Object catch (e, st) {
      AppLogger.error('V0 session failed', name: _log, error: e, stackTrace: st);
      if (sessionId != null) {
        await _store.completeSession(sessionId, TransferSessionStatus.failed);
      }
      throw BleTransferException(e.toString());
    } finally {
      await dataSub?.cancel();
      await connSub?.cancel();
    }
  }

  /// Parse a DATA frame payload into sensor values.
  /// Tries the legacy 52-byte binary format first, then falls back to
  /// protobuf decoding for future firmware versions.
  Map<String, double>? _parseDataPayload(Uint8List payload) {
    if (payload.length == 52) {
      return _parseBinaryPayload(payload);
    }
    final proto = _parseProtobufPayload(payload);
    if (proto != null) return proto;
    AppLogger.warn(
      'Unrecognized payload format (${payload.length} bytes)',
      name: _log,
    );
    return null;
  }

  /// Legacy 52-byte little-endian binary format:
  ///   [0..7]   timestamp ms (int64 LE)
  ///   [8..11]  temp   (float32 LE)
  ///   [12..15] hum    (float32 LE)
  ///   [16..19] gas    (float32 LE)
  ///   [20..23] mic    (float32 LE)
  ///   [24..27] db     (float32 LE)
  ///   [28..31] ax     (float32 LE)
  ///   [32..35] ay     (float32 LE)
  ///   [36..39] az     (float32 LE)
  ///   [40..43] fx     (float32 LE)
  ///   [44..47] fy     (float32 LE)
  ///   [48..51] fz     (float32 LE)
  Map<String, double>? _parseBinaryPayload(Uint8List payload) {
    if (payload.length < 52) return null;
    final bd = ByteData.sublistView(payload);
    final tsMs = bd.getInt64(0, Endian.little);
    return {
      'ts': tsMs.toDouble(),
      'temp': bd.getFloat32(8, Endian.little).toDouble(),
      'hum': bd.getFloat32(12, Endian.little).toDouble(),
      'gas': bd.getFloat32(16, Endian.little).toDouble(),
      'mic': bd.getFloat32(20, Endian.little).toDouble(),
      'db': bd.getFloat32(24, Endian.little).toDouble(),
      'ax': bd.getFloat32(28, Endian.little).toDouble(),
      'ay': bd.getFloat32(32, Endian.little).toDouble(),
      'az': bd.getFloat32(36, Endian.little).toDouble(),
      'fx': bd.getFloat32(40, Endian.little).toDouble(),
      'fy': bd.getFloat32(44, Endian.little).toDouble(),
      'fz': bd.getFloat32(48, Endian.little).toDouble(),
    };
  }

  /// Decode a protobuf payload.
  ///
  /// Tries the V0 hardware format (BuzzHiveMessage wrapping SensorData or
  /// ScaleData) first, then falls back to the app-native HiveSensorTelemetry
  /// schema for forward-compatibility with future firmware.
  Map<String, double>? _parseProtobufPayload(Uint8List payload) {
    final v0 = _parseV0BuzzHiveMessage(payload);
    if (v0 != null) return v0;

    final app = _parseAppTelemetry(payload);
    if (app != null) return app;

    AppLogger.warn('Protobuf decode failed for both V0 and app schemas', name: _log);
    return null;
  }

  /// Decode a V0 BuzzHiveMessage (nanopb) and route by payload type.
  Map<String, double>? _parseV0BuzzHiveMessage(Uint8List payload) {
    try {
      final msg = V0BuzzHiveMessage.fromBuffer(payload);

      switch (msg.whichPayload()) {
        case V0BuzzHiveMessage_Payload.sensorData:
          final s = msg.sensorData;
          AppLogger.info(
            'Decoded V0 SensorData (node ${s.nodeId})',
            name: _log,
          );
          return {
            'ts': DateTime.now().millisecondsSinceEpoch.toDouble(),
            'node_id': s.nodeId.toDouble(),
            'temp': s.temp.toDouble(),
            'hum': s.humid.toDouble(),
            'gas': s.gas.toDouble(),
            'mic': s.micFreq.toDouble(),
            'db': s.micDb.toDouble(),
            'ax': s.freqX.toDouble(),
            'ay': s.freqY.toDouble(),
            'az': s.freqZ.toDouble(),
            'fx': s.maxX.toDouble(),
            'fy': s.maxY.toDouble(),
            'fz': s.maxZ.toDouble(),
            'vbat': s.vbat.toDouble(),
          };

        case V0BuzzHiveMessage_Payload.scaleData:
          final sc = msg.scaleData;
          AppLogger.info(
            'Decoded V0 ScaleData (node ${sc.nodeId})',
            name: _log,
          );
          return {
            'ts': DateTime.now().millisecondsSinceEpoch.toDouble(),
            'node_id': sc.nodeId.toDouble(),
            'weight_kg': sc.weightKg.toDouble(),
            'vbat': sc.battery.toDouble(),
            'temp': 0, 'hum': 0, 'gas': 0,
            'mic': 0, 'db': 0,
            'ax': 0, 'ay': 0, 'az': 0,
            'fx': 0, 'fy': 0, 'fz': 0,
          };

        case V0BuzzHiveMessage_Payload.notSet:
          AppLogger.warn('V0 BuzzHiveMessage has no payload set', name: _log);
          return null;
      }
    } on Object {
      return null;
    }
  }

  /// Decode the app-native HiveSensorTelemetry (for future firmware).
  Map<String, double>? _parseAppTelemetry(Uint8List payload) {
    try {
      final msg = HiveSensorTelemetry.fromBuffer(payload);
      final accel = msg.hasAccel() ? msg.accel : null;
      final force = msg.hasForce() ? msg.force : null;
      AppLogger.info('Decoded protobuf HiveSensorTelemetry', name: _log);
      return {
        'ts': DateTime.now().millisecondsSinceEpoch.toDouble(),
        'temp': msg.temperatureC.toDouble(),
        'hum': msg.humidityPct.toDouble(),
        'gas': msg.vocIndex.toDouble(),
        'mic': msg.microphoneHz.toDouble(),
        'db': msg.soundLevelDb.toDouble(),
        'ax': accel?.x.toDouble() ?? 0,
        'ay': accel?.y.toDouble() ?? 0,
        'az': accel?.z.toDouble() ?? 0,
        'fx': force?.x.toDouble() ?? 0,
        'fy': force?.y.toDouble() ?? 0,
        'fz': force?.z.toDouble() ?? 0,
      };
    } on Object {
      return null;
    }
  }
}
