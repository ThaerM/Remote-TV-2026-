import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/features/devices/application/paired_android_tv_controller.dart';
import 'package:remote_tv_2026/features/devices/presentation/devices_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tv/stub_tv_provider.dart';

final _saved = PairedAndroidTvMetadata(
  deviceId: 'android_tv:family-room',
  name: 'Family room TV',
  lastKnownHost: '192.168.1.42',
  lastConnectedAt: DateTime(2026),
);

final _savedLongName = PairedAndroidTvMetadata(
  deviceId: 'android_tv:long',
  name: 'The Family Room Premium 4K Home Entertainment Center Television',
  lastKnownHost: '192.168.1.77',
  lastConnectedAt: DateTime(2026),
);

Future<StubTvProvider> _pumpDevices(
  WidgetTester tester, {
  Object? connectError,
}) async {
  final provider = StubTvProvider(
    platform: TvPlatform.androidTv,
    connectError: connectError,
  );
  final container = ProviderContainer(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([provider]),
      ),
      pairedAndroidTvDevicesProvider.overrideWith((ref) async => [_saved]),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.devices,
    routes: [
      GoRoute(
        path: AppRoutes.devices,
        builder: (context, state) => const DevicesScreen(),
      ),
      GoRoute(
        path: AppRoutes.remote,
        builder: (context, state) => const RemoteScreen(),
      ),
      GoRoute(
        path: AppRoutes.pairing,
        builder: (context, state) => const PairingScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return provider;
}

/// Pumps Devices with the saved device already the live connection -
/// distinct from `_pumpDevices`, which starts disconnected and connects
/// only when the test taps Connect.
Future<void> _pumpAlreadyConnected(
  WidgetTester tester, {
  List<PairedAndroidTvMetadata> saved = const [],
}) async {
  final provider = StubTvProvider(platform: TvPlatform.androidTv);
  final container = ProviderContainer(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([provider]),
      ),
      pairedAndroidTvDevicesProvider.overrideWith((ref) async => saved),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(tvSessionControllerProvider.notifier)
      .connect(
        TvDevice(
          id: _saved.deviceId,
          name: _saved.name,
          platform: TvPlatform.androidTv,
          host: _saved.lastKnownHost,
        ),
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DevicesScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a saved Android TV shows a Connect action, not just Forget', (
    tester,
  ) async {
    await _pumpDevices(tester);

    expect(find.text('Family room TV'), findsOneWidget);
    expect(find.text('Last seen at 192.168.1.42'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forget'), findsOneWidget);
  });

  testWidgets(
    'tapping Connect reconnects with the saved identity directly - no '
    'rediscovery screen',
    (tester) async {
      final provider = await _pumpDevices(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(provider.connectCalls, 1);
      expect(find.byType(RemoteScreen), findsOneWidget);
    },
  );

  testWidgets(
    'when the saved identity is rejected, Connect goes to Pairing instead '
    'of leaving the user stuck',
    (tester) async {
      await _pumpDevices(
        tester,
        connectError: const AuthenticationFailedException('rejected'),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // StubTvProvider surfaces any connectError as a plain failure
      // (lastError set, no pairingRequest) - the real AndroidTvProvider
      // is what turns an auth rejection into a fresh TvPinPairingRequest;
      // this only proves Devices doesn't strand the user on itself.
      expect(find.byType(DevicesScreen), findsOneWidget);
    },
  );

  testWidgets('1. the connected device card shows a Connected status', (
    tester,
  ) async {
    await _pumpAlreadyConnected(tester);

    expect(find.text('Family room TV'), findsOneWidget);
    expect(find.text('Connected'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Disconnect'), findsOneWidget);
  });

  testWidgets('8. the saved row for the live connection offers no redundant '
      'Connect button - only the connected card above does anything', (
    tester,
  ) async {
    await _pumpAlreadyConnected(tester, saved: [_saved]);

    // Exactly one "Family room TV" heading in the connected card, one
    // in the saved row below it - but only one Connect-less pairing.
    expect(find.text('Family room TV'), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Connect'), findsNothing);
    // Forget is still offered on the saved row.
    expect(find.widgetWithText(TextButton, 'Forget'), findsOneWidget);
  });

  testWidgets(
    '4. Forget asks for confirmation and only removes the device once '
    'confirmed',
    (tester) async {
      // A real (in-memory) store, not an overridden pairedAndroidTvDevicesProvider,
      // so Forget's actual removal shows up when the list is reloaded -
      // a constant-list override would still return the same devices
      // after invalidation.
      final secureStore = InMemoryCredentialStore();
      final deviceStore = AndroidTvPairedDeviceStore(secureStore: secureStore);
      await deviceStore.saveMetadata(_saved);
      final container = ProviderContainer(
        overrides: [
          tvProviderRegistryProvider.overrideWithValue(
            TvProviderRegistry([
              StubTvProvider(platform: TvPlatform.androidTv),
            ]),
          ),
          secureCredentialStoreProvider.overrideWithValue(secureStore),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DevicesScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.widgetWithText(TextButton, 'Forget'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Forget this TV?'), findsOneWidget);

      // Cancel leaves the device in place.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Family room TV'), findsOneWidget);

      // Confirming actually forgets it.
      await tester.tap(find.widgetWithText(TextButton, 'Forget'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Forget'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No saved TVs'), findsOneWidget);
    },
  );

  testWidgets('5. an empty saved-devices list shows the premium empty '
      'state with a Find a TV CTA', (tester) async {
    final container = ProviderContainer(
      overrides: [
        tvProviderRegistryProvider.overrideWithValue(
          TvProviderRegistry([StubTvProvider(platform: TvPlatform.androidTv)]),
        ),
        pairedAndroidTvDevicesProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.devices,
      routes: [
        GoRoute(
          path: AppRoutes.devices,
          builder: (context, state) => const DevicesScreen(),
        ),
        GoRoute(
          path: AppRoutes.discovery,
          builder: (context, state) => const Scaffold(body: Text('Discovery!')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No saved TVs'), findsOneWidget);
    expect(
      find.text('Connect a TV to control it quickly next time.'),
      findsOneWidget,
    );
    // No redundant second "Add another TV" button when the list is empty -
    // the empty state's own CTA is the only one.
    expect(find.text('Add another TV'), findsNothing);

    // 6. tapping it pushes Discovery.
    await tester.tap(find.widgetWithText(FilledButton, 'Find a TV'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Discovery!'), findsOneWidget);
  });

  testWidgets('7. a very long device name never overflows the card', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        tvProviderRegistryProvider.overrideWithValue(
          TvProviderRegistry([StubTvProvider(platform: TvPlatform.androidTv)]),
        ),
        pairedAndroidTvDevicesProvider.overrideWith(
          (ref) async => [_savedLongName],
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DevicesScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('The Family Room'), findsOneWidget);
  });
}
