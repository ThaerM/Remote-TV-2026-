import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/fake/fake_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

/// Stands in for a real (non-fake) provider without touching real
/// network I/O - `discoverAll` tests care about registry wiring and
/// ownership, not about mDNS itself (that's covered elsewhere with a
/// physical device, per docs/testing/android-tv-real-device.md).
class _StubRealProvider implements TvProvider {
  @override
  TvPlatform get platform => TvPlatform.androidTv;

  @override
  Future<TvDiscoveryOutcome> discover() async => const TvDiscoveryOutcome(
    devices: [
      TvDevice(
        id: 'real-1',
        name: 'Living Room TV',
        platform: TvPlatform.androidTv,
        host: '192.168.1.5',
      ),
    ],
  );

  @override
  Future<TvDevice?> probeHost(String host) async => null;

  @override
  Future<TvPairingRequest> connect(TvDevice device) async =>
      TvPairingRequest.none;

  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<TvConnectionState> get connectionState => const Stream.empty();

  @override
  Future<TvCapabilities> getCapabilities() async => TvCapabilities.none;

  @override
  Future<void> sendCommand(TvCommand command) async {}

  @override
  Future<List<TvApplication>> getApplications() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('selectRegisteredProviders', () {
    test('normal mode (demo disabled) registers only the real provider', () {
      final real = _StubRealProvider();
      final fake = FakeTvProvider();

      final providers = selectRegisteredProviders(
        enableDemoDevices: false,
        androidTvProvider: real,
        fakeTvProvider: fake,
      );

      expect(providers, [real]);
      expect(providers, isNot(contains(fake)));

      fake.dispose();
    });

    test('demo mode (demo enabled) registers both providers', () {
      final real = _StubRealProvider();
      final fake = FakeTvProvider();

      final providers = selectRegisteredProviders(
        enableDemoDevices: true,
        androidTvProvider: real,
        fakeTvProvider: fake,
      );

      expect(providers, containsAll([real, fake]));
      expect(providers, hasLength(2));

      fake.dispose();
    });
  });

  group('TvProviderRegistry platform ownership', () {
    test(
      'a normal-mode registry resolves androidTv to the real provider only',
      () {
        final real = _StubRealProvider();
        final fake = FakeTvProvider();
        final registry = TvProviderRegistry(
          selectRegisteredProviders(
            enableDemoDevices: false,
            androidTvProvider: real,
            fakeTvProvider: fake,
          ),
        );

        expect(registry.forPlatform(TvPlatform.androidTv), same(real));
        expect(registry.forPlatform(TvPlatform.fake), isNull);

        fake.dispose();
      },
    );

    test(
      'a demo-mode registry never lets FakeTvProvider own TvPlatform.androidTv',
      () {
        final real = _StubRealProvider();
        final fake = FakeTvProvider();
        final registry = TvProviderRegistry(
          selectRegisteredProviders(
            enableDemoDevices: true,
            androidTvProvider: real,
            fakeTvProvider: fake,
          ),
        );

        // Real Android/Google TV devices always resolve to the real provider.
        expect(registry.forPlatform(TvPlatform.androidTv), same(real));
        // Fake devices only ever resolve to FakeTvProvider.
        expect(registry.forPlatform(TvPlatform.fake), same(fake));
        // No collision: each platform maps to exactly one, distinct provider.
        expect(
          registry.forPlatform(TvPlatform.androidTv),
          isNot(same(registry.forPlatform(TvPlatform.fake))),
        );

        fake.dispose();
      },
    );

    test('discoverAll in normal mode never returns devices marked isDevelopmentFake', () async {
      final real = _StubRealProvider();
      final fake = FakeTvProvider();
      final registry = TvProviderRegistry(
        selectRegisteredProviders(
          enableDemoDevices: false,
          androidTvProvider: real,
          fakeTvProvider: fake,
        ),
      );

      final devices = (await registry.discoverAll()).devices;

      expect(devices, hasLength(1));
      expect(devices.any((d) => d.isDevelopmentFake), isFalse);

      fake.dispose();
    });

    test(
      'discoverAll in demo mode can return devices marked isDevelopmentFake',
      () async {
        final real = _StubRealProvider();
        final fake = FakeTvProvider();
        final registry = TvProviderRegistry(
          selectRegisteredProviders(
            enableDemoDevices: true,
            androidTvProvider: real,
            fakeTvProvider: fake,
          ),
        );

        final devices = (await registry.discoverAll()).devices;

        expect(devices.any((d) => d.isDevelopmentFake), isTrue);
        expect(devices.any((d) => !d.isDevelopmentFake), isTrue);

        fake.dispose();
      },
    );
  });

  group('AndroidTvProvider identity', () {
    test('AndroidTvProvider always reports TvPlatform.androidTv', () {
      final provider = AndroidTvProvider(
        store: AndroidTvPairedDeviceStore(
          secureStore: InMemoryCredentialStore(),
        ),
      );

      expect(provider.platform, TvPlatform.androidTv);

      provider.dispose();
    });
  });
}
