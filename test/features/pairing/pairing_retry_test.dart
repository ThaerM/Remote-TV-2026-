import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../../tv/stub_tv_provider.dart';

void main() {
  const tv = TvDevice(
    id: 'android_tv:family-room',
    name: 'Family room TV',
    platform: TvPlatform.androidTv,
    host: '192.168.1.42',
  );

  Future<StubTvProvider> pumpFailedConnect(WidgetTester tester) async {
    final provider = StubTvProvider(
      platform: TvPlatform.androidTv,
      connectError: const DeviceNotReachableException('No route to host.'),
    );
    final container = ProviderContainer(
      overrides: [
        tvProviderRegistryProvider.overrideWithValue(
          TvProviderRegistry([provider]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.discovery,
      routes: [
        GoRoute(
          path: AppRoutes.discovery,
          builder: (context, state) => const DiscoveryScreen(),
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
    await container.read(tvSessionControllerProvider.notifier).connect(tv);
    unawaited(router.push(AppRoutes.pairing));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return provider;
  }

  testWidgets(
    'a failed connect exits Connecting… and offers Retry and Back, never '
    'an indefinite spinner',
    (tester) async {
      await pumpFailedConnect(tester);

      expect(find.text('Connecting…'), findsNothing);
      expect(
        find.textContaining('Could not connect to Family room TV.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Back'), findsOneWidget);
    },
  );

  testWidgets('tapping Retry reconnects with the same device', (tester) async {
    final provider = await pumpFailedConnect(tester);
    final callsBeforeRetry = provider.connectCalls;

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(provider.connectCalls, callsBeforeRetry + 1);
  });
}
