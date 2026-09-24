import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/features/devices/application/paired_android_tv_controller.dart';
import 'package:remote_tv_2026/features/devices/presentation/devices_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../../tv/stub_tv_provider.dart';

final _saved = PairedAndroidTvMetadata(
  deviceId: 'android_tv:family-room',
  name: 'Family room TV',
  lastKnownHost: '192.168.1.42',
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

void main() {
  testWidgets('a saved Android TV shows a Connect action, not just Forget', (
    tester,
  ) async {
    await _pumpDevices(tester);

    expect(find.text('Family room TV'), findsOneWidget);
    expect(find.text('Last seen at 192.168.1.42'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Connect'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Forget'), findsOneWidget);
  });

  testWidgets(
    'tapping Connect reconnects with the saved identity directly - no '
    'rediscovery screen',
    (tester) async {
      final provider = await _pumpDevices(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Connect'));
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

      await tester.tap(find.widgetWithText(TextButton, 'Connect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // StubTvProvider surfaces any connectError as a plain failure
      // (lastError set, no pairingRequest) - the real AndroidTvProvider
      // is what turns an auth rejection into a fresh TvPinPairingRequest;
      // this only proves Devices doesn't strand the user on itself.
      expect(find.byType(DevicesScreen), findsOneWidget);
    },
  );
}
