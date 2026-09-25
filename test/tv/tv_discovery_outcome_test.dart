import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';

import 'stub_tv_provider.dart';

void main() {
  const tv = TvDevice(id: 'a', name: 'A', platform: TvPlatform.androidTv);

  group('TvDiscoveryOutcome', () {
    test('primaryIssue picks the most actionable issue', () {
      final outcome = TvDiscoveryOutcome(
        issues: {
          TvDiscoveryIssue.failed,
          TvDiscoveryIssue.localNetworkDenied,
          TvDiscoveryIssue.timedOut,
        },
      );

      expect(outcome.primaryIssue, TvDiscoveryIssue.localNetworkDenied);
    });

    test('merge combines devices and issues', () {
      final merged = TvDiscoveryOutcome.merge([
        const TvDiscoveryOutcome(devices: [tv]),
        TvDiscoveryOutcome.issue(TvDiscoveryIssue.multicastRestricted),
      ]);

      expect(merged.devices, [tv]);
      expect(merged.primaryIssue, TvDiscoveryIssue.multicastRestricted);
    });

    test('no issues means no primaryIssue', () {
      expect(const TvDiscoveryOutcome().primaryIssue, isNull);
    });
  });

  group('TvProviderRegistry', () {
    test('a provider that throws is reported as failed, not hidden', () async {
      final registry = TvProviderRegistry([
        StubTvProvider(
          platform: TvPlatform.androidTv,
          discoverError: StateError('x'),
        ),
        StubTvProvider(
          platform: TvPlatform.roku,
          outcome: const TvDiscoveryOutcome(devices: [tv]),
        ),
      ]);

      final outcome = await registry.discoverAll();

      expect(outcome.devices, [tv]);
      expect(outcome.issues, {TvDiscoveryIssue.failed});
    });

    test('probeAll collects every provider that recognizes the host', () async {
      final registry = TvProviderRegistry([
        StubTvProvider(platform: TvPlatform.androidTv, probeResult: tv),
        StubTvProvider(platform: TvPlatform.roku),
        StubTvProvider(
          platform: TvPlatform.lgWebOs,
          probeError: StateError('x'),
        ),
      ]);

      expect(await registry.probeAll('192.168.1.5'), [tv]);
    });
  });
}
