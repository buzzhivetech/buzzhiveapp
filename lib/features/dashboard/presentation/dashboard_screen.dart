import 'package:flutter/material.dart';

/// Main dashboard: KPIs, env, audio, motion, system info (dashboard parity).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard – replicate web KPIs and cards')),
    );
  }
}
