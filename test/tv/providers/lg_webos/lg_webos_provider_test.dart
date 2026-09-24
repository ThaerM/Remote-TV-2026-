import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/ssdp.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/lg_webos/lg_webos_provider.dart';

import '../../../core/fake_ssdp_transport.dart';
import 'fake_lg_tv.dart';

const _tv = TvDevice(
  id: 'lg:abc-123',
  name: 'Living Room LG',
  platform: TvPlatform.lgWebOs,
  host: '10.0.0.8',
);

const _description = '''<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:Basic:1</deviceType>
    <friendlyName>Living Room LG</friendlyName>
    <manufacturer>LG Electronics</manufacturer>
    <modelName>OLED55C1</modelName>
    <UDN>uuid:abc-123</UDN>
  </device>
</root>''';

({LgWebOsProvider provider, FakeLgTv tv, InMemoryCredentialStore store})
_setup({String? storedKey, FakeSsdpTransport? ssdp}) {
  final tv = FakeLgTv();
  final store = InMemoryCredentialStore();
  if (storedKey != null) {
    store.write(key: 'lg_webos.client_key.${_tv.id}', value: storedKey);
  }
  final provider = LgWebOsProvider(
    secureStore: store,
    ssdp: SsdpSearcher(transportFactory: () => ssdp ?? FakeSsdpTransport()),
    httpGet: (uri) async => uri.path == '/desc.xml' ? _description : null,
    openMainSocket: (host) async {
      if (host != '10.0.0.8') throw StateError('unreachable');
      return tv.openMain();
    },
    openInputSocket: (uri) async => tv.inputSocket,
    reconnectDelay: (_) => Duration.zero,
  );
  return (provider: provider, tv: tv, store: store);
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('discovery', () {
    test('names the TV from its UPnP description and keys it by UDN', () async {
      final (:provider, tv: _, store: _) = _setup(
        ssdp: FakeSsdpTransport(
          replies: [
            (
              ssdpReply(
                st: 'urn:lge-com:service:webos-second-screen:1',
                location: 'http://10.0.0.8:1086/desc.xml',
                usn: 'uuid:abc-123::urn:lge-com:service:webos-second-screen:1',
              ),
              '10.0.0.8',
            ),
          ],
        ),
      );

      final outcome = await provider.discover();

      expect(outcome.devices, [_tv.copyWith(iconKey: 'tv')]);
    });

    test('probeHost says hello without registering', () async {
      final (:provider, :tv, store: _) = _setup();

      expect(
        (await provider.probeHost('10.0.0.8'))?.platform,
        TvPlatform.lgWebOs,
      );
      expect(tv.promptsShown, 0);
      expect(await provider.probeHost('10.0.0.9'), isNull);
    });
  });

  group('pairing', () {
    test(
      'first connection: confirm on the TV, then the key is stored',
      () async {
        final (:provider, :tv, :store) = _setup();
        final states = <TvConnectionState>[];
        provider.connectionState.listen(states.add);

        final request = await provider.connect(_tv);
        await _flush();
        expect(request, isA<TvConfirmOnDevicePairingRequest>());
        expect(states.last, TvConnectionState.pairingRequired);

        tv.acceptPrompt();
        await _flush();

        expect(states.last, TvConnectionState.connected);
        expect(
          await store.read(key: 'lg_webos.client_key.${_tv.id}'),
          'new-key',
        );
      },
    );

    test('a stored key connects without a prompt', () async {
      final (:provider, :tv, store: _) = _setup(storedKey: 'stored-key');

      expect(await provider.connect(_tv), TvPairingRequest.none);
      expect(tv.promptsShown, 0);
      expect((await provider.getCapabilities()).dpad, isTrue);
    });

    test('declining on the TV ends in error and stores nothing', () async {
      final (:provider, :tv, :store) = _setup();
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      await provider.connect(_tv);
      tv.declinePrompt();
      await _flush();

      expect(states.last, TvConnectionState.error);
      expect(await store.read(key: 'lg_webos.client_key.${_tv.id}'), isNull);
    });

    test('forget removes the client key', () async {
      final (:provider, tv: _, :store) = _setup(storedKey: 'stored-key');

      await provider.forget(_tv.id);

      expect(await store.read(key: 'lg_webos.client_key.${_tv.id}'), isNull);
    });
  });

  group('commands', () {
    test('keys go to the input socket as webOS buttons', () async {
      final (:provider, :tv, store: _) = _setup(storedKey: 'stored-key');
      await provider.connect(_tv);

      await provider.sendCommand(const TvCommand.key(TvCommandKey.dpadUp));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.select));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.digit7));

      expect(tv.inputSocket.sent, [
        'type:button\nname:UP\n\n',
        'type:button\nname:ENTER\n\n',
        'type:button\nname:7\n\n',
      ]);
    });

    test('text, app launch and power use SSAP requests', () async {
      final (:provider, :tv, store: _) = _setup(storedKey: 'stored-key');
      await provider.connect(_tv);

      await provider.sendCommand(const TvCommand.text('stranger things'));
      await provider.sendCommand(const TvCommand.launchApp('netflix'));
      await provider.sendCommand(const TvCommand.key(TvCommandKey.power));
      await _flush();

      final uris = tv.requests.map((r) => r['uri']).toList();
      expect(
        uris,
        containsAllInOrder([
          'ssap://com.webos.service.ime/insertText',
          'ssap://system.launcher/launch',
          'ssap://system/turnOff',
        ]),
      );
      final insert = tv.requests.firstWhere(
        (r) => r['uri'] == 'ssap://com.webos.service.ime/insertText',
      );
      expect((insert['payload']! as Map)['text'], 'stranger things');
    });

    test('keys webOS lacks are rejected, not faked', () async {
      final (:provider, tv: _, store: _) = _setup(storedKey: 'stored-key');
      await provider.connect(_tv);

      expect(
        () =>
            provider.sendCommand(const TvCommand.key(TvCommandKey.inputSource)),
        throwsA(isA<UnsupportedTvCommandException>()),
      );
      expect(
        (await provider.getCapabilities()).allows(TvCommandKey.mediaNext),
        isFalse,
      );
    });

    test('apps come from launch points', () async {
      final (:provider, tv: _, store: _) = _setup(storedKey: 'stored-key');
      await provider.connect(_tv);

      expect(await provider.getApplications(), const [
        TvApplication(id: 'netflix', name: 'Netflix'),
        TvApplication(id: 'youtube.leanback.v4', name: 'YouTube'),
      ]);
    });
  });

  group('reconnect', () {
    test('a dropped socket re-registers with the stored key', () async {
      final (:provider, :tv, store: _) = _setup(storedKey: 'stored-key');
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_tv);

      await tv.mainSockets.first.close();
      await _flush();

      expect(states.sublist(states.length - 2), [
        TvConnectionState.reconnecting,
        TvConnectionState.connected,
      ]);
      expect(tv.promptsShown, 0);
    });

    test('a revoked key ends in error after one prompt, never loops', () async {
      final (:provider, :tv, :store) = _setup(storedKey: 'stored-key');
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_tv);
      await store.write(key: 'lg_webos.client_key.${_tv.id}', value: 'revoked');

      await tv.mainSockets.first.close();
      await _flush();

      expect(states.last, TvConnectionState.error);
      expect(tv.promptsShown, 1);
    });

    test('a user disconnect never reconnects', () async {
      final (:provider, tv: _, store: _) = _setup(storedKey: 'stored-key');
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);
      await provider.connect(_tv);

      await provider.disconnect();
      await _flush();

      expect(states.last, TvConnectionState.disconnected);
      expect(states, isNot(contains(TvConnectionState.reconnecting)));
    });
  });
}
