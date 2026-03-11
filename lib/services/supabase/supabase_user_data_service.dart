import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase user data only: profiles, sensors, user_sensor_links. No auth, no Firebase.
class SupabaseUserDataService {
  SupabaseUserDataService();

  SupabaseClient get _client => Supabase.instance.client;

  /// List sensors linked to this user (join user_sensor_links + sensors).
  /// Returns list of maps with keys: display_name, linked_at, sensor (map or list).
  Future<List<Map<String, dynamic>>> fetchLinkedSensors(String userId) async {
    final res = await _client
        .from('user_sensor_links')
        .select('display_name, linked_at, sensor:sensors(*)')
        .eq('user_id', userId)
        .order('linked_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Insert or get sensor by firebase_sensor_id. Returns sensor id.
  Future<String> upsertSensor({
    required String firebaseSensorId,
    String? displayName,
  }) async {
    final res = await _client
        .from('sensors')
        .upsert(
          {
            'firebase_sensor_id': firebaseSensorId,
            if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
          },
          onConflict: 'firebase_sensor_id',
        )
        .select('id')
        .maybeSingle();
    if (res == null) throw Exception('Failed to upsert sensor');
    return res['id'] as String;
  }

  /// Add link between user and sensor.
  Future<void> insertUserSensorLink({
    required String userId,
    required String sensorId,
    String? displayName,
  }) async {
    await _client.from('user_sensor_links').insert({
      'user_id': userId,
      'sensor_id': sensorId,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    });
  }

  /// Remove link.
  Future<void> deleteUserSensorLink({
    required String userId,
    required String sensorId,
  }) async {
    await _client.from('user_sensor_links').delete().match({
      'user_id': userId,
      'sensor_id': sensorId,
    });
  }

  /// Check if user already has this sensor linked (by firebase_sensor_id).
  Future<bool> hasLinkForFirebaseSensorId(String userId, String firebaseSensorId) async {
    final sensorRes = await _client
        .from('sensors')
        .select('id')
        .eq('firebase_sensor_id', firebaseSensorId)
        .maybeSingle();
    if (sensorRes == null) return false;
    final sensorId = sensorRes['id'] as String;
    final linkRes = await _client
        .from('user_sensor_links')
        .select('id')
        .eq('user_id', userId)
        .eq('sensor_id', sensorId)
        .maybeSingle();
    return linkRes != null;
  }
}
