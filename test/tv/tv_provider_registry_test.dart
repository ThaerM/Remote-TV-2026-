import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/fake/fake_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';

void main() {
  group('TvProviderRegistry', () {
    test('forPlatform returns the registered provider', () {
      final fake = FakeTvProvider();
      final registry = TvProviderRegistry([fake]);

      expect(registry.forPlatform(TvPlatform.fake), same(fake));
      expect(registry.forPlatform(TvPlatform.samsungTizen), isNull);
    });

    test('discoverAll flattens results from every provider', () async {
      final fake = FakeTvProvider();
      final registry = TvProviderRegistry([fake]);

      final devices = await registry.discoverAll();

      expect(devices, isNotEmpty);
      expect(devices.every((d) => d.platform == TvPlatform.fake), isTrue);
    });
  });
}
