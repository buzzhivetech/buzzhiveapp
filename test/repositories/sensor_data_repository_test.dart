import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:buzzhive_app/core/errors/app_exception.dart';
import 'package:buzzhive_app/repositories/sensor_data_repository.dart';
import 'package:buzzhive_app/services/firebase/firebase_sensor_data_service.dart';

class MockFirebaseSensorDataService extends Mock implements FirebaseSensorDataService {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseSensorDataService mockFirebase;
  late SensorDataRepositoryImpl repo;

  setUp(() {
    mockFirebase = MockFirebaseSensorDataService();
    repo = SensorDataRepositoryImpl(mockFirebase);
  });

  group('sensorExists', () {
    test('returns true when snapshot exists with map data', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.value).thenReturn({'temp': 25.0, 'hum': 60.0});
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      expect(await repo.sensorExists('10001'), isTrue);
    });

    test('returns false when snapshot does not exist', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(false);
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      expect(await repo.sensorExists('10001'), isFalse);
    });

    test('returns false when value is null', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.value).thenReturn(null);
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      expect(await repo.sensorExists('10001'), isFalse);
    });

    test('returns false when value is empty map', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.value).thenReturn(<dynamic, dynamic>{});
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      expect(await repo.sensorExists('10001'), isFalse);
    });

    test('throws FirebaseReadException on error', () async {
      when(() => mockFirebase.readOnce('bad'))
          .thenThrow(Exception('network error'));

      expect(
        () => repo.sensorExists('bad'),
        throwsA(isA<FirebaseReadException>()),
      );
    });
  });

  group('getReadingsInRange', () {
    test('parses nested structure', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.value).thenReturn({
        '1700000000000': {
          'temp': 25.0, 'hum': 60.0, 'gas': 0, 'mic': 0, 'db': 0,
          'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
          'id': '10001', 'timestamp': 1700000000000,
        },
      });
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      final readings = await repo.getReadingsInRange('10001', 0, 2000000000000);
      expect(readings, hasLength(1));
      expect(readings.first.temp, 25.0);
    });

    test('parses flat structure', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(true);
      when(() => snap.value).thenReturn({
        'temp': 30.0, 'hum': 55.0, 'gas': 10, 'mic': 100, 'db': 40,
        'ax': 0, 'ay': 0, 'az': 0, 'fx': 0, 'fy': 0, 'fz': 0,
        'id': '10001', 'timestamp': 1700000000000,
      });
      when(() => mockFirebase.readOnce('push-key')).thenAnswer((_) async => snap);

      final readings = await repo.getReadingsInRange('push-key', 0, 2000000000000);
      expect(readings, hasLength(1));
      expect(readings.first.temp, 30.0);
    });

    test('returns empty when snapshot does not exist', () async {
      final snap = MockDataSnapshot();
      when(() => snap.exists).thenReturn(false);
      when(() => snap.value).thenReturn(null);
      when(() => mockFirebase.readOnce('10001')).thenAnswer((_) async => snap);

      final readings = await repo.getReadingsInRange('10001', 0, 2000000000000);
      expect(readings, isEmpty);
    });
  });

  group('streamLatestReadings', () {
    test('returns empty map for empty ids', () async {
      final stream = repo.streamLatestReadings([]);
      expect(await stream.first, isEmpty);
    });
  });
}
