import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bluetooth/presentation/ble_download_screen.dart';
import '../../features/bluetooth/presentation/sync_status_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/map/presentation/hive_map_screen.dart';
import '../../features/sensors/presentation/add_sensor_screen.dart';
import '../../features/sensors/presentation/my_sensors_screen.dart';
import '../../features/settings/presentation/account_screen.dart';
import '../config/env.dart';
import 'main_shell.dart';
import 'routes.dart';

/// Typed payload for the BLE download route. Using a record (vs a
/// `Map<String, String>`) keeps navigation callers honest and makes
/// refactors compile-time safe.
typedef BleDownloadArgs = ({
  String sensorId,
  String firebaseSensorId,
  String sensorName,
  String advertisedName,
});

/// Creates the app's router ONCE for the lifetime of the app.
///
/// Auth state is passed via [isAuthenticated], a [ValueListenable] so that:
///  1. The redirect reads the latest value every time it runs.
///  2. The router re-evaluates redirects when the value changes
///     (via [GoRouter.refreshListenable]).
///
/// Creating the router on every widget rebuild is unsafe — go_router's
/// internal shell state uses `GlobalObjectKey`s keyed by int indices,
/// which collide by value across router instances and cause
/// "Multiple widgets used the same GlobalKey" during reconciliation.
GoRouter createAppRouter({
  required String initialLocation,
  required ValueListenable<bool> isAuthenticated,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: isAuthenticated,
    redirect: (BuildContext context, GoRouterState state) {
      final onAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register;
      if (!Env.hasSupabaseConfig) return null;
      final authed = isAuthenticated.value;
      if (authed && onAuthRoute) return Routes.dashboard;
      if (!authed && !onAuthRoute) return Routes.login;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.home,
        redirect: (_, __) => Routes.dashboard,
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (_, GoRouterState state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.sensors,
            builder: (_, __) => const MySensorsScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            builder: (_, __) => const AccountScreen(),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: Routes.addSensor,
        builder: (_, __) => const AddSensorScreen(),
      ),
      GoRoute(
        path: '${Routes.sensors}/:id',
        builder: (_, GoRouterState state) => _PlaceholderScreen(
          title: 'Sensor ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: Routes.analytics,
        builder: (_, __) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: Routes.map,
        builder: (_, __) => const HiveMapScreen(),
      ),
      GoRoute(
        path: Routes.alerts,
        builder: (_, __) => const AlertsScreen(),
      ),
      GoRoute(
        path: Routes.profileEdit,
        builder: (_, __) => const _PlaceholderScreen(title: 'Edit Profile'),
      ),
      GoRoute(
        path: Routes.bleDownload,
        builder: (_, GoRouterState state) {
          final args = state.extra as BleDownloadArgs?;
          return BleDownloadScreen(args: args);
        },
      ),
      GoRoute(
        path: Routes.syncStatus,
        builder: (_, __) => const SyncStatusScreen(),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
