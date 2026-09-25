import 'dart:async';

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

  testWidgets(
    '5. the AppBar Back button (not just the Cancel text button) also '
    'cancels a pending pairing attempt',
    (tester) async {
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
        initialLocation: '/discovery',
        routes: [
          GoRoute(
            path: '/discovery',
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
      expect(
        find.text('Enter the 6-character pairing code shown on your TV.'),
        findsOne,
      );

      await tester.tap(find.byType(BackButton));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Pick TV'), findsOneWidget);
      expect(provider.disconnectCalls, 1);
      expect(
        container.read(tvSessionControllerProvider).selectedDevice,
        isNull,
      );
    },
  );

  testWidgets('a hung "Connecting..." state (no pairing request, no error yet) '
      'still offers a way out - never an indefinite spinner', (tester) async {
    final hangingConnect = Completer<TvPairingRequest>();
    final provider = _HangingConnectProvider(hangingConnect.future);
    final container = ProviderContainer(
      overrides: [
        tvProviderRegistryProvider.overrideWithValue(
          TvProviderRegistry([provider]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/discovery',
      routes: [
        GoRoute(
          path: '/discovery',
          builder: (context, state) => const Scaffold(body: SizedBox()),
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
    unawaited(container.read(tvSessionControllerProvider.notifier).connect(tv));
    unawaited(router.push(AppRoutes.pairing));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Connecting to Family room TV…'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(PairingScreen), findsNothing);
    expect(provider.disconnectCalls, 1);
  });
}

/// A [TvProvider] whose `connect` never resolves on its own - simulates
/// the real-device stall (a TLS handshake that hangs) that motivated
/// bounding `SecureSocket.connect` in the Android TV provider.
class _HangingConnectProvider implements TvProvider {
  _HangingConnectProvider(this._pending);

  final Future<TvPairingRequest> _pending;
  int disconnectCalls = 0;
  final _states = StreamController<TvConnectionState>.broadcast();

  @override
  TvPlatform get platform => TvPlatform.androidTv;

  @override
  Future<TvDiscoveryOutcome> discover() async => const TvDiscoveryOutcome();

  @override
  Future<TvDevice?> probeHost(String host) async => null;

  @override
  Future<TvPairingRequest> connect(TvDevice device) => _pending;

  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _states.add(TvConnectionState.disconnected);
  }

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  @override
  Future<TvCapabilities> getCapabilities() async => TvCapabilities.none;

  @override
  Future<void> sendCommand(TvCommand command) async {}

  @override
  Future<List<TvApplication>> getApplications() async => const [];
}
