import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_display.dart';
import 'loading_indicator.dart';

/// Generic widget that maps a Riverpod [AsyncValue] to loading / error / data states.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.loadingMessage,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => LoadingIndicator(message: loadingMessage),
      error: (err, _) => ErrorDisplay(error: err, onRetry: onRetry),
      data: data,
    );
  }
}
