import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const tabs = [
    _Tab(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, path: Routes.dashboard),
    _Tab(label: 'Sensors', icon: Icons.sensors_outlined, activeIcon: Icons.sensors, path: Routes.sensors),
    _Tab(label: 'Account', icon: Icons.person_outline, activeIcon: Icons.person, path: Routes.settings),
  ];

  static int indexFromLocation(String location) {
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _goingForward = true;
  Widget? _outgoingChild;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _outgoingChild = null);
        }
      });
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIndex = MainShell.indexFromLocation(oldWidget.location);
    final newIndex = MainShell.indexFromLocation(widget.location);
    if (oldIndex != newIndex) {
      _goingForward = newIndex > oldIndex;
      _outgoingChild = oldWidget.child;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = MainShell.indexFromLocation(widget.location);
    final inOffset = _goingForward ? const Offset(1, 0) : const Offset(-1, 0);
    final outOffset = _goingForward ? const Offset(-1, 0) : const Offset(1, 0);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_outgoingChild != null)
                  SlideTransition(
                    position: Tween(begin: Offset.zero, end: outOffset).animate(curved),
                    child: _outgoingChild!,
                  ),
                SlideTransition(
                  position: _outgoingChild != null
                      ? Tween(begin: inOffset, end: Offset.zero).animate(curved)
                      : AlwaysStoppedAnimation(Offset.zero),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
        NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            if (i != index) context.go(MainShell.tabs[i].path);
          },
          destinations: [
            for (final tab in MainShell.tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
          ],
        ),
      ],
    );
  }
}

class _Tab {
  const _Tab({required this.label, required this.icon, required this.activeIcon, required this.path});
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
