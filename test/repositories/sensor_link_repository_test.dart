import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/repositories/sensor_link_repository.dart';
import 'package:buzzhive_app/services/supabase/supabase_user_data_service.dart';

class MockUserDataService extends Mock implements SupabaseUserDataService {}

void main() {
  late MockUserDataService mockData;
  late SensorLinkRepositoryImpl repo;

  setUp(() {
    mockData = MockUserDataService();
    repo = SensorLinkRepositoryImpl(mockData);
  });

  group('linkSensor', () {
    test('upserts sensor then inserts link', () async {
      when(() => mockData.upsertSensor(
            firebaseSensorId: '10001',
            displayName: 'Hive A',
          )).thenAnswer((_) async => 'sensor-uuid');
      when(() => mockData.insertUserSensorLink(
            userId: 'uid',
            sensorId: 'sensor-uuid',
            displayName: 'Hive A',
          )).thenAnswer((_) async {});

      final sensor = await repo.linkSensor('uid', '10001', displayName: 'Hive A');
      expect(sensor.firebaseSensorId, '10001');
      expect(sensor.id, 'sensor-uuid');
      verify(() => mockData.upsertSensor(firebaseSensorId: '10001', displayName: 'Hive A')).called(1);
      verify(() => mockData.insertUserSensorLink(userId: 'uid', sensorId: 'sensor-uuid', displayName: 'Hive A')).called(1);
    });

    test('throws ValidationException on duplicate (23505)', () async {
      when(() => mockData.upsertSensor(firebaseSensorId: any(named: 'firebaseSensorId'), displayName: any(named: 'displayName')))
          .thenAnswer((_) async => 'sensor-uuid');
      when(() => mockData.insertUserSensorLink(userId: any(named: 'userId'), sensorId: any(named: 'sensorId'), displayName: any(named: 'displayName')))
          .thenThrow(supabase.PostgrestException(message: 'duplicate', code: '23505'));

      expect(
        () => repo.linkSensor('uid', '10001'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws AppException on other PostgrestException', () async {
      when(() => mockData.upsertSensor(firebaseSensorId: any(named: 'firebaseSensorId'), displayName: any(named: 'displayName')))
          .thenThrow(supabase.PostgrestException(message: 'RLS', code: '42501'));

      expect(
        () => repo.linkSensor('uid', '10001'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', '42501')),
      );
    });
  });

  group('getLinkedSensors', () {
    test('returns parsed list', () async {
      when(() => mockData.fetchLinkedSensors('uid')).thenAnswer((_) async => [
            {
              'display_name': 'Hive A',
              'linked_at': '2024-03-01T10:00:00.000Z',
              'sensor': {
                'id': 'sensor-uuid',
                'firebase_sensor_id': '10001',
                'display_name': null,
                'created_at': '2024-01-01T00:00:00.000Z',
              },
            },
          ]);

      final links = await repo.getLinkedSensors('uid');
      expect(links, hasLength(1));
      expect(links.first.sensor.firebaseSensorId, '10001');
      expect(links.first.displayName, 'Hive A');
    });

    test('returns empty list when none linked', () async {
      when(() => mockData.fetchLinkedSensors('uid')).thenAnswer((_) async => []);

      final links = await repo.getLinkedSensors('uid');
      expect(links, isEmpty);
    });
  });

  group('unlinkSensor', () {
    test('calls deleteUserSensorLink', () async {
      when(() => mockData.deleteUserSensorLink(userId: 'uid', sensorId: 's-1'))
          .thenAnswer((_) async {});

      await repo.unlinkSensor('uid', 's-1');
      verify(() => mockData.deleteUserSensorLink(userId: 'uid', sensorId: 's-1')).called(1);
    });
  });
}
