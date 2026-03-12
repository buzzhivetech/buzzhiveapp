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

GoRouter createAppRouter({
  required String initialLocation,
  required bool isAuthenticated,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (BuildContext context, GoRouterState state) {
      final onAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register;
      if (!Env.hasSupabaseConfig) return null;
      if (isAuthenticated && onAuthRoute) return Routes.dashboard;
      if (!isAuthenticated && !onAuthRoute) return Routes.login;
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
          final extra = state.extra as Map<String, String>? ?? {};
          return BleDownloadScreen(
            sensorId: extra['sensorId'] ?? '',
            firebaseSensorId: extra['firebaseSensorId'] ?? '',
            sensorName: extra['sensorName'] ?? 'Sensor',
          );
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
