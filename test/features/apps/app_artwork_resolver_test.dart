import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/apps/application/app_artwork_resolver.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

void main() {
  group('AppArtworkResolver', () {
    test('1. a known Netflix app resolves the Netflix asset', () {
      expect(
        AppArtworkResolver.resolve(
          iconKey: 'netflix',
          id: 'netflix',
          name: 'Netflix',
        ),
        'assets/app_icons/netflix_icon.png',
      );
    });

    test('2. a known YouTube app is aliased but has no bundled asset yet - '
        'resolves to null, never a crash', () {
      expect(
        AppArtworkResolver.resolve(
          iconKey: 'youtube',
          id: 'youtube',
          name: 'YouTube',
        ),
        isNull,
      );
    });

    test('3. name matching is case-insensitive', () {
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'NETFLIX'),
        'assets/app_icons/netflix_icon.png',
      );
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'nEtFlIx'),
        'assets/app_icons/netflix_icon.png',
      );
    });

    test('4. name matching tolerates surrounding/extra whitespace', () {
      expect(
        AppArtworkResolver.resolve(id: 'x', name: '  Netflix  '),
        'assets/app_icons/netflix_icon.png',
      );
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Prime   Video'),
        'assets/app_icons/prime_video_icon.jpeg',
      );
    });

    test('5. a stable app id wins over a display name that would resolve '
        'differently', () {
      // The id says Netflix; a misleading display name must not win.
      expect(
        AppArtworkResolver.resolve(id: 'netflix', name: 'My Channel 4'),
        'assets/app_icons/netflix_icon.png',
      );
    });

    test('6. an unrecognized app returns null safely, never throws', () {
      expect(
        AppArtworkResolver.resolve(
          id: 'com.example.mystery',
          name: 'Mystery App',
        ),
        isNull,
      );
    });

    test('Disney+ resolves via both "disney+" and "disney plus" spellings', () {
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Disney+'),
        'assets/app_icons/disney_plus_icon.png',
      );
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Disney Plus'),
        'assets/app_icons/disney_plus_icon.png',
      );
      expect(
        AppArtworkResolver.resolve(id: 'disney_plus', name: 'Disney+'),
        'assets/app_icons/disney_plus_icon.png',
      );
    });

    test('Prime Video resolves via both "prime video" and the Amazon-prefixed alias', () {
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Prime Video'),
        'assets/app_icons/prime_video_icon.jpeg',
      );
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Amazon Prime Video'),
        'assets/app_icons/prime_video_icon.jpeg',
      );
    });

    test('Apple TV resolves via its bundled asset', () {
      expect(
        AppArtworkResolver.resolve(id: 'x', name: 'Apple TV'),
        'assets/app_icons/apple_tv_icon.png',
      );
    });

    test('iconKey is checked before id/name - the strongest same-repo hint '
        'wins', () {
      expect(
        AppArtworkResolver.resolve(
          iconKey: 'netflix',
          id: 'com.roku.unrelated.123',
          name: 'Some Weird Channel Name',
        ),
        'assets/app_icons/netflix_icon.png',
      );
    });

    test('resolveForApp reads the same three fields off a TvApplication', () {
      const app = TvApplication(
        id: 'prime_video',
        name: 'Prime Video',
        iconKey: 'prime_video',
      );
      expect(
        AppArtworkResolver.resolveForApp(app),
        'assets/app_icons/prime_video_icon.jpeg',
      );
    });
  });
}
