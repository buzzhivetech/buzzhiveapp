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

    test('parses generic BuzzHive_Sensor name without an id', () {
      final id = BleAdvertisementIdentity.tryParse('BuzzHive_Sensor');
      expect(id, isNotNull);
      expect(id!.deviceId, isNull);
      expect(id.isIdentified, isFalse);
      expect(id.localName, 'BuzzHive_Sensor');
    });

    test('identified advertisement reports isIdentified=true', () {
      final id = BleAdvertisementIdentity.tryParse('BuzzHive-42');
      expect(id!.isIdentified, isTrue);
    });

    test('treats "BuzzHive-" alone as unidentified rather than a parse failure',
        () {
      // "BuzzHive-" is shorter than/equal to the identified prefix, so the
      // dashed parse bails; the generic/brand-prefix branch then accepts it.
      final id = BleAdvertisementIdentity.tryParse('BuzzHive-');
      expect(id, isNotNull);
      expect(id!.deviceId, isNull);
    });

    test('returns null when name is null', () {
      expect(BleAdvertisementIdentity.tryParse(null), isNull);
    });
  });
}
