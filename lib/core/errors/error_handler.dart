import '../utils/app_logger.dart';
import 'app_exception.dart';
import 'failure.dart';

/// Maps errors to user-facing [Failure] objects and logs them.
class ErrorHandler {
  ErrorHandler._();

  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is AuthException) {
      AppLogger.error('Auth: ${error.message}', name: 'ErrorHandler', error: error, stackTrace: stackTrace);
      return Failure(error.message, code: error.code);
    }

    if (error is ValidationException) {
      return Failure(error.message, code: error.code);
    }

    if (error is NotFoundException) {
      return Failure(error.message, code: error.code, recoverable: false);
    }

    if (error is NetworkException) {
      AppLogger.warn('Network: ${error.message}', name: 'ErrorHandler', error: error, stackTrace: stackTrace);
      return Failure('Connection problem. Check your internet and try again.', code: error.code);
    }

    if (error is FirebaseReadException) {
      AppLogger.error('Firebase read: ${error.message}', name: 'ErrorHandler', error: error, stackTrace: stackTrace);
      return Failure('Could not load sensor data. Try again.', code: error.code);
    }

    if (error is AppException) {
      AppLogger.error('App: ${error.message}', name: 'ErrorHandler', error: error, stackTrace: stackTrace);
      return Failure(error.message, code: error.code);
    }

    AppLogger.error('Unhandled: $error', name: 'ErrorHandler', error: error, stackTrace: stackTrace);
    return const Failure('Something went wrong. Please try again.');
  }

  /// User-friendly message from any error.
  static String userMessage(Object error) => handle(error).message;
}
