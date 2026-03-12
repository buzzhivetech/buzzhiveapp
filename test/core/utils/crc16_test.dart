import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:buzzhive_app/core/utils/crc16.dart';

void main() {
  group('Crc16', () {
    test('compute returns consistent value for same input', () {
      final data = Uint8List.fromList([0x01, 0x02, 0x03]);
      expect(Crc16.compute(data), equals(Crc16.compute(data)));
    });

    test('compute returns different value for different input', () {
      final a = Uint8List.fromList([0x01, 0x02, 0x03]);
      final b = Uint8List.fromList([0x01, 0x02, 0x04]);
      expect(Crc16.compute(a), isNot(equals(Crc16.compute(b))));
    });

    test('compute with start/end subset', () {
      final data = Uint8List.fromList([0xAA, 0x01, 0x02, 0xBB]);
      final full = Crc16.compute(Uint8List.fromList([0x01, 0x02]));
      final subset = Crc16.compute(data, start: 1, end: 3);
      expect(subset, equals(full));
    });

    test('verify succeeds with correct CRC appended', () {
      final payload = Uint8List.fromList([0x10, 0x00, 0x01, 0xAA, 0xBB]);
      final crc = Crc16.compute(payload);
      final frame = Uint8List.fromList([
        ...payload,
        (crc >> 8) & 0xFF,
        crc & 0xFF,
      ]);
      expect(Crc16.verify(frame), isTrue);
    });

    test('verify fails with wrong CRC', () {
      final frame = Uint8List.fromList([0x10, 0x00, 0x01, 0xFF, 0xFF]);
      expect(Crc16.verify(frame), isFalse);
    });

    test('verify fails for frame shorter than 3 bytes', () {
      expect(Crc16.verify(Uint8List.fromList([0x01, 0x02])), isFalse);
    });
  });
}
