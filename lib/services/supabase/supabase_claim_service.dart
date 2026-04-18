import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over the `claim_sensor` Supabase RPC.
///
/// Business logic and error mapping live in [DeviceClaimRepository];
/// this service just forwards the call and returns the raw result row.
class SupabaseClaimService {
  SupabaseClaimService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Call the `claim_sensor(p_device_id, p_claim_code)` RPC.
  ///
  /// Returns the composite row as a [Map] with keys `ok`, `error_code`,
  /// `sensor_id`. PostgREST serializes composite return types as a JSON
  /// object, so we get a map back directly (no array wrapper).
  Future<Map<String, dynamic>> claimSensor({
    required String deviceId,
    required String claimCode,
  }) async {
    final res = await _client.rpc(
      'claim_sensor',
      params: {
        'p_device_id': deviceId,
        'p_claim_code': claimCode,
      },
    );
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    // Some older PostgREST versions wrap composite returns in a single-row list.
    if (res is List && res.isNotEmpty && res.first is Map) {
      return Map<String, dynamic>.from(res.first as Map);
    }
    throw StateError('Unexpected claim_sensor response shape: $res');
  }
}
