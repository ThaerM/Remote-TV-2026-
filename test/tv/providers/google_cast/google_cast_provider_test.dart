import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/google_cast/cast_message.dart';
import 'package:remote_tv_2026/tv/providers/google_cast/cast_session.dart';
import 'package:remote_tv_2026/tv/providers/google_cast/google_cast_provider.dart';
import 'package:remote_tv_2026/tv/providers/shared/service_discovery/service_discovery.dart';

import 'fake_cast_device.dart';

class _ScanDiscovery implements ServiceDiscovery {
  _ScanDiscovery(this.scan);
  final ServiceDiscoveryScan scan;

  @override
  Future<ServiceDiscoveryScan> discover({Duration? timeout}) async => scan;
}

const _chromecast = TvDevice(
  id: 'cast:abc',
  name: 'Living Room TV',
  platform: TvPlatform.googleCast,
  host: '192.168.1.50',
);

final _video = TvMediaItem(
  url: Uri.parse('https://example.com/bbb.mp4'),
  contentType: 'video/mp4',
  title: 'Big Buck Bunny',
);

/// Hands out [devices] in order, one per connection attempt.
({GoogleCastProvider provider, List<FakeCastDevice> devices}) _setup(
  List<FakeCastDevice> devices,
) {
  final queue = [...devices];
  final provider = GoogleCastProvider(
    discovery: _ScanDiscovery(const ServiceDiscoveryScan([])),
    connector: (host, port) async {
      if (queue.isEmpty) throw const DeviceNotReachableException('gone');
      return queue.removeAt(0);
    },
    reconnectDelay: (_) => Duration.zero,
  );
  return (provider: provider, devices: devices);
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('discovery', () {
    test('names and identifies devices from their TXT record', () async {
      final provider = GoogleCastProvider(
        discovery: _ScanDiscovery(
          const ServiceDiscoveryScan([
            ServiceDiscoveryResult(
              id: 'Chromecast-Ultra-5f2c.local',
              name: 'Chromecast-Ultra-5f2c',
              host: '192.168.1.50',
              port: 8009,
              txt: {'fn': 'Living Room TV', 'id': 'abc', 'md': 'Chromecast'},
            ),
            ServiceDiscoveryResult(
              id: 'group.local',
              name: 'Google-Cast-Group-1',
              host: '192.168.1.51',
              port: 32187,
              txt: {'fn': 'Whole house', 'md': 'Google Cast Group'},
            ),
          ], issue: TvDiscoveryIssue.timedOut),
        ),
      );

      final outcome = await provider.discover();

      expect(outcome.devices.first, _chromecast.copyWith(iconKey: 'cast'));
      expect(outcome.devices.last.port, 32187, reason: 'groups use own port');
      expect(outcome.devices.last.iconKey, 'speaker_group');
      expect(outcome.issues, {TvDiscoveryIssue.timedOut});
    });

    test('probeHost recognizes a Cast receiver, and nothing else', () async {
      final (:provider, devices: _) = _setup([FakeCastDevice()]);

      expect(
        (await provider.probeHost('192.168.1.50'))?.platform,
        TvPlatform.googleCast,
      );
      expect(await provider.probeHost('192.168.1.99'), isNull);
    });
  });

  group('session', () {
    test('connects without pairing; casting, volume and playback', () async {
      final (:provider, devices: _) = _setup([FakeCastDevice()]);

      expect(await provider.connect(_chromecast), TvPairingRequest.none);
      final caps = await provider.getCapabilities();

      expect(caps.casting && caps.volume && caps.mute, isTrue);
      expect(caps.mediaControls, isTrue);
      expect(caps.dpad || caps.keyboard || caps.launchApps, isFalse);
      expect(caps.allows(TvCommandKey.mediaNext), isFalse);
    });

    test('a device with fixed volume offers no volume controls', () async {
      final (:provider, devices: _) = _setup([
        FakeCastDevice(volumeFixed: true),
      ]);
      await provider.connect(_chromecast);

      final caps = await provider.getCapabilities();

      expect(caps.volume || caps.mute, isFalse);
      expect(
        () => provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp)),
        throwsA(isA<UnsupportedTvCommandException>()),
      );
    });

    test('answers the device heartbeat', () async {
      final (:provider, :devices) = _setup([FakeCastDevice()]);
      await provider.connect(_chromecast);

      devices.single.emit(CastConstants.nsHeartbeat, 'receiver-0', {
        'type': 'PING',
      });
      await _flush();

      expect(
        devices.single.sentOn(CastConstants.nsHeartbeat).map((m) => m['type']),
        contains('PONG'),
      );
    });
  });

  group('casting', () {
    test(
      'launches the media receiver, connects to it and loads the URL',
      () async {
        final (:provider, :devices) = _setup([FakeCastDevice()]);
        final statuses = <TvMediaStatus?>[];
        provider.mediaStatus.listen(statuses.add);
        await provider.connect(_chromecast);

        await provider.castMedia(_video);
        await _flush();

        final device = devices.single;
        expect(
          device.sentTypes,
          containsAllInOrder(['LAUNCH', 'CONNECT', 'LOAD']),
        );
        final load = device.sentOn(CastConstants.nsMedia).single;
        final media = load['media'] as Map;
        expect(media['contentId'], 'https://example.com/bbb.mp4');
        expect(media['contentType'], 'video/mp4');
        expect(media['streamType'], 'BUFFERED');
        expect(device.sent.last.destinationId, 'transport-1');
        expect(statuses.last?.playerState, TvPlayerState.playing);
        expect(statuses.last?.duration, const Duration(minutes: 10));
      },
    );

    test('reuses a media receiver that is already running', () async {
      final (:provider, :devices) = _setup([
        FakeCastDevice(mediaAppRunning: true),
      ]);
      await provider.connect(_chromecast);

      await provider.castMedia(_video);

      expect(devices.single.sentTypes, isNot(contains('LAUNCH')));
    });

    test('play/pause toggles, and rewind/forward seek relative', () async {
      final (:provider, :devices) = _setup([FakeCastDevice()]);
      await provider.connect(_chromecast);
      await provider.castMedia(_video);
      await _flush();

      await provider.sendCommand(const TvCommand.key(TvCommandKey.mediaPlay));
      await _flush();
      expect(devices.single.playerState, 'PAUSED');

      await provider.sendCommand(const TvCommand.key(TvCommandKey.mediaPlay));
      await provider.sendCommand(
        const TvCommand.key(TvCommandKey.mediaForward),
      );
      expect(devices.single.currentTime, 30);
    });

    test('a failed load explains what went wrong', () async {
      final (:provider, devices: _) = _setup([FakeCastDevice(loadFails: true)]);
      await provider.connect(_chromecast);

      await expectLater(
        provider.castMedia(_video),
        throwsA(
          isA<TvMediaSessionException>().having(
            (e) => e.message,
            'message',
            contains('direct, publicly reachable media file'),
          ),
        ),
      );
    });

    test('rejects non-http links before contacting the device', () async {
      final (:provider, :devices) = _setup([FakeCastDevice()]);
      await provider.connect(_chromecast);
      final sentBefore = devices.single.sent.length;

      await expectLater(
        provider.castMedia(
          TvMediaItem(
            url: Uri.parse('file:///x.mp4'),
            contentType: 'video/mp4',
          ),
        ),
        throwsA(isA<TvMediaSessionException>()),
      );
      expect(devices.single.sent.length, sentBefore);
    });

    test(
      'playback commands with nothing playing are refused clearly',
      () async {
        final (:provider, devices: _) = _setup([FakeCastDevice()]);
        await provider.connect(_chromecast);

        await expectLater(
          provider.stopMedia(),
          throwsA(isA<TvMediaSessionException>()),
        );
      },
    );

    test('volume up steps by 5% and mute toggles', () async {
      final (:provider, :devices) = _setup([FakeCastDevice()]);
      await provider.connect(_chromecast);

      await provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp));
      await _flush();
      expect(devices.single.volume, closeTo(0.55, 1e-9));

      await provider.sendCommand(const TvCommand.key(TvCommandKey.mute));
      expect(devices.single.muted, isTrue);
    });
  });

  group('reconnect', () {
    test('a dropped connection reconnects with backoff', () async {
      final (:provider, :devices) = _setup([
        FakeCastDevice(),
        FakeCastDevice(),
      ]);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_chromecast);

      await devices.first.drop();
      await _flush();

      expect(states, [
        TvConnectionState.connecting,
        TvConnectionState.connected,
        TvConnectionState.reconnecting,
        TvConnectionState.connected,
      ]);
    });

    test('gives up after three attempts instead of looping', () async {
      final (:provider, :devices) = _setup([FakeCastDevice()]);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_chromecast);

      await devices.first.drop();
      await _flush();

      expect(states.last, TvConnectionState.error);
    });

    test('a user disconnect never reconnects', () async {
      final (:provider, :devices) = _setup([
        FakeCastDevice(),
        FakeCastDevice(),
      ]);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_chromecast);

      await provider.disconnect();
      await _flush();

      expect(states.last, TvConnectionState.disconnected);
      expect(states, isNot(contains(TvConnectionState.reconnecting)));
    });
  });

  group('CastSession', () {
    test('a silent device is dropped after the idle timeout', () async {
      final device = FakeCastDevice(answerRequests: false);
      final session = CastSession(
        device,
        heartbeatInterval: const Duration(milliseconds: 20),
        idleTimeout: const Duration(milliseconds: 80),
      )..open();

      await session.done.timeout(const Duration(seconds: 1));

      expect(
        device.sentOn(CastConstants.nsHeartbeat).map((m) => m['type']),
        contains('PING'),
      );
    });

    test('an unanswered request times out instead of hanging', () async {
      final session = CastSession(
        FakeCastDevice(answerRequests: false),
        requestTimeout: const Duration(milliseconds: 50),
      )..open();

      await expectLater(
        session.getStatus(),
        throwsA(isA<DeviceNotReachableException>()),
      );
      await session.close();
    });
  });
}
