import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
