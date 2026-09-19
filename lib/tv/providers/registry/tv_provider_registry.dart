import '../../domain/tv_domain.dart';

/// Holds every [TvProvider] the app knows about, keyed by [TvPlatform].
///
/// This is the single place that knows the full set of providers; UI and
/// discovery/pairing features depend on this registry rather than
/// instantiating providers themselves, so a provider can be swapped for a
/// fake/mock in tests.
class TvProviderRegistry {
  TvProviderRegistry(Iterable<TvProvider> providers)
    : _providers = {for (final p in providers) p.platform: p};

  final Map<TvPlatform, TvProvider> _providers;

  Iterable<TvProvider> get all => _providers.values;

  TvProvider? forPlatform(TvPlatform platform) => _providers[platform];

  /// Runs [TvProvider.discover] across every registered provider in
  /// parallel and flattens the results. A provider that throws is treated
  /// as "found nothing" rather than failing the whole scan.
  Future<List<TvDevice>> discoverAll() async {
    final results = await Future.wait(
      all.map(
        (provider) => provider.discover().catchError((_) => <TvDevice>[]),
      ),
    );
    return results.expand((devices) => devices).toList(growable: false);
  }
}
