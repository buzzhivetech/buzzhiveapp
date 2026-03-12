import 'package:flutter_test/flutter_test.dart';
import 'package:buzzhive_app/core/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('debug does not throw', () {
      expect(() => AppLogger.debug('test message', name: 'Test'), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => AppLogger.info('test message', name: 'Test'), returnsNormally);
    });

    test('warn does not throw', () {
      expect(() => AppLogger.warn('test warning', name: 'Test'), returnsNormally);
    });

    test('error does not throw', () {
      expect(
        () => AppLogger.error('test error', name: 'Test', error: Exception('oops')),
        returnsNormally,
      );
    });

    test('error with stack trace does not throw', () {
      try {
        throw Exception('stack test');
      } catch (e, st) {
        expect(
          () => AppLogger.error('caught', name: 'Test', error: e, stackTrace: st),
          returnsNormally,
        );
      }
    });
  });
}
