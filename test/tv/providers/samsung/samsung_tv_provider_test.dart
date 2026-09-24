import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/ssdp.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/samsung/samsung_tv_provider.dart';

import '../../../core/fake_ssdp_transport.dart';
import '../lg_webos/fake_lg_tv.dart' show FakeTextSocket;

const _info2020 = '''{
  "device": {
    "id": "uuid:1f5c-2020",
    "name": "[TV] Samsung Q80 Series (55)",
    "modelName": "QE55Q80TATXXU",
    "TokenAuthSupport": "true"
  },
  "id": "uuid:1f5c-2020",
  "name": "[TV] Samsung Q80 Series (55)"
}''';

const _info2017 = '''{
  "device": {"id": "uuid:old-2017", "name": "Samsung 6 Series", "TokenAuthSupport": "false"}
}''';

const _tv = TvDevice(
  id: 'samsung:1f5c-2020',
  name: '[TV] Samsung Q80 Series (55)',
  platform: TvPlatform.samsungTizen,
  host: '10.0.0.20',
);

/// Answers like a Tizen TV: [grant] decides what happens after the socket
/// opens - `token` (known/accepted), `deny`, or `prompt` (wait for the
/// test to call [allow]/[deny]).
class _FakeSamsung {
  _FakeSamsung({this.grant = 'token', this.info = _info2020, this.apps = true});

  String grant;
  final String info;
  final bool apps;
  final sockets = <FakeTextSocket>[];
  final uris = <Uri>[];

  FakeTextSocket open(Uri uri) {
    uris.add(uri);
    late final FakeTextSocket socket;
    socket = FakeTextSocket(
      onSend: (data) {
        final message = jsonDecode(data) as Map<String, Object?>;
        final params = message['params'] as Map?;
        if (apps && params?['event'] == 'ed.installedApp.get') {
          socket.emit({
            'event': 'ed.installedApp.get',
            'data': {
              'data': [
                {'appId': '3201907018807', 'name': 'Netflix', 'app_type': 2},
                {'appId': '111299001912', 'name': 'YouTube', 'app_type': 2},
              ],
            },
          });
        }
      },
    );
    sockets.add(socket);
    switch (grant) {
      case 'token':
        socket.emit({
          'event': 'ms.channel.connect',
          'data': {'token': '12345678'},
        });
      case 'deny':
        socket.emit({'event': 'ms.channel.unauthorized'});
    }
    return socket;
  }

  void allow() => sockets.last.emit({
    'event': 'ms.channel.connect',
    'data': {'token': '87654321'},
  });

  void deny() => sockets.last.emit({'event': 'ms.channel.unauthorized'});

  List<Map<String, Object?>> sentBy(int index) => [
    for (final raw in sockets[index].sent)
      jsonDecode(raw) as Map<String, Object?>,
  ];
}

({SamsungTvProvider provider, _FakeSamsung tv, InMemoryCredentialStore store})
_setup(_FakeSamsung tv, {String? storedToken, FakeSsdpTransport? ssdp}) {
  final store = InMemoryCredentialStore();
  if (storedToken != null) {
    store.write(key: 'samsung.token.${_tv.id}', value: storedToken);
  }
  final provider = SamsungTvProvider(
    secureStore: store,
    ssdp: SsdpSearcher(transportFactory: () => ssdp ?? FakeSsdpTransport()),
    httpGet: (uri) async =>
        uri.host == '10.0.0.20' && uri.path == '/api/v2/' ? tv.info : null,
    connectSocket: (uri) async => tv.open(uri),
    reconnectDelay: (_) => Duration.zero,
    connectGrace: const Duration(milliseconds: 50),
  );
  return (provider: provider, tv: tv, store: store);
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('discovery', () {
    test('lists Tizen TVs that answer /api/v2/, named by the TV', () async {
      final (:provider, tv: _, store: _) = _setup(
        _FakeSamsung(),
        ssdp: FakeSsdpTransport(
          replies: [
            (
              ssdpReply(
                st: 'urn:samsung.com:device:RemoteControlReceiver:1',
                location: 'http://10.0.0.20:7676/rcr/',
                usn: 'uuid:1f5c-2020::urn:samsung.com:device:RemoteControlReceiver:1',
              ),
              '10.0.0.20',
            ),
            (
              ssdpReply(
                st: 'urn:samsung.com:device:RemoteControlReceiver:1',
                location: 'http://10.0.0.21:7676/rcr/',
                usn: 'uuid:orsay-2014',
              ),
              '10.0.0.21',
            ),
          ],
        ),
      );

      final devices = (await provider.discover()).devices;

      expect(devices, [_tv.copyWith(iconKey: 'tv')]);
    });

    test('probeHost uses the REST device info', () async {
      final (:provider, tv: _, store: _) = _setup(_FakeSamsung());

      expect((await provider.probeHost('10.0.0.20'))?.id, _tv.id);
      expect(await provider.probeHost('10.0.0.99'), isNull);
    });
  });

  group('pairing', () {
    test(
      '2018+ TVs use wss:8002; the first time needs "Allow" on the TV',
      () async {
        final (:provider, :tv, :store) = _setup(_FakeSamsung(grant: 'prompt'));
        final states = <TvConnectionState>[];
        provider.connectionState.listen(states.add);

        final request = await provider.connect(_tv);
        await _flush();
        expect(request, isA<TvConfirmOnDevicePairingRequest>());
        expect(states.last, TvConnectionState.pairingRequired);
        final uri = tv.uris.single;
        expect(uri.scheme, 'wss');
        expect(uri.port, 8002);
        expect(uri.path, '/api/v2/channels/samsung.remote.control');
        expect(
          utf8.decode(base64.decode(uri.queryParameters['name']!)),
          'Remote TV 2026',
        );
        expect(uri.queryParameters.containsKey('token'), isFalse);

        tv.allow();
        await _flush();

        expect(states.last, TvConnectionState.connected);
        expect(await store.read(key: 'samsung.token.${_tv.id}'), '87654321');
      },
    );

    test('a stored token is sent and connects without a prompt', () async {
      final (:provider, :tv, store: _) = _setup(
        _FakeSamsung(),
        storedToken: '12345678',
      );

      expect(await provider.connect(_tv), TvPairingRequest.none);
      expect(tv.uris.single.queryParameters['token'], '12345678');
    });

    test('older TVs without token auth use plain ws:8001', () async {
      final (:provider, :tv, store: _) = _setup(_FakeSamsung(info: _info2017));

      await provider.connect(_tv);

      expect(tv.uris.single.scheme, 'ws');
      expect(tv.uris.single.port, 8001);
    });

    test('"Deny" on the TV ends in error with no token stored', () async {
      final (:provider, :tv, :store) = _setup(_FakeSamsung(grant: 'prompt'));
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      await provider.connect(_tv);
      tv.deny();
      await _flush();

      expect(states.last, TvConnectionState.error);
      expect(await store.read(key: 'samsung.token.${_tv.id}'), isNull);
    });
  });

  group('commands', () {
    test('keys are SendRemoteKey clicks', () async {
      final (:provider, :tv, store: _) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );
      await provider.connect(_tv);

      await provider.sendCommand(const TvCommand.key(TvCommandKey.back));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.inputSource));

      expect(tv.sentBy(0).map((m) => (m['params'] as Map)['DataOfCmd']), [
        'KEY_RETURN',
        'KEY_SOURCE',
      ]);
      expect((tv.sentBy(0).first['params'] as Map)['Cmd'], 'Click');
    });

    test('text is base64 SendInputString followed by SendInputEnd', () async {
      final (:provider, :tv, store: _) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );
      await provider.connect(_tv);

      await provider.sendCommand(const TvCommand.text('héllo'));

      final sent = tv.sentBy(0);
      final params = sent.first['params'] as Map;
      expect(params['TypeOfRemote'], 'SendInputString');
      expect(utf8.decode(base64.decode(params['Cmd'] as String)), 'héllo');
      expect((sent.last['params'] as Map)['TypeOfRemote'], 'SendInputEnd');
    });

    test(
      'apps come from ed.installedApp.get; launch uses the app type',
      () async {
        final (:provider, :tv, store: _) = _setup(
          _FakeSamsung(),
          storedToken: 't',
        );
        await provider.connect(_tv);

        final apps = await provider.getApplications();
        await provider.sendCommand(TvCommand.launchApp(apps.first.id));

        expect(apps.map((a) => a.name), ['Netflix', 'YouTube']);
        final launch = tv.sentBy(0).last['params'] as Map;
        expect(launch['event'], 'ed.apps.launch');
        expect((launch['data'] as Map)['action_type'], 'DEEP_LINK');
      },
    );

    test(
      'firmware that ignores the apps request yields an empty list',
      () async {
        final (:provider, tv: _, store: _) = _setup(
          _FakeSamsung(apps: false),
          storedToken: 't',
        );
        await provider.connect(_tv);

        expect(await provider.getApplications(), isEmpty);
      },
    );

    test('previous/next are not offered', () async {
      final (:provider, tv: _, store: _) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );
      await provider.connect(_tv);

      final caps = await provider.getCapabilities();
      expect(caps.allows(TvCommandKey.mediaNext), isFalse);
      expect(
        () => provider.sendCommand(const TvCommand.key(TvCommandKey.mediaNext)),
        throwsA(isA<UnsupportedTvCommandException>()),
      );
    });
  });

  group('reconnect', () {
    test('a dropped socket reconnects with the stored token', () async {
      final (:provider, :tv, store: _) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_tv);

      await tv.sockets.first.close();
      await _flush();

      expect(states.sublist(states.length - 2), [
        TvConnectionState.reconnecting,
        TvConnectionState.connected,
      ]);
    });

    test('a TV that would prompt again ends in error, bounded', () async {
      final (:provider, :tv, store: _) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_tv);
      tv.grant = 'prompt';

      await tv.sockets.first.close();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(states.last, TvConnectionState.error);
      expect(tv.sockets.length, lessThanOrEqualTo(4));
    });

    test('forget removes the token', () async {
      final (:provider, tv: _, :store) = _setup(
        _FakeSamsung(),
        storedToken: 't',
      );

      await provider.forget(_tv.id);

      expect(await store.read(key: 'samsung.token.${_tv.id}'), isNull);
    });
  });
}
