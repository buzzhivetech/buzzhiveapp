import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

/// Root app widget.
///
/// The [GoRouter] is created exactly once per app lifetime. Auth state is
/// pushed into the router through a [ValueNotifier] so the redirect always
/// sees fresh state and the router re-runs redirects on changes via its
/// `refreshListenable`. Re-creating the router on every rebuild causes
/// `GlobalObjectKey` collisions in go_router's internal shell state.
class BuzzHiveApp extends ConsumerStatefulWidget {
  const BuzzHiveApp({super.key});

  @override
  ConsumerState<BuzzHiveApp> createState() => _BuzzHiveAppState();
}

class _BuzzHiveAppState extends ConsumerState<BuzzHiveApp> {
  final ValueNotifier<bool> _authListenable = ValueNotifier<bool>(false);
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(
      initialLocation: Routes.login,
      isAuthenticated: _authListenable,
    );
  }

  @override
  void dispose() {
    _authListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
      final isAuth = next.valueOrNull ?? false;
      if (_authListenable.value != isAuth) {
        _authListenable.value = isAuth;
      }
    });

    return MaterialApp.router(
      title: 'BuzzHive',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
