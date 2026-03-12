import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE GATT service and characteristic UUIDs for BuzzHive sensor transfer.
/// The sensor firmware must advertise this service and implement
/// the characteristics below.
class BleProtocol {
  BleProtocol._();

  /// Custom service UUID advertised by BuzzHive sensors.
  static final serviceUuid =
      Uuid.parse('BEE50001-CAFE-BABE-DEAD-BEEFCAFE0001');

  /// Control characteristic (write): phone sends commands to sensor.
  /// Commands: START_TRANSFER, ACK_BATCH, ABORT, DELETE_CONFIRMED.
  static final controlCharUuid =
      Uuid.parse('BEE50002-CAFE-BABE-DEAD-BEEFCAFE0001');

  /// Data characteristic (notify): sensor streams packet frames to phone.
  static final dataCharUuid =
      Uuid.parse('BEE50003-CAFE-BABE-DEAD-BEEFCAFE0001');

  /// Status characteristic (read/notify): sensor reports transfer metadata.
  static final statusCharUuid =
      Uuid.parse('BEE50004-CAFE-BABE-DEAD-BEEFCAFE0001');

  // --- Control command bytes ---

  /// Request sensor to begin transferring stored readings.
  static const int cmdStartTransfer = 0x01;

  /// Acknowledge receipt of a batch (payload: 2-byte last confirmed seq).
  static const int cmdAckBatch = 0x02;

  /// Resume from a given sequence number (payload: 2-byte seq).
  static const int cmdResume = 0x03;

  /// Abort the current transfer session.
  static const int cmdAbort = 0x04;

  /// Confirm that all data is durably stored; sensor may purge.
  static const int cmdDeleteConfirmed = 0x05;

  // --- Data frame structure ---
  //
  // Byte layout per notification (≤ MTU):
  //   [0]       frame type  (0x10 = SESSION_START, 0x20 = DATA, 0x30 = SESSION_END)
  //   [1..2]    sequence number (big-endian uint16)
  //   [3..N-2]  payload
  //   [N-1..N]  CRC-16 over bytes [0..N-2]

  static const int frameTypeSessionStart = 0x10;
  static const int frameTypeData = 0x20;
  static const int frameTypeSessionEnd = 0x30;

  /// Minimum overhead: 1 type + 2 seq + 2 CRC.
  static const int frameOverheadBytes = 5;

  /// Default desired MTU.
  static const int desiredMtu = 247;

  /// Connection timeout.
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Prescan duration before connecting.
  static const Duration prescanDuration = Duration(seconds: 5);
}
