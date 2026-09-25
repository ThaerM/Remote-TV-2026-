import '../../../core/logging/app_logger.dart';
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
  final _logger = AppLogger('TV.Registry');

  Iterable<TvProvider> get all => _providers.values;

  TvProvider? forPlatform(TvPlatform platform) => _providers[platform];

  /// Runs [TvProvider.discover] across every registered provider in
  /// parallel and merges the outcomes. A provider that throws despite the
  /// never-throw contract is logged and reported as
  /// [TvDiscoveryIssue.failed] - never silently turned into "no TVs".
  Future<TvDiscoveryOutcome> discoverAll() async {
    final outcomes = await Future.wait(
      all.map(
        (provider) => provider.discover().catchError((Object error) {
          _logger.warning(
            '[TV][DISCOVERY] provider_failed platform=${provider.platform.name} '
            'type=${error.runtimeType}',
          );
          return TvDiscoveryOutcome.issue(TvDiscoveryIssue.failed);
        }),
      ),
    );
    return TvDiscoveryOutcome.merge(outcomes);
  }

  /// Asks every provider whether it recognizes a device at [host].
  Future<List<TvDevice>> probeAll(String host) async {
    final found = await Future.wait(
      all.map(
        (provider) => provider.probeHost(host).catchError((Object error) {
          _logger.warning(
            '[TV][DISCOVERY] probe_failed platform=${provider.platform.name} '
            'type=${error.runtimeType}',
          );
          return null;
        }),
      ),
    );
    return found.whereType<TvDevice>().toList(growable: false);
  }
}
