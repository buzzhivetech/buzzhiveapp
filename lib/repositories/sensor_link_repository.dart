import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../models/sensor.dart';
import '../models/user_sensor_link.dart';
import '../services/supabase/supabase_user_data_service.dart';

/// Supabase: list linked sensors, link/unlink by Firebase sensor ID.
abstract class SensorLinkRepository {
  Future<List<UserSensorLink>> getLinkedSensors(String userId);
  Future<Sensor> linkSensor(String userId, String firebaseSensorId, {String? displayName});
  Future<void> unlinkSensor(String userId, String sensorId);
}

class SensorLinkRepositoryImpl implements SensorLinkRepository {
  SensorLinkRepositoryImpl(this._userData);

  final SupabaseUserDataService _userData;

  @override
  Future<List<UserSensorLink>> getLinkedSensors(String userId) async {
    try {
      final rows = await _userData.fetchLinkedSensors(userId);
      return rows.map(_rowToUserSensorLink).toList();
    } on supabase.PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } on Object catch (e) {
      throw AppException(e.toString());
    }
  }

  UserSensorLink _rowToUserSensorLink(Map<String, dynamic> row) {
    final sensorData = row['sensor'];
    final sensorMap = sensorData is List
        ? (sensorData.isNotEmpty ? sensorData.first as Map<String, dynamic> : <String, dynamic>{})
        : sensorData as Map<String, dynamic>? ?? {};
    final sensor = Sensor.fromMap(Map<String, dynamic>.from(sensorMap));
    return UserSensorLink(
      sensor: sensor,
      displayName: row['display_name'] as String?,
      linkedAt: DateTime.parse(row['linked_at'] as String),
    );
  }

  @override
  Future<Sensor> linkSensor(String userId, String firebaseSensorId, {String? displayName}) async {
    try {
      final sensorId = await _userData.upsertSensor(
        firebaseSensorId: firebaseSensorId,
        displayName: displayName,
      );
      await _userData.insertUserSensorLink(
        userId: userId,
        sensorId: sensorId,
        displayName: displayName,
      );
      return Sensor(
        id: sensorId,
        firebaseSensorId: firebaseSensorId,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
    } on supabase.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
        'This sensor is already linked to your account.',
      );
      }
      throw AppException(e.message, code: e.code);
    } on Object catch (e) {
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> unlinkSensor(String userId, String sensorId) async {
    try {
      await _userData.deleteUserSensorLink(userId: userId, sensorId: sensorId);
    } on supabase.PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } on Object catch (e) {
      throw AppException(e.toString());
    }
  }
}
