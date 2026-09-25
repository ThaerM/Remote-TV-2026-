import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/remotemessage.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/transport/android_tv_message_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_android_tv_transport.dart';

const _fullFeatureSet = (1 << 0) | (1 << 1) | (1 << 5) | (1 << 6) | (1 << 9);

/// A TV that is already paired: every remote-port connect succeeds (while
/// [reachable]) and completes the configure -> start handshake.
class _PairedTv {
  bool reachable = true;
  final transports = <FakeAndroidTvTransport>[];
  int connectAttempts = 0;

  Future<AndroidTvMessageTransport> connect({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
    required Duration timeout,
  }) async {
    connectAttempts++;
    if (!reachable) {
      throw const DeviceNotReachableException('No route to host.');
    }
    late FakeAndroidTvTransport transport;
    transport = FakeAndroidTvTransport(
      onSend: (bytes) {
        final msg = RemoteMessage.fromBuffer(bytes);
        if (msg.hasRemoteConfigure()) {
          transport.receive(
            RemoteMessage(remoteSetActive: RemoteSetActive()).writeToBuffer(),
          );
          transport.receive(
            RemoteMessage(remoteStart: RemoteStart(started: true))
                .writeToBuffer(),
          );
        }
      },
    );
    transports.add(transport);
    scheduleMicrotask(
      () => transport.receive(
        RemoteMessage(
          remoteConfigure: RemoteConfigure(
            code1: _fullFeatureSet,
            deviceInfo: RemoteDeviceInfo(vendor: 'Google', model: 'Google TV'),
          ),
        ).writeToBuffer(),
      ),
    );
    return transport;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const device = TvDevice(
    id: 'android_tv:family-room',
    name: 'Family room TV',
    platform: TvPlatform.androidTv,
    host: '192.168.1.42',
  );

  late AndroidTvIdentity identity;

  setUpAll(() => identity = AndroidTvIdentity.generate());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AndroidTvPairedDeviceStore> pairedStore() async {
    final store = AndroidTvPairedDeviceStore(
      secureStore: InMemoryCredentialStore(),
    );
    await store.saveIdentity(device.id, identity);
    return store;
  }

  test('reconnect gives up after a bounded number of attempts', () async {
    final store = await pairedStore();
    fakeAsync((async) {
      final tv = _PairedTv();
      final provider = AndroidTvProvider(store: store, connect: tv.connect);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      provider.connect(device);
      async.flushMicrotasks();
      expect(states.last, TvConnectionState.connected);

      tv.reachable = false;
      tv.transports.single.closeWithError(const SocketTimeout());
      async.elapse(const Duration(minutes: 10));

      expect(states.last, TvConnectionState.error);
      expect(
        tv.connectAttempts,
        1 + AndroidTvProvider.maxReconnectAttempts,
        reason: 'one initial connect plus the bounded retries, no more',
      );

      final attemptsAtGiveUp = tv.connectAttempts;
      async.elapse(const Duration(hours: 1));
      expect(tv.connectAttempts, attemptsAtGiveUp);
      provider.dispose();
    });
  });

  test('reconnect succeeds when the TV comes back', () async {
    final store = await pairedStore();
    fakeAsync((async) {
      final tv = _PairedTv();
      final provider = AndroidTvProvider(store: store, connect: tv.connect);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      provider.connect(device);
      async.flushMicrotasks();
      tv.reachable = false;
      tv.transports.single.closeWithError(const SocketTimeout());
      async.elapse(const Duration(seconds: 4));
      expect(states.last, TvConnectionState.reconnecting);

      tv.reachable = true;
      async.elapse(const Duration(seconds: 30));
      expect(states.last, TvConnectionState.connected);
      provider.dispose();
    });
  });

  // Real async (not fakeAsync): closing a live transport awaits a
  // subscription cancel whose future fakeAsync never delivers.
  test('connecting again closes the previous socket without a reconnect '
      'loop', () async {
    final tv = _PairedTv();
    final provider = AndroidTvProvider(
      store: await pairedStore(),
      connect: tv.connect,
    );
    final states = <TvConnectionState>[];
    final sub = provider.connectionState.listen(states.add);

    await provider.connect(device);
    await provider.connect(device);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(tv.transports, hasLength(2));
    expect(tv.transports.first.closed, isTrue);
    expect(tv.transports.last.closed, isFalse);
    expect(states, isNot(contains(TvConnectionState.reconnecting)));
    expect(states.last, TvConnectionState.connected);

    await provider.disconnect();
    await sub.cancel();
    provider.dispose();
  });

  test('disconnect stops reconnect attempts', () async {
    final store = await pairedStore();
    fakeAsync((async) {
      final tv = _PairedTv();
      final provider = AndroidTvProvider(store: store, connect: tv.connect);

      provider.connect(device);
      async.flushMicrotasks();
      tv.reachable = false;
      tv.transports.single.closeWithError(const SocketTimeout());
      async.flushMicrotasks();
      provider.disconnect();
      async.flushMicrotasks();
      final attempts = tv.connectAttempts;
      async.elapse(const Duration(minutes: 5));

      expect(tv.connectAttempts, attempts);
      provider.dispose();
    });
  });
}

class SocketTimeout implements Exception {
  const SocketTimeout();
}
