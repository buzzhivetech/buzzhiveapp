import '../core/errors/app_exception.dart';
import '../models/sensor.dart';
import '../models/user_sensor_link.dart';

/// Supabase: list linked sensors, link/unlink by Firebase sensor ID.
abstract class SensorLinkRepository {
  Future<List<UserSensorLink>> getLinkedSensors(String userId);
  Future<Sensor> linkSensor(String userId, String firebaseSensorId, {String? displayName});
  Future<void> unlinkSensor(String userId, String sensorId);
}

class SensorLinkRepositoryImpl implements SensorLinkRepository {
  @override
  Future<List<UserSensorLink>> getLinkedSensors(String userId) async {
    throw const AppException('Not implemented: configure Supabase');
  }

  @override
  Future<Sensor> linkSensor(String userId, String firebaseSensorId, {String? displayName}) async {
    throw const AppException('Not implemented: configure Supabase');
  }

  @override
  Future<void> unlinkSensor(String userId, String sensorId) async {
    throw const AppException('Not implemented: configure Supabase');
  }
}
