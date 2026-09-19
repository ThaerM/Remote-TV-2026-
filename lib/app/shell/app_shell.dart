import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';

/// Bottom-tab shell for the four primary destinations: Remote, Cast,
/// Devices, Settings. See docs/product/screen-inventory.md.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _destinations = [
    (
      route: AppRoutes.remote,
      icon: Icons.settings_remote_rounded,
      label: 'Remote',
    ),
    (route: AppRoutes.cast, icon: Icons.cast_rounded, label: 'Cast'),
    (route: AppRoutes.devices, icon: Icons.tv_rounded, label: 'Devices'),
    (
      route: AppRoutes.settings,
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  int _indexForLocation(String location) {
    final index = _destinations.indexWhere((d) => location.startsWith(d.route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_destinations[index].route);
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
