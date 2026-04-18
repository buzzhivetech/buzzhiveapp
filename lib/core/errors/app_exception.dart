/// Base exception for app layer; repositories map SDK errors to these.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Auth-related errors (invalid credentials, session expired, etc.).
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Network/connectivity errors.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Validation errors (e.g. invalid email format).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Resource not found (e.g. sensor or profile).
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

/// Firebase read errors.
class FirebaseReadException extends AppException {
  const FirebaseReadException(super.message, {super.code});
}

/// Bluetooth transfer errors.
class BleTransferException extends AppException {
  const BleTransferException(super.message, {super.code});
}

/// Sync/upload errors.
class SyncException extends AppException {
  const SyncException(super.message, {super.code});
}

/// Device claim/onboarding errors. The [code] matches the `error_code`
/// returned by the `claim_sensor` Supabase RPC (see [ClaimErrorCode]).
class ClaimException extends AppException {
  const ClaimException(super.message, {super.code});
}

/// Error codes returned by the `claim_sensor` RPC.
/// Keep these strings in sync with supabase/migrations/20250105000001_claim_sensor_rpc.sql.
class ClaimErrorCode {
  ClaimErrorCode._();

  static const String notAuthenticated = 'not_authenticated';
  static const String rateLimited = 'rate_limited';
  static const String unknownDevice = 'unknown_device';
  static const String disabledDevice = 'disabled_device';
  static const String alreadyClaimed = 'already_claimed';
  static const String wrongCode = 'wrong_code';
}
