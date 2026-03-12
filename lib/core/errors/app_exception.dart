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
