import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../models/sensor.dart';
import '../models/user_sensor_link.dart';
import '../services/supabase/supabase_user_data_service.dart';

/// Supabase: list linked sensors, link/unlink by Firebase sensor ID.
abstract class SensorLinkRepository {
  Future<List<UserSensorLink>> getLinkedSensors(String userId);
  Future<Sensor> linkSensor(String userId, String firebaseSensorId, {String? displayName});
  Future<void> unlinkSensor(String userId, String sensorId);
  Future<void> renameSensor(String userId, String sensorId, String displayName);
}

class SensorLinkRepositoryImpl implements SensorLinkRepository {
  SensorLinkRepositoryImpl(this._userData);

  final SupabaseUserDataService _userData;
  static const _log = 'SensorLink';

  @override
  Future<List<UserSensorLink>> getLinkedSensors(String userId) async {
    try {
      final rows = await _userData.fetchLinkedSensors(userId);
      AppLogger.debug('getLinkedSensors($userId): ${rows.length} links', name: _log);
      return rows.map(_rowToUserSensorLink).toList();
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('getLinkedSensors failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('getLinkedSensors unexpected error', name: _log, error: e, stackTrace: st);
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
      AppLogger.info('Linking sensor $firebaseSensorId for user $userId', name: _log);
      final sensorId = await _userData.upsertSensor(
        firebaseSensorId: firebaseSensorId,
        displayName: displayName,
      );
      await _userData.insertUserSensorLink(
        userId: userId,
        sensorId: sensorId,
        displayName: displayName,
      );
      AppLogger.info('Sensor $firebaseSensorId linked (sensorId: $sensorId)', name: _log);
      return Sensor(
        id: sensorId,
        firebaseSensorId: firebaseSensorId,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
    } on supabase.PostgrestException catch (e, st) {
      if (e.code == '23505') {
        AppLogger.warn('Sensor $firebaseSensorId already linked for $userId', name: _log);
        throw const ValidationException(
          'This sensor is already linked to your account.',
        );
      }
      AppLogger.error('linkSensor failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('linkSensor unexpected error', name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> unlinkSensor(String userId, String sensorId) async {
    try {
      await _userData.deleteUserSensorLink(userId: userId, sensorId: sensorId);
      AppLogger.info('Sensor $sensorId unlinked for user $userId', name: _log);
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('unlinkSensor failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('unlinkSensor unexpected error', name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> renameSensor(String userId, String sensorId, String displayName) async {
    try {
      await _userData.renameLinkedSensor(
        userId: userId,
        sensorId: sensorId,
        displayName: displayName,
      );
      AppLogger.info('Sensor $sensorId renamed to "$displayName"', name: _log);
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('renameSensor failed: ${e.message}', name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('renameSensor unexpected error', name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }
}
