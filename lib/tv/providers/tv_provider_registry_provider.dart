import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake/fake_tv_provider.dart';
import 'registry/tv_provider_registry.dart';

/// Long-lived [FakeTvProvider] instance backing the current foundation.
///
/// Real providers (Android TV, Google Cast, Samsung, ...) will be added
/// here one at a time in later phases - see
/// docs/product/feature-roadmap.md.
final fakeTvProviderProvider = Provider<FakeTvProvider>((ref) {
  final provider = FakeTvProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

final tvProviderRegistryProvider = Provider<TvProviderRegistry>((ref) {
  return TvProviderRegistry([ref.watch(fakeTvProviderProvider)]);
});
