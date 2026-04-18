import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../services/supabase/supabase_claim_service.dart';

/// Result of a successful sensor claim: the server-assigned sensor UUID
/// that can be used to look up the linked sensor in Supabase.
class ClaimedSensor {
  const ClaimedSensor({required this.sensorId, required this.deviceId});

  final String sensorId;
  final String deviceId;
}

/// Repository for the customer-facing "claim this device" flow.
///
/// Wraps [SupabaseClaimService] with error mapping from the RPC's typed
/// `error_code` result to [ClaimException] subtypes.
abstract class DeviceClaimRepository {
  /// Attempt to claim [deviceId] using the [claimCode] printed on the
  /// device sticker. Throws [ClaimException] on any non-ok result.
  Future<ClaimedSensor> claim({
    required String deviceId,
    required String claimCode,
  });
}

class DeviceClaimRepositoryImpl implements DeviceClaimRepository {
  DeviceClaimRepositoryImpl(this._service);

  final SupabaseClaimService _service;
  static const _log = 'DeviceClaim';

  @override
  Future<ClaimedSensor> claim({
    required String deviceId,
    required String claimCode,
  }) async {
    final trimmedId = deviceId.trim();
    final trimmedCode = claimCode.trim().toUpperCase();

    if (trimmedId.isEmpty) {
      throw const ValidationException('Enter a device ID.');
    }
    if (trimmedCode.isEmpty) {
      throw const ValidationException('Enter the claim code from the sticker.');
    }

    AppLogger.info('Claiming device $trimmedId', name: _log);

    try {
      final row = await _service.claimSensor(
        deviceId: trimmedId,
        claimCode: trimmedCode,
      );

      final ok = row['ok'] == true;
      final errorCode = row['error_code'] as String?;
      final sensorId = row['sensor_id'] as String?;

      if (ok && sensorId != null) {
        AppLogger.info('Device $trimmedId claimed (sensor_id=$sensorId)', name: _log);
        return ClaimedSensor(sensorId: sensorId, deviceId: trimmedId);
      }

      AppLogger.warn('Claim rejected for $trimmedId: $errorCode', name: _log);
      throw _mapErrorCode(errorCode);
    } on ClaimException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on supabase.PostgrestException catch (e, st) {
      AppLogger.error('claim_sensor RPC failed: ${e.message}',
          name: _log, error: e, stackTrace: st);
      throw AppException(e.message, code: e.code);
    } on Object catch (e, st) {
      AppLogger.error('claim_sensor unexpected error',
          name: _log, error: e, stackTrace: st);
      throw AppException(e.toString());
    }
  }

  ClaimException _mapErrorCode(String? code) {
    switch (code) {
      case ClaimErrorCode.notAuthenticated:
        return const ClaimException(
          'You must be signed in to claim a sensor.',
          code: ClaimErrorCode.notAuthenticated,
        );
      case ClaimErrorCode.rateLimited:
        return const ClaimException(
          'Too many attempts. Wait 10 minutes and try again.',
          code: ClaimErrorCode.rateLimited,
        );
      case ClaimErrorCode.unknownDevice:
        return const ClaimException(
          'Device not recognized. Check the ID on the sticker.',
          code: ClaimErrorCode.unknownDevice,
        );
      case ClaimErrorCode.disabledDevice:
        return const ClaimException(
          'This device has been disabled. Contact support.',
          code: ClaimErrorCode.disabledDevice,
        );
      case ClaimErrorCode.alreadyClaimed:
        return const ClaimException(
          'This device is already registered to another account.',
          code: ClaimErrorCode.alreadyClaimed,
        );
      case ClaimErrorCode.wrongCode:
        return const ClaimException(
          'Claim code does not match. Check the sticker and try again.',
          code: ClaimErrorCode.wrongCode,
        );
      default:
        return ClaimException(
          'Could not claim device (code: ${code ?? 'unknown'}).',
          code: code,
        );
    }
  }
}
