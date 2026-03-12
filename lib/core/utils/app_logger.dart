import 'dart:developer' as dev;

/// Structured logger using dart:developer. Suppressed in production builds.
/// Use named loggers per module: AppLogger.info('Init done', name: 'Firebase').
class AppLogger {
  AppLogger._();

  static const int _levelDebug = 0;
  static const int _levelInfo = 500;
  static const int _levelWarning = 900;
  static const int _levelError = 1000;

  static const bool _isReleaseBuild = bool.fromEnvironment('dart.vm.product', defaultValue: false);

  static void debug(String message, {String name = 'App', Object? error, StackTrace? stackTrace}) {
    _log(message, level: _levelDebug, name: name, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String name = 'App', Object? error, StackTrace? stackTrace}) {
    _log(message, level: _levelInfo, name: name, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {String name = 'App', Object? error, StackTrace? stackTrace}) {
    _log(message, level: _levelWarning, name: name, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String name = 'App', Object? error, StackTrace? stackTrace}) {
    _log(message, level: _levelError, name: name, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String message, {
    required int level,
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_isReleaseBuild && level < _levelWarning) return;
    dev.log(message, level: level, name: name, error: error, stackTrace: stackTrace);
  }
}
