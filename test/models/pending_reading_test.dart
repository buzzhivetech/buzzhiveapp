import 'package:flutter_test/flutter_test.dart';

import 'package:buzzhive_app/models/pending_reading.dart';

void main() {
  group('PendingReading', () {
    final reading = PendingReading(
      id: 1,
      sessionId: 10,
      firebaseSensorId: 'sensor_A',
      sequence: 42,
      temp: 25.5,
      hum: 60.0,
      gas: 100.0,
      mic: 0.5,
      db: 45.0,
      ax: 0.1,
      ay: 0.2,
      az: 9.8,
      fx: 1.0,
      fy: 2.0,
      fz: 3.0,
      sensorTimestampMs: 1700000000000,
      receivedAt: DateTime.utc(2024, 1, 1),
      synced: false,
    );

    test('firebaseKey is deterministic from timestamp and sequence', () {
      expect(reading.firebaseKey, equals('1700000000000_42'));
    });

    test('toFirebaseMap contains all sensor fields', () {
      final map = reading.toFirebaseMap();
      expect(map['temp'], 25.5);
      expect(map['hum'], 60.0);
      expect(map['gas'], 100.0);
      expect(map['id'], '1700000000000_42');
      expect(map['timestamp'], 1700000000000);
      expect(map['ax'], 0.1);
    });

    test('two readings with same fields are equal', () {
      final other = PendingReading(
        id: 1,
        sessionId: 10,
        firebaseSensorId: 'sensor_A',
        sequence: 42,
        temp: 25.5,
        hum: 60.0,
        gas: 100.0,
        mic: 0.5,
        db: 45.0,
        ax: 0.1,
        ay: 0.2,
        az: 9.8,
        fx: 1.0,
        fy: 2.0,
        fz: 3.0,
        sensorTimestampMs: 1700000000000,
        receivedAt: DateTime.utc(2024, 1, 1),
        synced: false,
      );
      expect(reading, equals(other));
    });
  });
}
