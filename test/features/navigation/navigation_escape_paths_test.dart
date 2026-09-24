import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/app/shell/app_shell.dart';
import 'package:remote_tv_2026/features/about/presentation/about_screen.dart';
import 'package:remote_tv_2026/features/apps/presentation/apps_screen.dart';
import 'package:remote_tv_2026/features/devices/application/paired_android_tv_controller.dart';
import 'package:remote_tv_2026/features/devices/presentation/devices_screen.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/features/onboarding/presentation/welcome_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/connected_success_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/features/settings/application/settings_controller.dart';
import 'package:remote_tv_2026/features/settings/presentation/remote_layout_settings_screen.dart';
import 'package:remote_tv_2026/features/settings/presentation/settings_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../../tv/stub_tv_provider.dart';

/// Every route the real router serves, minus the ones this suite doesn't
/// exercise (diagnostics, remote-behavior settings) - kept intentionally
/// close to `appRouterProvider`'s own shape (a plain-route set plus one
/// [ShellRoute] for the four tab roots) so a Back/Cancel behaviour proven
/// here holds for the real app, not just a simplified stand-in.
GoRouter _appLikeRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
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
            builder: (context, state) =>
                const Scaffold(body: Text('Cast root')),
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
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
}

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }
}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController(SettingsState initial) {
    state = initial;
  }
}

Widget _wrap(
  GoRouter router, {
  TvSessionState session = const TvSessionState(),
  StubTvProvider? provider,
}) {
  return ProviderScope(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([
          provider ?? StubTvProvider(platform: TvPlatform.androidTv),
        ]),
      ),
      tvSessionControllerProvider.overrideWith(
        (ref) => _FakeSessionController(ref, session),
      ),
      settingsControllerProvider.overrideWith(
        (ref) => _FakeSettingsController(const SettingsState()),
      ),
      pairedAndroidTvDevicesProvider.overrideWith((ref) async => const []),
      appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// A handful of screens carry a deliberately-repeating animation (the
/// Discovery radar, Welcome's glow, the connected Remote header's
/// connection pulse) - never `pumpAndSettle` across them, matching every
/// other test in this repo that touches those screens. This settles a
/// bounded transition/async gap instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  // Long enough for a full push/pop page-transition animation to finish
  // and the departing route to actually dispose - a shorter pump leaves
  // both the old and new screen mounted mid-transition.
  await tester.pump(const Duration(milliseconds: 1000));
}

void main() {
  group('Root shell and Welcome', () {
    testWidgets(
      '1. the main shell never exposes Welcome on Back after onboarding',
      (tester) async {
        final router = _appLikeRouter(initialLocation: AppRoutes.welcome);
        await tester.pumpWidget(_wrap(router));
        await tester.pump();

        await tester.ensureVisible(find.text('Explore app first'));
        await tester.tap(find.text('Explore app first'));
        await _settle(tester);

        expect(find.byType(WelcomeScreen), findsNothing);
        expect(find.byType(AppShell), findsOneWidget);
        final shellContext = tester.element(find.byType(AppShell));
        expect(
          Navigator.of(shellContext).canPop(),
          isFalse,
          reason: 'nothing to pop back into Welcome with',
        );
      },
    );

    testWidgets('15. root/tab screens do not show a redundant Back button when '
        'they are the only route on screen', (tester) async {
      for (final route in [
        AppRoutes.remote,
        AppRoutes.devices,
        AppRoutes.settings,
      ]) {
        final router = _appLikeRouter(initialLocation: route);
        await tester.pumpWidget(_wrap(router));
        await tester.pump();

        expect(
          find.byType(BackButton),
          findsNothing,
          reason: '$route is a root/tab destination',
        );
      }
    });
  });

  group('Discovery caller-aware Back', () {
    testWidgets('2. opened from Remote, Back returns to Remote', (
      tester,
    ) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.remote);
      await tester.pumpWidget(_wrap(router));
      await tester.pump();

      expect(find.text('Connect TV'), findsOneWidget);
      await tester.tap(find.text('Connect TV'));
      await _settle(tester);

      expect(find.byType(DiscoveryScreen), findsOneWidget);

      await tester.pageBack();
      await _settle(tester);

      expect(find.byType(DiscoveryScreen), findsNothing);
      expect(find.text('Connect TV'), findsOneWidget);
    });

    testWidgets('3. opened from Devices, Back returns to Devices', (
      tester,
    ) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.devices);
      await tester.pumpWidget(_wrap(router));
      await tester.pump();

      expect(find.text('Find a TV'), findsOneWidget);
      await tester.tap(find.text('Find a TV'));
      await _settle(tester);

      expect(find.byType(DiscoveryScreen), findsOneWidget);

      await tester.pageBack();
      await _settle(tester);

      expect(find.byType(DiscoveryScreen), findsNothing);
      expect(find.byType(DevicesScreen), findsOneWidget);
    });

    testWidgets(
      '4. opened from Welcome (nothing to pop), Back leads into the app '
      'and never reveals Welcome',
      (tester) async {
        final router = _appLikeRouter(initialLocation: AppRoutes.welcome);
        await tester.pumpWidget(_wrap(router));
        await tester.pump();

        await tester.tap(find.text('Find my TV'));
        await _settle(tester);

        expect(find.byType(DiscoveryScreen), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);

        await tester.pageBack();
        await _settle(tester);

        expect(find.byType(WelcomeScreen), findsNothing);
        expect(find.byType(AppShell), findsOneWidget);
      },
    );
  });

  group('Connected Success', () {
    GoRouter successRouter() => GoRouter(
      initialLocation: AppRoutes.connectedSuccess,
      routes: [
        GoRoute(
          path: AppRoutes.connectedSuccess,
          builder: (context, state) => const ConnectedSuccessScreen(),
        ),
        GoRoute(
          path: AppRoutes.remote,
          builder: (context, state) =>
              const Scaffold(body: Text('Remote root')),
        ),
      ],
    );

    const connectedState = TvSessionState(
      selectedDevice: TvDevice(
        id: 'd1',
        name: 'Family room TV',
        platform: TvPlatform.fake,
      ),
      connectionState: TvConnectionState.connected,
    );

    testWidgets('8. Open Remote works', (tester) async {
      await tester.pumpWidget(_wrap(successRouter(), session: connectedState));
      await tester.pump();

      await tester.tap(find.text('Go to Remote'));
      await _settle(tester);

      expect(find.text('Remote root'), findsOneWidget);
      expect(find.byType(ConnectedSuccessScreen), findsNothing);
    });

    testWidgets(
      '9. Back does not exit or return to a pairing loop - it lands on '
      'Remote',
      (tester) async {
        await tester.pumpWidget(
          _wrap(successRouter(), session: connectedState),
        );
        await tester.pump();

        final context = tester.element(find.byType(ConnectedSuccessScreen));
        await Navigator.of(context).maybePop();
        await _settle(tester);

        // PopScope(canPop: false) intercepted the attempt and redirected
        // via go(AppRoutes.remote) itself, instead of leaving nothing to
        // pop into (which would exit the app) or somehow reopening
        // Pairing (which isn't even in this stack).
        expect(find.text('Remote root'), findsOneWidget);
        expect(find.byType(ConnectedSuccessScreen), findsNothing);
        expect(find.byType(PairingScreen), findsNothing);
      },
    );
  });

  group('Apps', () {
    testWidgets('10. Back returns to Remote', (tester) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.remote);
      const connectedWithApps = TvSessionState(
        selectedDevice: TvDevice(
          id: 'd1',
          name: 'Family room TV',
          platform: TvPlatform.fake,
        ),
        connectionState: TvConnectionState.connected,
        capabilities: TvCapabilities(launchApps: true),
        applications: [TvApplication(id: 'netflix', name: 'Netflix')],
      );
      await tester.pumpWidget(_wrap(router, session: connectedWithApps));
      await tester.pump();

      await tester.tap(find.text('See all'));
      await _settle(tester);

      expect(find.byType(AppsScreen), findsOneWidget);

      await tester.pageBack();
      await _settle(tester);

      expect(find.byType(AppsScreen), findsNothing);
      expect(find.text('Netflix'), findsOneWidget); // the quick-apps row
    });
  });

  group('Settings and About', () {
    testWidgets('11. a Settings child screen returns to Settings on Back', (
      tester,
    ) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.settings);
      await tester.pumpWidget(_wrap(router));
      await tester.pump();

      await tester.tap(find.text('Remote layout'));
      await _settle(tester);

      expect(find.byType(RemoteLayoutSettingsScreen), findsOneWidget);

      await tester.pageBack();
      await _settle(tester);

      expect(find.byType(RemoteLayoutSettingsScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('12. About returns to Settings on Back', (tester) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.settings);
      await tester.pumpWidget(_wrap(router));
      await tester.pump();

      await tester.scrollUntilVisible(find.text('About'), 200);
      await tester.tap(find.text('About'));
      await _settle(tester);

      expect(find.byType(AboutScreen), findsOneWidget);

      await tester.pageBack();
      await _settle(tester);

      expect(find.byType(AboutScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Sheets', () {
    testWidgets('13. Add TV by IP address sheet can be dismissed', (
      tester,
    ) async {
      final router = _appLikeRouter(initialLocation: AppRoutes.discovery);
      await tester.pumpWidget(_wrap(router));
      await _settle(tester);

      await tester.tap(find.text('Add TV by IP address'));
      await _settle(tester);

      expect(find.text('Add TV by IP address'), findsWidgets);

      // Tapping the scrim outside the sheet dismisses it, same as the
      // system back gesture/button would.
      await tester.tapAt(const Offset(20, 20));
      await _settle(tester);

      expect(find.text('IP address'), findsNothing);
    });
  });

  group('No duplicate navigation', () {
    testWidgets(
      '14. firing connect twice before the first result lands does not '
      'crash or double-navigate',
      (tester) async {
        final provider = StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: const TvDiscoveryOutcome(
            devices: [
              TvDevice(
                id: 'android_tv:one',
                name: 'Family room TV',
                platform: TvPlatform.androidTv,
                host: '192.168.1.42',
              ),
            ],
          ),
        );
        final router = GoRouter(
          initialLocation: AppRoutes.discovery,
          routes: [
            GoRoute(
              path: AppRoutes.discovery,
              builder: (context, state) => const DiscoveryScreen(),
            ),
            GoRoute(
              path: AppRoutes.connectedSuccess,
              builder: (context, state) =>
                  const Scaffold(body: Text('Connected!')),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tvProviderRegistryProvider.overrideWithValue(
                TvProviderRegistry([provider]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await _settle(tester);

        // No pump between the two taps: both onTap handlers fire before
        // either `connect()` future resolves, exactly the race a slow
        // network reply could cause on a real device.
        await tester.tap(find.text('Family room TV'));
        await tester.tap(find.text('Family room TV'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('Connected!'), findsOneWidget);
      },
    );
  });
}
