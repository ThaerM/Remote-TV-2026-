import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/features/devices/application/paired_android_tv_controller.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/features/onboarding/application/onboarding_state.dart';
import 'package:remote_tv_2026/features/onboarding/presentation/welcome_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tv/stub_tv_provider.dart';

const _tv = TvDevice(
  id: 'android_tv:family-room',
  name: 'Family room TV',
  platform: TvPlatform.androidTv,
  host: '192.168.1.42',
);

/// A router covering only the routes this flow exercises, mirroring
/// AppRoutes/app_router's shape so navigation calls in the real widgets
/// resolve the same way.
GoRouter _appRouter({
  required bool onboarded,
  required StubTvProvider provider,
}) {
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
        path: AppRoutes.remote,
        builder: (context, state) => const RemoteScreen(),
      ),
    ],
  );
}

Future<void> _pumpApp(
  WidgetTester tester,
  ProviderContainer container, {
  required bool onboarded,
  required StubTvProvider provider,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: _appRouter(onboarded: onboarded, provider: provider),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer containerWith(StubTvProvider provider) => ProviderContainer(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([provider]),
      ),
      pairedAndroidTvDevicesProvider.overrideWith((ref) async => const []),
    ],
  );

  testWidgets('Welcome shows both Find my TV and Explore app first', (
    tester,
  ) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: false, provider: provider);

    expect(find.text('Find my TV'), findsOneWidget);
    expect(find.text('Explore app first'), findsOneWidget);
  });

  testWidgets('tapping Find my TV goes to Discovery', (tester) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: false, provider: provider);
    await tester.ensureVisible(find.text('Find my TV'));
    await tester.tap(find.text('Find my TV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DiscoveryScreen), findsOneWidget);
  });

  testWidgets('tapping Explore app first goes straight to the main app shell '
      'without discovering or pairing', (tester) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: false, provider: provider);
    await tester.ensureVisible(find.text('Explore app first'));
    await tester.tap(find.text('Explore app first'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RemoteScreen), findsOneWidget);
    expect(find.byType(DiscoveryScreen), findsNothing);
    expect(provider.connectCalls, 0, reason: 'no auto pairing/reconnect');
  });

  testWidgets('the main app with no TV shows a clean, non-blocking state', (
    tester,
  ) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: true, provider: provider);

    expect(find.text('No TV connected'), findsOneWidget);
    expect(
      find.text("Connect a compatible TV when you're ready."),
      findsOneWidget,
    );
    expect(find.text('Connect TV'), findsOneWidget);
    expect(
      find.text('You can explore the app before connecting a device.'),
      findsOneWidget,
    );
  });

  testWidgets('the Connect TV CTA goes to Discovery', (tester) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: true, provider: provider);
    await tester.tap(find.text('Connect TV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DiscoveryScreen), findsOneWidget);
  });

  testWidgets('Back from a manually-opened Discovery returns to the app, '
      'not Welcome', (tester) async {
    final provider = StubTvProvider(platform: TvPlatform.androidTv);
    final container = containerWith(provider);
    addTearDown(container.dispose);

    await _pumpApp(tester, container, onboarded: true, provider: provider);
    await tester.tap(find.text('Connect TV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DiscoveryScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RemoteScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets(
    'reopening the app after onboarding goes straight to the main shell, '
    'not forced into Discovery',
    (tester) async {
      final provider = StubTvProvider(platform: TvPlatform.androidTv);
      final container = containerWith(provider);
      addTearDown(container.dispose);

      await _pumpApp(tester, container, onboarded: true, provider: provider);

      expect(find.byType(RemoteScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(DiscoveryScreen), findsNothing);
    },
  );

  test('OnboardingStore persists completion across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final first = OnboardingStore();
    expect(await first.isCompleted(), isFalse);

    await first.markCompleted();

    final second = OnboardingStore();
    expect(await second.isCompleted(), isTrue);
  });

  testWidgets(
    'skipping onboarding does not delete a previously paired device or '
    'its stored credentials',
    (tester) async {
      final secureStore = InMemoryCredentialStore();
      final deviceStore = AndroidTvPairedDeviceStore(secureStore: secureStore);
      final identity = AndroidTvIdentity.generate();
      await deviceStore.saveIdentity(_tv.id, identity);
      await deviceStore.saveMetadata(
        PairedAndroidTvMetadata(
          deviceId: _tv.id,
          name: _tv.name,
          lastKnownHost: _tv.host!,
          lastConnectedAt: DateTime.now(),
        ),
      );

      final provider = StubTvProvider(platform: TvPlatform.androidTv);
      final container = ProviderContainer(
        overrides: [
          tvProviderRegistryProvider.overrideWithValue(
            TvProviderRegistry([provider]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpApp(tester, container, onboarded: false, provider: provider);
      await tester.ensureVisible(find.text('Explore app first'));
      await tester.ensureVisible(find.text('Explore app first'));
      await tester.tap(find.text('Explore app first'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(await deviceStore.loadIdentity(_tv.id), isNotNull);
      expect(await deviceStore.loadAll(), hasLength(1));
    },
  );
}
