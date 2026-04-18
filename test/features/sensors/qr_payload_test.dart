import 'package:flutter_test/flutter_test.dart';

import 'package:buzzhive_app/features/sensors/domain/qr_payload.dart';

void main() {
  group('QrPayload.parse', () {
    test('parses a well-formed payload', () {
      final p = QrPayload.parse('buzzhive://claim?d=10001&c=7K3M9PQT');
      expect(p.deviceId, '10001');
      expect(p.claimCode, '7K3M9PQT');
    });

    test('trims surrounding whitespace', () {
      final p = QrPayload.parse('  buzzhive://claim?d=5&c=abc123  ');
      expect(p.deviceId, '5');
      expect(p.claimCode, 'ABC123');
    });

    test('uppercases claim code for case-insensitive matching', () {
      final p = QrPayload.parse('buzzhive://claim?d=5&c=abcdef');
      expect(p.claimCode, 'ABCDEF');
    });

    test('throws on empty input', () {
      expect(
        () => QrPayload.parse(''),
        throwsA(isA<QrPayloadException>()),
      );
    });

    test('throws on wrong scheme', () {
      expect(
        () => QrPayload.parse('https://example.com/claim?d=1&c=2'),
        throwsA(isA<QrPayloadException>()),
      );
    });

    test('throws on wrong host', () {
      expect(
        () => QrPayload.parse('buzzhive://signup?d=1&c=2'),
        throwsA(isA<QrPayloadException>()),
      );
    });

    test('throws when device id is missing', () {
      expect(
        () => QrPayload.parse('buzzhive://claim?c=2'),
        throwsA(isA<QrPayloadException>()),
      );
    });

    test('throws when claim code is missing', () {
      expect(
        () => QrPayload.parse('buzzhive://claim?d=5'),
        throwsA(isA<QrPayloadException>()),
      );
    });
  });

  group('QrPayload.encode', () {
    test('round-trips through parse', () {
      const original = QrPayload(deviceId: '10001', claimCode: 'ABCDEF12');
      final encoded = original.encode();
      final parsed = QrPayload.parse(encoded);
      expect(parsed.deviceId, original.deviceId);
      expect(parsed.claimCode, original.claimCode);
    });
  });
}
