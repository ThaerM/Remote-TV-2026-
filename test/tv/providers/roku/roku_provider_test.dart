import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/ssdp.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/roku/roku_ecp_client.dart';
import 'package:remote_tv_2026/tv/providers/roku/roku_provider.dart';

import '../../../core/fake_ssdp_transport.dart';

const _playerInfo = '''<?xml version="1.0" encoding="UTF-8" ?>
<device-info>
  <udn>28001240-0000-1000-8000-d83134a0f1c1</udn>
  <serial-number>X01900AB1234</serial-number>
  <device-id>S00001234567</device-id>
  <model-name>Roku Express</model-name>
  <friendly-device-name>Bedroom Roku</friendly-device-name>
  <user-device-name>Bedroom Roku</user-device-name>
  <is-tv>false</is-tv>
  <supports-find-remote>false</supports-find-remote>
</device-info>''';

const _tvInfo = '''<device-info>
  <serial-number>YN00TV000001</serial-number>
  <model-name>TCL 55R635</model-name>
  <friendly-device-name>55&quot; TCL Roku TV</friendly-device-name>
  <user-device-name></user-device-name>
  <is-tv>true</is-tv>
</device-info>''';

const _apps = '''<apps>
  <app id="tvinput.hdmi1" type="tvin" version="1.0.0">HDMI 1</app>
  <app id="12" type="appl" version="5.1.98">Netflix</app>
  <app id="837" type="appl" version="2.21.9">YouTube</app>
  <app id="2285" type="appl" version="6.0.0">Hulu &amp; Live TV</app>
</apps>''';

/// Routes GET/POST paths to canned responses and records every request.
class _FakeHttp implements RokuHttpTransport {
  _FakeHttp(this.routes);

  final Map<String, Object> routes;
  final requests = <String>[];

  @override
  Future<RokuHttpResponse> get(Uri uri) => _handle('GET', uri);

  @override
  Future<RokuHttpResponse> post(Uri uri) => _handle('POST', uri);

  Future<RokuHttpResponse> _handle(String method, Uri uri) async {
    final key = '$method ${uri.host}${uri.path}';
    requests.add(key);
    final route = routes[key] ?? routes['$method *${uri.path}'];
    if (route is Exception) throw route;
    if (route is RokuHttpResponse) return route;
    if (route is String) return RokuHttpResponse(200, route);
    if (method == 'POST' && routes['POST *'] != null) {
      return RokuHttpResponse(200, '');
    }
    return const RokuHttpResponse(404, '');
  }
}

RokuProvider _provider(_FakeHttp http, {FakeSsdpTransport? ssdp}) {
  return RokuProvider(
    transport: http,
    ssdp: SsdpSearcher(transportFactory: () => ssdp ?? FakeSsdpTransport()),
    discoveryTimeout: const Duration(milliseconds: 300),
  );
}

const _player = TvDevice(
  id: 'roku:X01900AB1234',
  name: 'Bedroom Roku',
  platform: TvPlatform.roku,
  host: '10.0.0.5',
);

void main() {
  group('Roku ECP parsing', () {
    test('device-info: user name, serial, TV vs player', () {
      final player = RokuDeviceInfo.parse(_playerInfo)!;
      expect(player.name, 'Bedroom Roku');
      expect(player.serialNumber, 'X01900AB1234');
      expect(player.isTv, isFalse);

      final tv = RokuDeviceInfo.parse(_tvInfo)!;
      expect(tv.name, '55" TCL Roku TV', reason: 'empty user name falls back');
      expect(tv.isTv, isTrue);
    });

    test('device-info without a serial is rejected', () {
      expect(RokuDeviceInfo.parse('<device-info></device-info>'), isNull);
    });

    test('apps: only channels, entities decoded', () {
      expect(parseRokuApps(_apps), const [
        TvApplication(id: '12', name: 'Netflix'),
        TvApplication(id: '837', name: 'YouTube'),
        TvApplication(id: '2285', name: 'Hulu & Live TV'),
      ]);
    });
  });

  group('RokuProvider discovery', () {
    test('finds a Roku via SSDP and names it from device-info', () async {
      final http = _FakeHttp({'GET 10.0.0.5/query/device-info': _playerInfo});
      final provider = _provider(
        http,
        ssdp: FakeSsdpTransport(
          replies: [
            (
              ssdpReply(
                st: 'roku:ecp',
                location: 'http://10.0.0.5:8060/',
                usn: 'uuid:roku:ecp:X01900AB1234',
              ),
              '10.0.0.5',
            ),
          ],
        ),
      );

      final outcome = await provider.discover();

      expect(outcome.devices, [_player.copyWith(iconKey: 'streaming_player')]);
      expect(outcome.issues, isEmpty);
    });

    test(
      'still lists a Roku whose device-info fails, by SSDP serial',
      () async {
        final provider = _provider(
          _FakeHttp({}),
          ssdp: FakeSsdpTransport(
            replies: [
              (
                ssdpReply(
                  st: 'roku:ecp',
                  location: 'http://10.0.0.7:8060/',
                  usn: 'uuid:roku:ecp:ZZ999',
                ),
                '10.0.0.7',
              ),
            ],
          ),
        );

        final device = (await provider.discover()).devices.single;

        expect(device.id, 'roku:ZZ999');
        expect(device.name, 'Roku (10.0.0.7)');
      },
    );

    test(
      'an iOS-style refused multicast send becomes multicastRestricted',
      () async {
        final provider = _provider(
          _FakeHttp({}),
          ssdp: FakeSsdpTransport(
            sendError: const OSError('No route to host', 65),
          ),
        );

        final outcome = await provider.discover();

        expect(outcome.devices, isEmpty);
        expect(outcome.issues, {TvDiscoveryIssue.multicastRestricted});
      },
    );

    test('probeHost recognizes a Roku by its device-info', () async {
      final provider = _provider(
        _FakeHttp({'GET 10.0.0.5/query/device-info': _playerInfo}),
      );

      expect((await provider.probeHost('10.0.0.5'))?.id, 'roku:X01900AB1234');
      expect(await provider.probeHost('10.0.0.6'), isNull);
    });
  });

  group('RokuProvider session', () {
    test(
      'a player: navigation/media/keyboard/apps, no volume or power',
      () async {
        final provider = _provider(
          _FakeHttp({'GET 10.0.0.5/query/device-info': _playerInfo}),
        );

        expect(await provider.connect(_player), TvPairingRequest.none);
        final caps = await provider.getCapabilities();

        expect(caps.dpad && caps.keyboard && caps.mediaControls, isTrue);
        expect(caps.launchApps, isTrue);
        expect(caps.volume || caps.power || caps.channel, isFalse);
        expect(caps.allows(TvCommandKey.mediaNext), isFalse);
        expect(caps.allows(TvCommandKey.mediaPlay), isTrue);
      },
    );

    test('a Roku TV adds volume, mute, channel and power', () async {
      final provider = _provider(
        _FakeHttp({'GET 10.0.0.5/query/device-info': _tvInfo}),
      );

      await provider.connect(_player);
      final caps = await provider.getCapabilities();

      expect(caps.volume && caps.mute && caps.channel && caps.power, isTrue);
    });

    test('commands become ECP keypresses, text and launches', () async {
      final http = _FakeHttp({
        'GET 10.0.0.5/query/device-info': _tvInfo,
        'POST *': true,
      });
      final provider = _provider(http);
      await provider.connect(_player);

      await provider.sendCommand(const TvCommand.key(TvCommandKey.dpadUp));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.menu));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp));
      await provider.sendCommand(const TvCommand.text('a b'));
      await provider.sendCommand(const TvCommand.launchApp('12'));

      expect(http.requests.where((r) => r.startsWith('POST')), [
        'POST 10.0.0.5/keypress/Up',
        'POST 10.0.0.5/keypress/Info',
        'POST 10.0.0.5/keypress/VolumeUp',
        'POST 10.0.0.5/keypress/Lit_a',
        'POST 10.0.0.5/keypress/Lit_%20',
        'POST 10.0.0.5/keypress/Lit_b',
        'POST 10.0.0.5/launch/12',
      ]);
    });

    test('keys a Roku lacks are rejected, not faked', () async {
      final provider = _provider(
        _FakeHttp({'GET 10.0.0.5/query/device-info': _playerInfo}),
      );
      await provider.connect(_player);

      expect(
        () => provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp)),
        throwsA(isA<UnsupportedTvCommandException>()),
      );
      expect(
        () => provider.sendCommand(const TvCommand.key(TvCommandKey.digit5)),
        throwsA(isA<UnsupportedTvCommandException>()),
      );
    });

    test('apps come from /query/apps', () async {
      final provider = _provider(
        _FakeHttp({
          'GET 10.0.0.5/query/device-info': _playerInfo,
          'GET 10.0.0.5/query/apps': _apps,
        }),
      );
      await provider.connect(_player);

      expect(await provider.getApplications(), hasLength(3));
    });

    test('403 explains how to allow mobile control', () async {
      final provider = _provider(
        _FakeHttp({
          'GET 10.0.0.5/query/device-info': const RokuHttpResponse(403, ''),
        }),
      );
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      await expectLater(
        provider.connect(_player),
        throwsA(
          isA<AuthenticationFailedException>().having(
            (e) => e.message,
            'message',
            contains('Control by mobile apps'),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(states.last, TvConnectionState.error);
    });

    test('a dropped request recovers once and retries', () async {
      var failNext = true;
      final http = _RecoveringHttp(() {
        if (failNext) {
          failNext = false;
          throw const SocketException('reset');
        }
      });
      final provider = RokuProvider(
        transport: http,
        ssdp: SsdpSearcher(transportFactory: FakeSsdpTransport.new),
      );
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_player);

      await provider.sendCommand(const TvCommand.key(TvCommandKey.home));
      await Future<void>.delayed(Duration.zero);

      expect(http.posts, ['/keypress/Home']);
      expect(states, [
        TvConnectionState.connecting,
        TvConnectionState.connected,
        TvConnectionState.reconnecting,
        TvConnectionState.connected,
      ]);
    });

    test('an unreachable Roku ends in error instead of looping', () async {
      final http = _RecoveringHttp(() {}, alwaysFailAfterConnect: true);
      final provider = RokuProvider(
        transport: http,
        ssdp: SsdpSearcher(transportFactory: FakeSsdpTransport.new),
      );
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_player);

      await expectLater(
        provider.sendCommand(const TvCommand.key(TvCommandKey.home)),
        throwsA(isA<DeviceNotReachableException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(states.last, TvConnectionState.error);
    });
  });
}

/// device-info always answers (unless [alwaysFailAfterConnect]); the first
/// POST runs [beforePost], which may throw once.
class _RecoveringHttp implements RokuHttpTransport {
  _RecoveringHttp(this.beforePost, {this.alwaysFailAfterConnect = false});

  final void Function() beforePost;
  final bool alwaysFailAfterConnect;
  final posts = <String>[];
  var _connected = false;

  @override
  Future<RokuHttpResponse> get(Uri uri) async {
    if (_connected && alwaysFailAfterConnect) {
      throw const SocketException('down');
    }
    _connected = true;
    return const RokuHttpResponse(200, _playerInfo);
  }

  @override
  Future<RokuHttpResponse> post(Uri uri) async {
    if (alwaysFailAfterConnect) throw const SocketException('down');
    beforePost();
    posts.add(uri.path);
    return const RokuHttpResponse(200, '');
  }
}
