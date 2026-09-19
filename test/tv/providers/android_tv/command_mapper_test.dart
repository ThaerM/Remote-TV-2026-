import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/command_mapper.dart';

void main() {
  group('AndroidTvCommandMapper', () {
    test('maps every navigation and system key the protocol supports', () {
      expect(
        AndroidTvCommandMapper.supportedKeys[TvCommandKey.dpadUp],
        isNotNull,
      );
      expect(
        AndroidTvCommandMapper.supportedKeys[TvCommandKey.home],
        isNotNull,
      );
      expect(
        AndroidTvCommandMapper.supportedKeys[TvCommandKey.back],
        isNotNull,
      );
      expect(
        AndroidTvCommandMapper.supportedKeys[TvCommandKey.select],
        isNotNull,
      );
    });

    test(
      'flags color keys and voice as unsupported by the protocol itself',
      () {
        expect(
          AndroidTvCommandMapper.unsupportedByProtocol,
          contains(TvCommandKey.colorRed),
        );
        expect(
          AndroidTvCommandMapper.unsupportedByProtocol,
          contains(TvCommandKey.voiceStart),
        );
        expect(
          AndroidTvCommandMapper.supportedKeys.keys,
          isNot(contains(TvCommandKey.colorRed)),
        );
      },
    );

    test(
      'every supported key and every unsupported key together cover no overlap',
      () {
        final overlap = AndroidTvCommandMapper.supportedKeys.keys
            .toSet()
            .intersection(AndroidTvCommandMapper.unsupportedByProtocol);
        expect(overlap, isEmpty);
      },
    );
  });

  group('AndroidTvAppLinks', () {
    test('has entries for the common quick-app shortcuts', () {
      expect(AndroidTvAppLinks.byAppId['netflix'], isNotNull);
      expect(AndroidTvAppLinks.byAppId['youtube'], isNotNull);
    });
  });
}
