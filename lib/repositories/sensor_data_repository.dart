import '../core/errors/app_exception.dart';
import '../models/sensor_reading.dart';

/// Firebase Realtime DB: stream latest readings and fetch range for analytics.
abstract class SensorDataRepository {
  /// Stream of latest reading per firebase_sensor_id (nested path sensor_data/{id}/...).
  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds);

  /// One-off fetch for analytics: readings in [startMs, endMs] for one sensor.
  Future<List<SensorReading>> getReadingsInRange(
    String firebaseSensorId,
    int startMs,
    int endMs,
  );
}

class SensorDataRepositoryImpl implements SensorDataRepository {
  @override
  Stream<Map<String, SensorReading?>> streamLatestReadings(List<String> firebaseSensorIds) {
    throw const FirebaseReadException('Not implemented: configure Firebase');
  }

  @override
  Future<List<SensorReading>> getReadingsInRange(
    String firebaseSensorId,
    int startMs,
    int endMs,
  ) async {
    throw const FirebaseReadException('Not implemented: configure Firebase');
  }
}
