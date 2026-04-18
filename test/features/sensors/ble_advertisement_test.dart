import 'package:flutter_test/flutter_test.dart';

import 'package:buzzhive_app/features/sensors/domain/ble_advertisement.dart';

void main() {
  group('BleAdvertisementIdentity.tryParse', () {
    test('parses standard BuzzHive-<id> advertisement name', () {
      final id = BleAdvertisementIdentity.tryParse('BuzzHive-10001');
      expect(id, isNotNull);
      expect(id!.deviceId, '10001');
      expect(id.localName, 'BuzzHive-10001');
    });

    test('is case-insensitive on the prefix', () {
      final id = BleAdvertisementIdentity.tryParse('buzzhive-ABCD');
      expect(id, isNotNull);
      expect(id!.deviceId, 'ABCD');
    });

    test('trims surrounding whitespace', () {
      final id = BleAdvertisementIdentity.tryParse('  BuzzHive-7  ');
      expect(id, isNotNull);
      expect(id!.deviceId, '7');
    });

    test('returns null for unrelated advertisement names', () {
      expect(BleAdvertisementIdentity.tryParse('Acme-123'), isNull);
      expect(BleAdvertisementIdentity.tryParse('Unknown'), isNull);
    });

    test('returns null when name is just the prefix', () {
      expect(BleAdvertisementIdentity.tryParse('BuzzHive-'), isNull);
    });

    test('returns null when name is null', () {
      expect(BleAdvertisementIdentity.tryParse(null), isNull);
    });
  });
}
