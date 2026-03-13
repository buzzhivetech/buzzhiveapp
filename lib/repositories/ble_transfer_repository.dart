import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../core/constants/ble_protocol.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/crc16.dart';
import '../models/ble_transfer_session.dart';
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

  /// Parse a DATA frame payload into sensor values.
  /// Binary layout (all little-endian float32 except timestamp which is int64):
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
  ///   Total = 52 bytes
  Map<String, double>? _parseDataPayload(Uint8List payload) {
    if (payload.length < 52) {
      AppLogger.warn('Data payload too short (${payload.length} < 52)', name: _log);
      return null;
    }
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
}
