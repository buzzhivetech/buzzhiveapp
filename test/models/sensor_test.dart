import 'package:flutter_test/flutter_test.dart';
import 'package:buzzhive_app/models/sensor.dart';

void main() {
  group('Sensor.fromMap', () {
    test('parses complete map', () {
      final map = <String, dynamic>{
        'id': 'uuid-1',
        'firebase_sensor_id': '10001',
        'display_name': 'Backyard Hive',
        'created_at': '2024-03-01T10:00:00.000Z',
      };
      final sensor = Sensor.fromMap(map);
      expect(sensor.id, 'uuid-1');
      expect(sensor.firebaseSensorId, '10001');
      expect(sensor.displayName, 'Backyard Hive');
    });

    test('handles null display name', () {
      final map = <String, dynamic>{
        'id': 'uuid-2',
        'firebase_sensor_id': '10002',
        'display_name': null,
        'created_at': '2024-03-01T10:00:00.000Z',
      };
      final sensor = Sensor.fromMap(map);
      expect(sensor.displayName, isNull);
    });
  });
}
