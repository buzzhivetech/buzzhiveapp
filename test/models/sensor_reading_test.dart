import 'package:flutter_test/flutter_test.dart';
import 'package:buzzhive_app/models/sensor_reading.dart';

void main() {
  group('SensorReading.fromMap', () {
    test('parses a complete map with int timestamp (milliseconds)', () {
      final map = <dynamic, dynamic>{
        'temp': 25.3,
        'hum': 60.0,
        'gas': 100,
        'mic': 512,
        'db': 45.0,
        'ax': 0.1,
        'ay': 0.2,
        'az': 9.8,
        'fx': 1.0,
        'fy': 2.0,
        'fz': 3.0,
        'id': '10001',
        'timestamp': 1700000000000,
      };
      final reading = SensorReading.fromMap(map);
      expect(reading, isNotNull);
      expect(reading!.temp, 25.3);
      expect(reading.hum, 60.0);
      expect(reading.id, '10001');
      expect(reading.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('parses int timestamp in seconds (auto-scales)', () {
      final map = <dynamic, dynamic>{
        'temp': 20.0, 'hum': 50.0, 'gas': 0, 'mic': 0, 'db': 0,
        'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
        'id': 'test', 'timestamp': 1700000000,
      };
      final reading = SensorReading.fromMap(map);
      expect(reading, isNotNull);
      expect(reading!.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('parses string timestamp', () {
      final map = <dynamic, dynamic>{
        'temp': 20.0, 'hum': 50.0, 'gas': 0, 'mic': 0, 'db': 0,
        'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
        'id': 'test', 'timestamp': '2024-01-01T00:00:00.000Z',
      };
      final reading = SensorReading.fromMap(map);
      expect(reading, isNotNull);
      expect(reading!.timestamp, DateTime.utc(2024));
    });

    test('uses timestampKey as fallback id', () {
      final map = <dynamic, dynamic>{
        'temp': 20.0, 'hum': 50.0, 'gas': 0, 'mic': 0, 'db': 0,
        'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
        'timestamp': 1700000000000,
      };
      final reading = SensorReading.fromMap(map, timestampKey: 'my-key');
      expect(reading, isNotNull);
      expect(reading!.id, 'my-key');
    });

    test('handles missing fields with zero defaults', () {
      final map = <dynamic, dynamic>{'timestamp': 1700000000000};
      final reading = SensorReading.fromMap(map);
      expect(reading, isNotNull);
      expect(reading!.temp, 0.0);
      expect(reading.hum, 0.0);
      expect(reading.gas, 0.0);
    });

    test('handles string numbers', () {
      final map = <dynamic, dynamic>{
        'temp': '25.3', 'hum': '60', 'gas': '100', 'mic': '0', 'db': '0',
        'ax': '0', 'ay': '0', 'az': '0', 'fx': '0', 'fy': '0', 'fz': '0',
        'timestamp': 1700000000000,
      };
      final reading = SensorReading.fromMap(map);
      expect(reading, isNotNull);
      expect(reading!.temp, 25.3);
      expect(reading.hum, 60.0);
    });

    test('tempF converts correctly', () {
      final map = <dynamic, dynamic>{
        'temp': 0.0, 'hum': 0, 'gas': 0, 'mic': 0, 'db': 0,
        'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
        'timestamp': 1700000000000,
      };
      final reading = SensorReading.fromMap(map)!;
      expect(reading.tempF, 32.0);
    });
  });
}
