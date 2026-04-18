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

    test('maps PostgrestException to AppException with code', () async {
      when(() => mockData.fetchLinkedSensors('uid'))
          .thenThrow(const supabase.PostgrestException(message: 'RLS', code: '42501'));

      expect(
        () => repo.getLinkedSensors('uid'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', '42501')),
      );
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

  group('renameSensor', () {
    test('calls renameLinkedSensor', () async {
      when(() => mockData.renameLinkedSensor(
            userId: 'uid',
            sensorId: 's-1',
            displayName: 'Back yard',
          )).thenAnswer((_) async {});

      await repo.renameSensor('uid', 's-1', 'Back yard');
      verify(() => mockData.renameLinkedSensor(
            userId: 'uid',
            sensorId: 's-1',
            displayName: 'Back yard',
          )).called(1);
    });
  });
}
