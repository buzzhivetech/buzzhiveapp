import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';

/// Riverpod observer that logs provider errors and disposal.
class AppProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(ProviderBase<Object?> provider, Object error, StackTrace stackTrace, ProviderContainer container) {
    AppLogger.error(
      'Provider ${provider.name ?? provider.runtimeType.toString()} failed',
      name: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void didDisposeProvider(ProviderBase<Object?> provider, ProviderContainer container) {
    AppLogger.debug(
      'Disposed ${provider.name ?? provider.runtimeType.toString()}',
      name: 'Riverpod',
    );
  }
}
