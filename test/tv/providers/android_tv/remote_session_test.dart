import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/remotemessage.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/remote_session.dart';

import 'fake_android_tv_transport.dart';

RemoteMessage _lastSent(FakeAndroidTvTransport transport) =>
    RemoteMessage.fromBuffer(transport.sent.last);

/// Feature bits: PING|KEY|POWER|VOLUME|APP_LINK, matching what a fully
/// capable device would advertise.
const _fullFeatureSet = (1 << 0) | (1 << 1) | (1 << 5) | (1 << 6) | (1 << 9);

void main() {
  group('RemoteSession', () {
    test('negotiates features and completes `ready` on remote_start', () async {
      final transport = FakeAndroidTvTransport();
      final session = RemoteSession(transport);

      transport.receive(
        RemoteMessage(
          remoteConfigure: RemoteConfigure(
            code1: _fullFeatureSet,
            deviceInfo: RemoteDeviceInfo(vendor: 'Google', model: 'Google TV'),
          ),
        ).writeToBuffer(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(_lastSent(transport).hasRemoteConfigure(), isTrue);
      expect(_lastSent(transport).remoteConfigure.code1, _fullFeatureSet);

      transport.receive(
        RemoteMessage(remoteSetActive: RemoteSetActive()).writeToBuffer(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(_lastSent(transport).hasRemoteSetActive(), isTrue);

      transport.receive(
        RemoteMessage(remoteStart: RemoteStart(started: true)).writeToBuffer(),
      );

      await expectLater(session.ready, completes);
      expect(session.deviceInfo?.model, 'Google TV');
      expect(session.supportsVolume, isTrue);
      expect(session.supportsPower, isTrue);
      expect(session.supportsAppLink, isTrue);

      await session.dispose();
    });

    test('answers ping requests with the same val1', () async {
      final transport = FakeAndroidTvTransport();
      final session = RemoteSession(transport);

      transport.receive(
        RemoteMessage(remotePingRequest: RemotePingRequest(val1: 42))
            .writeToBuffer(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(_lastSent(transport).hasRemotePingResponse(), isTrue);
      expect(_lastSent(transport).remotePingResponse.val1, 42);

      await session.dispose();
    });

    test('sendKey injects the given key code and direction', () async {
      final transport = FakeAndroidTvTransport();
      final session = RemoteSession(transport);

      session.sendKey(RemoteKeyCode.KEYCODE_DPAD_UP);

      expect(
        _lastSent(transport).remoteKeyInject.keyCode,
        RemoteKeyCode.KEYCODE_DPAD_UP,
      );
      expect(
        _lastSent(transport).remoteKeyInject.direction,
        RemoteDirection.SHORT,
      );

      await session.dispose();
    });

    test('surfaces volume updates from remote_set_volume_level', () async {
      final transport = FakeAndroidTvTransport();
      final session = RemoteSession(transport);
      final volumeUpdates = <({int level, int max, bool muted})>[];
      final sub = session.volumeUpdates.listen(volumeUpdates.add);

      transport.receive(
        RemoteMessage(
          remoteSetVolumeLevel: RemoteSetVolumeLevel(
            volumeLevel: 8,
            volumeMax: 20,
            volumeMuted: false,
          ),
        ).writeToBuffer(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(volumeUpdates, hasLength(1));
      expect(volumeUpdates.single.level, 8);
      expect(volumeUpdates.single.max, 20);

      await sub.cancel();
      await session.dispose();
    });
  });
}
