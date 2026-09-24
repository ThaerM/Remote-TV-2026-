import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/apps/presentation/apps_screen.dart';
import '../../features/casting/presentation/cast_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/onboarding/application/onboarding_state.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/pairing/presentation/connected_success_screen.dart';
import '../../features/pairing/presentation/pairing_screen.dart';
import '../../features/remote/presentation/remote_screen.dart';
import '../../features/settings/presentation/remote_behavior_settings_screen.dart';
import '../../features/settings/presentation/remote_layout_settings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/diagnostics/presentation/diagnostics_screen.dart';
import '../shell/app_shell.dart';

abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const discovery = '/discovery';
  static const pairing = '/pairing';
  static const connectedSuccess = '/pairing/connected';
  static const remote = '/remote';
  static const cast = '/cast';
  static const devices = '/devices';
  static const settings = '/settings';
  static const apps = '/apps';
  static const remoteLayoutSettings = '/settings/remote-layout';
  static const remoteBehaviorSettings = '/settings/remote-behavior';
  static const diagnostics = '/settings/diagnostics';
  static const about = '/settings/about';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // After the first run the app opens straight into the main shell; a TV
  // is never required to get in.
  final onboarded = ref.read(onboardingCompletedAtLaunchProvider);
  return GoRouter(
    initialLocation: onboarded ? AppRoutes.remote : AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.discovery,
        builder: (context, state) => const DiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.pairing,
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectedSuccess,
        builder: (context, state) => const ConnectedSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.apps,
        builder: (context, state) => const AppsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.remote,
            builder: (context, state) => const RemoteScreen(),
          ),
          GoRoute(
            path: AppRoutes.cast,
            builder: (context, state) => const CastScreen(),
          ),
          GoRoute(
            path: AppRoutes.devices,
            builder: (context, state) => const DevicesScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.remoteLayoutSettings,
        builder: (context, state) => const RemoteLayoutSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.remoteBehaviorSettings,
        builder: (context, state) => const RemoteBehaviorSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostics,
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
