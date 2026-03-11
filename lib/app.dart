import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

class BuzzHiveApp extends ConsumerWidget {
  const BuzzHiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.valueOrNull ?? false;
    final router = createAppRouter(
      initialLocation: isAuthenticated ? '/dashboard' : '/login',
      isAuthenticated: isAuthenticated,
    );

    return MaterialApp.router(
      title: 'BuzzHive',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
