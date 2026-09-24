import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/flutter_secure_credential_store.dart';
import '../../core/storage/secure_credential_store.dart';
import '../domain/tv_domain.dart';
import 'android_tv/android_tv_provider.dart';
import 'android_tv/storage/android_tv_paired_device_store.dart';
import 'fake/fake_tv_provider.dart';
import 'google_cast/google_cast_provider.dart';
import 'lg_webos/lg_webos_provider.dart';
import 'registry/tv_provider_registry.dart';
import 'roku/roku_provider.dart';
import 'samsung/samsung_tv_provider.dart';

/// Long-lived [FakeTvProvider] instance backing the demo experience.
///
/// Only registered into [tvProviderRegistryProvider] when
/// [kEnableDemoTvDevices] is set - see [selectRegisteredProviders]. The
/// provider itself is still created eagerly (it's cheap: no sockets, no
/// real I/O) so the flag can be toggled without restructuring the
/// provider graph.
final fakeTvProviderProvider = Provider<FakeTvProvider>((ref) {
  final provider = FakeTvProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

/// Keychain/Keystore-backed credential storage used by every real
/// provider to persist pairing secrets - see
/// `docs/architecture/security.md`.
final secureCredentialStoreProvider = Provider<SecureCredentialStore>((ref) {
  return FlutterSecureCredentialStore();
});

final androidTvPairedDeviceStoreProvider = Provider<AndroidTvPairedDeviceStore>(
  (ref) {
    return AndroidTvPairedDeviceStore(
      secureStore: ref.watch(secureCredentialStoreProvider),
    );
  },
);

final androidTvProviderProvider = Provider<AndroidTvProvider>((ref) {
  final provider = AndroidTvProvider(
    store: ref.watch(androidTvPairedDeviceStoreProvider),
  );
  ref.onDispose(provider.dispose);
  return provider;
});

final googleCastProviderProvider = Provider<GoogleCastProvider>((ref) {
  final provider = GoogleCastProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

final lgWebOsProviderProvider = Provider<LgWebOsProvider>((ref) {
  final provider = LgWebOsProvider(
    secureStore: ref.watch(secureCredentialStoreProvider),
  );
  ref.onDispose(provider.dispose);
  return provider;
});

final samsungTvProviderProvider = Provider<SamsungTvProvider>((ref) {
  final provider = SamsungTvProvider(
    secureStore: ref.watch(secureCredentialStoreProvider),
  );
  ref.onDispose(provider.dispose);
  return provider;
});

final rokuProviderProvider = Provider<RokuProvider>((ref) {
  final provider = RokuProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

/// Decides which [TvProvider]s get registered, given whether demo
/// devices are enabled.
///
/// Pulled out as a plain function (rather than inlined in the Provider
/// below) so the on/off behavior of [kEnableDemoTvDevices] is directly
/// unit-testable without needing a `--dart-define` recompile - see
/// `test/tv/providers/tv_provider_registry_provider_test.dart`.
///
/// Real providers ([AndroidTvProvider], [GoogleCastProvider],
/// [LgWebOsProvider], [RokuProvider], [SamsungTvProvider]) are always
/// registered. `FakeTvProvider` is opt-in only, so a normal `flutter
/// run` against a real TV never mixes demo devices into real discovery
/// results.
List<TvProvider> selectRegisteredProviders({
  required bool enableDemoDevices,
  required List<TvProvider> realProviders,
  required TvProvider fakeTvProvider,
}) {
  return [...realProviders, if (enableDemoDevices) fakeTvProvider];
}

final tvProviderRegistryProvider = Provider<TvProviderRegistry>((ref) {
  return TvProviderRegistry(
    selectRegisteredProviders(
      enableDemoDevices: kEnableDemoTvDevices,
      realProviders: [
        ref.watch(androidTvProviderProvider),
        ref.watch(googleCastProviderProvider),
        ref.watch(lgWebOsProviderProvider),
        ref.watch(rokuProviderProvider),
        ref.watch(samsungTvProviderProvider),
      ],
      fakeTvProvider: ref.watch(fakeTvProviderProvider),
    ),
  );
});
