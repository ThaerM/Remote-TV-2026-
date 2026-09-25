import '../../../tv/domain/tv_domain.dart';

/// Resolves a bundled artwork asset for a launchable [TvApplication],
/// shared by the Remote screen's Quick Apps row and the Apps screen so
/// the two never carry two separate copies of this mapping.
///
/// Bundled assets under `assets/app_icons/` are a fixed, small set of
/// apps this repository already ships approved artwork for - this is
/// *not* an icon pack or a general logo service, and it never fetches
/// anything remotely (see docs/research - no provider currently returns
/// icon bytes/URLs; [TvApplication.iconKey] is a same-repo hint a
/// provider sets, not third-party data). An app this resolver doesn't
/// recognize always renders with the generic fallback icon - see
/// `AppsScreen`/`RemoteScreen`'s `Icons.apps_rounded`/
/// `Icons.smart_display_outlined` usage - never a broken image.
class AppArtworkResolver {
  const AppArtworkResolver._();

  /// Canonical app key -> bundled asset path. Only apps this repo has
  /// actual approved artwork for appear here; every other known alias
  /// below still resolves to a canonical key with no asset yet, which
  /// correctly returns null (never a missing-file crash).
  static const Map<String, String> _assetByKey = {
    'netflix': 'assets/app_icons/netflix_icon.png',
    'disney_plus': 'assets/app_icons/disney_plus_icon.png',
    'prime_video': 'assets/app_icons/prime_video_icon.jpeg',
    'apple_tv': 'assets/app_icons/apple_tv_icon.png',
  };

  /// Normalized id/name/iconKey text -> canonical app key. Built only
  /// from names/ids this codebase's own providers actually produce
  /// (`FakeTvProvider`, `AndroidTvProvider`'s app-link catalog) plus the
  /// plain display names real TV apps are always shown under (Roku's
  /// `/query/apps` and Samsung's `ed.installedApp.get` return each
  /// device's own app name, e.g. "Netflix"/"Prime Video", verbatim) -
  /// never an invented package id this repo has no evidence for.
  static const Map<String, String> _aliases = {
    'netflix': 'netflix',
    'youtube': 'youtube',
    'youtube music': 'youtube_music',
    'google tv': 'google_tv',
    'prime video': 'prime_video',
    'amazon prime video': 'prime_video',
    'disney+': 'disney_plus',
    'disney plus': 'disney_plus',
    'spotify': 'spotify',
    'plex': 'plex',
    'vlc': 'vlc',
    'apple tv': 'apple_tv',
  };

  /// The local asset path for [iconKey]/[id]/[name], or null when this
  /// app isn't one this repo has (or has aliased) artwork for. Checks
  /// the strongest evidence first: a provider-set [iconKey] (an explicit
  /// same-repo hint, not guessed), then the app's own stable id, then
  /// its display name - never the name alone when a stable id is
  /// available, per the matching priority this resolver is built to.
  static String? resolve({
    String? iconKey,
    required String id,
    required String name,
  }) {
    for (final candidate in [iconKey, id, name]) {
      if (candidate == null) continue;
      final normalized = _normalize(candidate);
      if (normalized.isEmpty) continue;
      final key = _aliases[normalized] ?? normalized;
      final asset = _assetByKey[key];
      if (asset != null) return asset;
    }
    return null;
  }

  /// Convenience wrapper over [resolve] for callers that already have a
  /// full [TvApplication] - Quick Apps and the Apps screen both use this
  /// one entry point rather than each re-extracting the three fields.
  static String? resolveForApp(TvApplication app) =>
      resolve(iconKey: app.iconKey, id: app.id, name: app.name);

  /// lowercase, trimmed, underscores/hyphens folded to spaces, internal
  /// whitespace collapsed - safe against the id/name spelling
  /// differences (`disney_plus` vs `Disney+` vs `Disney Plus`) real
  /// provider responses and this repo's own iconKeys actually show,
  /// without stripping punctuation aggressively enough to merge
  /// unrelated names.
  static String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
