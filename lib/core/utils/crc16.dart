import 'dart:typed_data';

/// CRC-16/CCITT-FALSE used for BLE frame integrity checks.
class Crc16 {
  Crc16._();

  static int compute(Uint8List data, {int start = 0, int? end}) {
    var crc = 0xFFFF;
    final stop = end ?? data.length;
    for (var i = start; i < stop; i++) {
      crc ^= (data[i] & 0xFF) << 8;
      for (var j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc;
  }

  /// Verify that the last 2 bytes of [frame] match CRC-16 of the preceding bytes.
  static bool verify(Uint8List frame) {
    if (frame.length < 3) return false;
    final payloadEnd = frame.length - 2;
    final expected = compute(frame, end: payloadEnd);
    final actual = (frame[payloadEnd] << 8) | frame[payloadEnd + 1];
    return expected == actual;
  }
}
