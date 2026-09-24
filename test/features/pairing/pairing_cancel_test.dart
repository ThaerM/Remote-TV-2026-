import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
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

  testWidgets('Cancel on the code screen goes back and closes the pairing', (
    tester,
  ) async {
    final provider = StubTvProvider(
      platform: TvPlatform.androidTv,
      pairingRequest: const TvPinPairingRequest(
        expectedLength: 6,
        alphabet: TvPinAlphabet.hex,
      ),
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
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await container
                      .read(tvSessionControllerProvider.notifier)
                      .connect(tv);
                  if (context.mounted) {
                    await context.push(AppRoutes.pairing);
                  }
                },
                child: const Text('Pick TV'),
              ),
            ),
          ),
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
    await tester.tap(find.text('Pick TV'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Enter the code shown on your television.'), findsOne);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    // Through the pop transition until the pairing screen is disposed.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Pick TV'), findsOneWidget);
    expect(provider.disconnectCalls, 1);
    expect(container.read(tvSessionControllerProvider).selectedDevice, isNull);
  });
}
