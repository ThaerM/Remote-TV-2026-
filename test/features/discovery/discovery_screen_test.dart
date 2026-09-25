import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../../tv/stub_tv_provider.dart';

const _manualTv = TvDevice(
  id: 'android_tv:192.168.1.42',
  name: 'Android TV (192.168.1.42)',
  platform: TvPlatform.androidTv,
  host: '192.168.1.42',
);

Widget _app(StubTvProvider provider) {
  return ProviderScope(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([provider]),
      ),
    ],
    child: const MaterialApp(home: DiscoveryScreen()),
  );
}

Future<void> _settleScan(WidgetTester tester) async {
  // Not pumpAndSettle: the scanning radar repeats by design.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('DiscoveryScreen', () {
    testWidgets('explains a denied local network permission', (tester) async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        outcome: TvDiscoveryOutcome.issue(TvDiscoveryIssue.localNetworkDenied),
      );
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      expect(find.text('Local network access is off'), findsOneWidget);
      expect(find.text('Scan again'), findsOneWidget);
      expect(find.text('Add TV by IP address'), findsOneWidget);
    });

    testWidgets('a healthy empty scan shows the generic no-TVs copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(StubTvProvider(platform: TvPlatform.androidTv)),
      );
      await _settleScan(tester);

      expect(find.text('No TVs found'), findsOneWidget);
    });

    testWidgets('adding a TV by address lists it', (tester) async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        probeResult: _manualTv,
      );
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      await tester.tap(find.text('Add TV by IP address'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), ' 192.168.1.42 ');
      await tester.tap(find.text('Add TV'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(provider.probedHosts, ['192.168.1.42']);
      expect(find.text('Android TV (192.168.1.42)'), findsOneWidget);
      // Let the card's staggered entrance timer finish.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('an address nothing answers at shows an inline error', (
      tester,
    ) async {
      final provider = StubTvProvider(platform: TvPlatform.androidTv);
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      await tester.tap(find.text('Add TV by IP address'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), '10.0.0.7');
      await tester.tap(find.text('Add TV'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('No supported TV answered'), findsOneWidget);
    });

    testWidgets('rejects obviously invalid input without probing', (
      tester,
    ) async {
      final provider = StubTvProvider(platform: TvPlatform.androidTv);
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      await tester.tap(find.text('Add TV by IP address'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), 'not an address!');
      await tester.tap(find.text('Add TV'));
      await tester.pump();

      expect(provider.probedHosts, isEmpty);
      expect(find.textContaining('Enter an IP address'), findsOneWidget);
    });
  });

  testWidgets('with reduced motion, found TVs appear without animating', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      _app(
        StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: const TvDiscoveryOutcome(devices: [_manualTv]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Android TV (192.168.1.42)'),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  group('DiscoveryScreen physical device grouping', () {
    testWidgets(
      'Android TV + Cast on the same host show one grouped card, titled '
      'with the TV name and both capabilities',
      (tester) async {
        final provider = StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: const TvDiscoveryOutcome(
            devices: [
              TvDevice(
                id: 'android_tv:Android_9ca7.local',
                name: 'Family room TV',
                platform: TvPlatform.androidTv,
                host: '192.168.1.42',
              ),
              TvDevice(
                id: 'cast:abc123',
                name: 'Family room TV',
                platform: TvPlatform.googleCast,
                host: '192.168.1.42',
              ),
            ],
          ),
        );
        await tester.pumpWidget(_app(provider));
        await _settleScan(tester);

        expect(find.text('Family room TV'), findsOneWidget);
        // Shown as separate capability badges, not one joined string.
        expect(find.text('Remote'), findsOneWidget);
        expect(find.text('Cast'), findsOneWidget);
        expect(find.text('Remote • Cast'), findsNothing);
        // Never a raw protocol label for a grouped device.
        expect(find.text('Android TV / Google TV'), findsNothing);
        expect(find.text('Google Cast'), findsNothing);
      },
    );

    testWidgets('a Cast-only device shows its plain platform label', (
      tester,
    ) async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        outcome: const TvDiscoveryOutcome(
          devices: [
            TvDevice(
              id: 'cast:def456',
              name: 'Living Room Chromecast',
              platform: TvPlatform.googleCast,
              host: '192.168.1.60',
            ),
          ],
        ),
      );
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      expect(find.text('Living Room Chromecast'), findsOneWidget);
      expect(find.text('Google Cast'), findsOneWidget);
      expect(find.text('Remote • Cast'), findsNothing);
    });

    testWidgets('a remote-only Android TV shows its plain platform label', (
      tester,
    ) async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        outcome: const TvDiscoveryOutcome(
          devices: [
            TvDevice(
              id: 'android_tv:Android_solo.local',
              name: 'Office TV',
              platform: TvPlatform.androidTv,
              host: '192.168.1.70',
            ),
          ],
        ),
      );
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      expect(find.text('Office TV'), findsOneWidget);
      expect(find.text('Android TV / Google TV'), findsOneWidget);
      expect(find.text('Remote • Cast'), findsNothing);
    });

    testWidgets('same display name, different hosts: two cards, never merged', (
      tester,
    ) async {
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
            TvDevice(
              id: 'cast:two',
              name: 'Family room TV',
              platform: TvPlatform.googleCast,
              host: '192.168.1.99',
            ),
          ],
        ),
      );
      await tester.pumpWidget(_app(provider));
      await _settleScan(tester);

      expect(find.text('Family room TV'), findsNWidgets(2));
      expect(find.text('Android TV / Google TV'), findsOneWidget);
      expect(find.text('Google Cast'), findsOneWidget);
      expect(find.text('Remote • Cast'), findsNothing);
    });

    testWidgets(
      'tapping a grouped card connects with the remote endpoint, never '
      'asking the user to pick a protocol',
      (tester) async {
        final provider = StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: const TvDiscoveryOutcome(
            devices: [
              TvDevice(
                id: 'android_tv:Android_9ca7.local',
                name: 'Family room TV',
                platform: TvPlatform.androidTv,
                host: '192.168.1.42',
              ),
              TvDevice(
                id: 'cast:abc123',
                name: 'Family room TV',
                platform: TvPlatform.googleCast,
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
        await _settleScan(tester);

        await tester.tap(find.text('Family room TV'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(provider.connectCalls, 1);
        expect(find.text('Connected!'), findsOneWidget);
      },
    );
  });

  group('TvSessionController manual devices', () {
    test('a manually added TV survives a rescan', () async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        probeResult: _manualTv,
      );
      final container = ProviderContainer(
        overrides: [
          tvProviderRegistryProvider.overrideWithValue(
            TvProviderRegistry([provider]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(tvSessionControllerProvider.notifier);

      expect(await controller.addDeviceByAddress('192.168.1.42'), 1);
      await controller.discover();

      expect(container.read(tvSessionControllerProvider).discoveredDevices, [
        _manualTv,
      ]);
    });

    test('the scan issue is exposed on the session state', () async {
      final provider = StubTvProvider(
        platform: TvPlatform.androidTv,
        outcome: TvDiscoveryOutcome.issue(TvDiscoveryIssue.networkUnavailable),
      );
      final container = ProviderContainer(
        overrides: [
          tvProviderRegistryProvider.overrideWithValue(
            TvProviderRegistry([provider]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tvSessionControllerProvider.notifier).discover();

      expect(
        container.read(tvSessionControllerProvider).discoveryIssue,
        TvDiscoveryIssue.networkUnavailable,
      );
    });
  });
}
