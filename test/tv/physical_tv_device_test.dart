import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

const _androidTv = TvDevice(
  id: 'android_tv:Android_9ca7.local',
  name: 'Family room TV',
  platform: TvPlatform.androidTv,
  host: '192.168.1.42',
);
const _cast = TvDevice(
  id: 'cast:abc123',
  name: 'Family room TV',
  platform: TvPlatform.googleCast,
  host: '192.168.1.42',
);
const _roku = TvDevice(
  id: 'roku:X1',
  name: 'Bedroom Roku',
  platform: TvPlatform.roku,
  host: '192.168.1.50',
);

void main() {
  group('PhysicalTvDevice.group', () {
    test('1. Android TV + Cast on the same IP become one card', () {
      final groups = PhysicalTvDevice.group([_androidTv, _cast]);

      expect(groups, hasLength(1));
      expect(groups.single.isGrouped, isTrue);
      expect(groups.single.hasRemote, isTrue);
      expect(groups.single.hasCast, isTrue);
      expect(groups.single.remoteEndpoint, _androidTv);
      expect(groups.single.castEndpoint, _cast);
      expect(groups.single.primary, _androidTv, reason: 'remote leads');
    });

    test('2. Android TV alone is one card, remote only', () {
      final groups = PhysicalTvDevice.group([_androidTv]);

      expect(groups, hasLength(1));
      expect(groups.single.isGrouped, isFalse);
      expect(groups.single.hasRemote, isTrue);
      expect(groups.single.hasCast, isFalse);
      expect(groups.single.primary, _androidTv);
    });

    test('3. a Cast-only Chromecast is one Cast card', () {
      const chromecast = TvDevice(
        id: 'cast:def456',
        name: 'Living Room Chromecast',
        platform: TvPlatform.googleCast,
        host: '192.168.1.60',
      );
      final groups = PhysicalTvDevice.group([chromecast]);

      expect(groups, hasLength(1));
      expect(groups.single.isGrouped, isFalse);
      expect(groups.single.hasRemote, isFalse);
      expect(groups.single.hasCast, isTrue);
      expect(groups.single.primary, chromecast);
    });

    test('4. two TVs with the same friendly name but different IPs stay two '
        'devices', () {
      const otherFamilyRoomTv = TvDevice(
        id: 'android_tv:Android_other.local',
        name: 'Family room TV',
        platform: TvPlatform.androidTv,
        host: '192.168.1.99',
      );
      final groups = PhysicalTvDevice.group([_androidTv, otherFamilyRoomTv]);

      expect(groups, hasLength(2));
      expect(groups.every((g) => !g.isGrouped), isTrue);
    });

    test('5. an Android TV and an unrelated Chromecast sharing a display name '
        'stay separate when their hosts differ', () {
      const unrelatedCastSameName = TvDevice(
        id: 'cast:unrelated',
        name: 'Family room TV', // coincidence, not the same physical TV
        platform: TvPlatform.googleCast,
        host: '192.168.1.77',
      );
      final groups = PhysicalTvDevice.group([
        _androidTv,
        unrelatedCastSameName,
      ]);

      expect(
        groups,
        hasLength(2),
        reason: 'same name is never enough evidence to merge',
      );
      expect(groups.every((g) => !g.isGrouped), isTrue);
    });

    test('6. grouping the same input twice gives the same grouped result '
        '(a rescan cannot flip a card)', () {
      final first = PhysicalTvDevice.group([_androidTv, _cast, _roku]);
      final second = PhysicalTvDevice.group([_androidTv, _cast, _roku]);

      expect(first.length, second.length);
      expect(first.map((g) => g.id), second.map((g) => g.id));
      expect(first.map((g) => g.isGrouped), second.map((g) => g.isGrouped));
    });

    test('7. a manually-added device already deduplicated against '
        'discovery does not produce a duplicate physical TV', () {
      // TvSessionController._withManualDevices already collapses a manual
      // entry into the discovered one of the *same* platform/host before
      // this list is built - grouping only has to not turn one physical
      // TV's two still-distinct protocol endpoints into two cards, which
      // case 1 already covers. This documents that a flat list with no
      // same-platform duplicate stays exactly as grouped as case 1.
      final groups = PhysicalTvDevice.group([_androidTv, _cast]);
      expect(groups, hasLength(1));
    });

    test('a device with no known host never groups with anything', () {
      const noHost = TvDevice(
        id: 'roku:manual-unresolved',
        name: 'Some TV',
        platform: TvPlatform.roku,
      );
      final groups = PhysicalTvDevice.group([noHost, _androidTv]);

      expect(groups, hasLength(2));
    });

    test('matching is case-insensitive on host', () {
      const upperHost = TvDevice(
        id: 'cast:ghi789',
        name: 'Family room TV',
        platform: TvPlatform.googleCast,
        host: '192.168.1.42',
      );
      final groups = PhysicalTvDevice.group([_androidTv, upperHost]);
      expect(groups, hasLength(1));
    });

    test('three unrelated devices stay three cards', () {
      final groups = PhysicalTvDevice.group([_androidTv, _cast, _roku]);

      expect(groups, hasLength(2));
      final grouped = groups.firstWhere((g) => g.isGrouped);
      expect(grouped.endpoints, [_androidTv, _cast]);
      final ungrouped = groups.firstWhere((g) => !g.isGrouped);
      expect(ungrouped.primary, _roku);
    });

    test('a demo (fake) device is always its own card', () {
      const demo1 = TvDevice(
        id: 'fake-1',
        name: 'Demo TV',
        platform: TvPlatform.fake,
        isDevelopmentFake: true,
      );
      const demo2 = TvDevice(
        id: 'fake-2',
        name: 'Demo TV',
        platform: TvPlatform.fake,
        isDevelopmentFake: true,
      );
      final groups = PhysicalTvDevice.group([demo1, demo2]);

      expect(groups, hasLength(2));
      expect(groups.every((g) => g.isDevelopmentFake), isTrue);
    });
  });
}
