import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/flutter_secure_credential_store.dart';
import '../../core/storage/secure_credential_store.dart';
import 'android_tv/android_tv_provider.dart';
import 'android_tv/storage/android_tv_paired_device_store.dart';
import 'fake/fake_tv_provider.dart';
import 'registry/tv_provider_registry.dart';

/// Long-lived [FakeTvProvider] instance backing the demo experience.
///
/// Kept registered alongside real providers (not replaced by them) so
/// the app, tests, and screenshots can keep exercising the full UI
/// without a physical TV - see
/// `docs/architecture/provider-system.md`.
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

final tvProviderRegistryProvider = Provider<TvProviderRegistry>((ref) {
  return TvProviderRegistry([
    ref.watch(fakeTvProviderProvider),
    ref.watch(androidTvProviderProvider),
  ]);
});
