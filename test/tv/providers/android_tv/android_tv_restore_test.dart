// Regression tests for the saved-device restore/reconnect path: a device
// paired once must reconnect silently on every later launch, using the
// identity already in SecureCredentialStore, with no unbounded "Connecting…"
// and no pairing code unless the TV itself rejects that identity.
import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/polo.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/remotemessage.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/transport/android_tv_message_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_android_tv_transport.dart';

const _fullFeatureSet = (1 << 0) | (1 << 1) | (1 << 5) | (1 << 6) | (1 << 9);
const _pairingPort = 6467;

/// A scripted Android TV: has its own fixed identity (so pairing codes are
/// computable), tracks which client certificates it currently trusts, and
/// answers the pairing and remote-control protocols realistically enough
/// to drive [AndroidTvProvider] end to end without a real socket.
class _Tv {
  _Tv() : serverIdentity = AndroidTvIdentity.generate();

  final AndroidTvIdentity serverIdentity;
  final Set<String> trustedCertPems = {};

  bool reachable = true;
  bool hangRemote = false;

  /// When true, a remote-port connect returns a Future the test completes
  /// by hand (via [pendingRemote]) instead of resolving immediately -
  /// for simulating a slow connect that a later attempt supersedes.
  bool controlledRemote = false;
  final pendingRemote = <Completer<AndroidTvMessageTransport>>[];

  int pairingAttempts = 0;
  int remoteAttempts = 0;
  final remoteTransports = <FakeAndroidTvTransport>[];

  Future<AndroidTvMessageTransport> connect({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
    required Duration timeout,
  }) async {
    if (port == _pairingPort) {
      pairingAttempts++;
      if (!reachable) {
        throw const DeviceNotReachableException('No route to host.');
      }
      late FakeAndroidTvTransport transport;
      transport = FakeAndroidTvTransport(
        peerCertificatePem: serverIdentity.certificatePem,
        onSend: (bytes) => _respondToPairing(transport, bytes, identity),
      );
      return transport;
    }

    remoteAttempts++;
    if (hangRemote) {
      // Never completes - stands in for a stalled TLS handshake.
      return Completer<AndroidTvMessageTransport>().future;
    }
    if (!reachable) {
      throw const DeviceNotReachableException('No route to host.');
    }
    if (!trustedCertPems.contains(identity.certificatePem)) {
      throw const AuthenticationFailedException('Client rejected.');
    }
    if (controlledRemote) {
      final completer = Completer<AndroidTvMessageTransport>();
      pendingRemote.add(completer);
      return completer.future;
    }
    return _remoteTransport();
  }

  FakeAndroidTvTransport _remoteTransport() {
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
    remoteTransports.add(transport);
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

  void _respondToPairing(
    FakeAndroidTvTransport transport,
    Uint8List raw,
    AndroidTvIdentity clientIdentity,
  ) {
    final msg = OuterMessage.fromBuffer(raw);
    if (msg.hasPairingRequest()) {
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          pairingRequestAck: PairingRequestAck(serverName: 'Family room TV'),
        ).writeToBuffer(),
      );
    } else if (msg.hasOptions()) {
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          options: Options(),
        ).writeToBuffer(),
      );
    } else if (msg.hasConfiguration()) {
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          configurationAck: ConfigurationAck(),
        ).writeToBuffer(),
      );
    } else if (msg.hasSecret()) {
      // A real TV only reaches this step because the pairing-code hash
      // already matched, so accepting here and trusting the client
      // mirrors what actually pairs it.
      trustedCertPems.add(clientIdentity.certificatePem);
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          secretAck: SecretAck(),
        ).writeToBuffer(),
      );
    }
  }
}

/// Brute-forces the 6-hex-digit code that validates for this (client,
/// server) certificate pair, exactly as the real TV would compute and
/// display it.
String _validCodeFor(AndroidTvIdentity client, AndroidTvIdentity server) {
  final clientComponents = RsaPublicKeyComponents.fromCertificatePem(
    client.certificatePem,
  );
  final serverComponents = RsaPublicKeyComponents.fromCertificatePem(
    server.certificatePem,
  );
  for (var candidate = 0; candidate < 0x1000000; candidate++) {
    final code = candidate.toRadixString(16).padLeft(6, '0').toUpperCase();
    try {
      AndroidTvPairingSecret.compute(
        client: clientComponents,
        server: serverComponents,
        pairingCode: code,
      );
      return code;
    } on AndroidTvPairingSecretMismatch {
      continue;
    }
  }
  throw StateError('Could not find a valid pairing code.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const device = TvDevice(
    id: 'android_tv:family-room',
    name: 'Family room TV',
    platform: TvPlatform.androidTv,
    host: '192.168.1.42',
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Pairs [provider] with [tv] end to end and returns the identity it
  /// paired with.
  Future<AndroidTvIdentity> pair(
    AndroidTvProvider provider,
    _Tv tv,
    AndroidTvIdentity clientIdentity,
  ) async {
    final request = await provider.connect(device);
    expect(request, isA<TvPinPairingRequest>());
    final code = _validCodeFor(clientIdentity, tv.serverIdentity);
    await provider.submitPairingCode(code);
    await Future<void>.delayed(Duration.zero);
    return clientIdentity;
  }

  test(
    '1. successful pairing stores the identity in SecureCredentialStore',
    () async {
      final secureStore = InMemoryCredentialStore();
      final store = AndroidTvPairedDeviceStore(secureStore: secureStore);
      final tv = _Tv();
      final clientIdentity = AndroidTvIdentity.generate();
      final provider = AndroidTvProvider(
        store: store,
        connect: tv.connect,
        generateIdentity: () => clientIdentity,
      );

      await pair(provider, tv, clientIdentity);

      final stored = await store.loadIdentity(device.id);
      expect(stored, isNotNull);
      expect(stored!.certificatePem, clientIdentity.certificatePem);
      final metadata = await store.loadAll();
      expect(metadata, hasLength(1));
      expect(metadata.single.lastKnownHost, device.host);
      provider.dispose();
    },
  );

  test('2/3. after an app restart (new provider, same stores), reconnect uses '
      'the stored identity - no pairing code', () async {
    final secureStore = InMemoryCredentialStore();
    final tv = _Tv();
    final clientIdentity = AndroidTvIdentity.generate();

    final store1 = AndroidTvPairedDeviceStore(secureStore: secureStore);
    final provider1 = AndroidTvProvider(
      store: store1,
      connect: tv.connect,
      generateIdentity: () => clientIdentity,
    );
    await pair(provider1, tv, clientIdentity);
    provider1.dispose();
    expect(tv.pairingAttempts, 1);
    expect(tv.remoteAttempts, 1);

    // "Restart": a fresh provider and a fresh store wrapper over the
    // same underlying secure storage and SharedPreferences backend.
    final store2 = AndroidTvPairedDeviceStore(secureStore: secureStore);
    final provider2 = AndroidTvProvider(
      store: store2,
      connect: tv.connect,
      generateIdentity: AndroidTvIdentity.generate,
    );

    final request = await provider2.connect(device);

    expect(request, isA<TvPairingRequest>());
    expect(request, isNot(isA<TvPinPairingRequest>()));
    expect(tv.pairingAttempts, 1, reason: 'no new pairing happened');
    expect(tv.remoteAttempts, 2);
    provider2.dispose();
  });

  test('4. reconnect does not request pairing again when the identity is '
      'still valid', () async {
    final secureStore = InMemoryCredentialStore();
    final store = AndroidTvPairedDeviceStore(secureStore: secureStore);
    final tv = _Tv();
    final clientIdentity = AndroidTvIdentity.generate();
    tv.trustedCertPems.add(clientIdentity.certificatePem);
    await store.saveIdentity(device.id, clientIdentity);

    final provider = AndroidTvProvider(store: store, connect: tv.connect);
    final request = await provider.connect(device);

    expect(request, TvPairingRequest.none);
    expect(tv.pairingAttempts, 0);
    expect(tv.remoteAttempts, 1);
    provider.dispose();
  });

  test('5. no saved identity goes straight to pairing required', () async {
    final store = AndroidTvPairedDeviceStore(
      secureStore: InMemoryCredentialStore(),
    );
    final tv = _Tv();
    final provider = AndroidTvProvider(store: store, connect: tv.connect);

    final request = await provider.connect(device);

    expect(request, isA<TvPinPairingRequest>());
    expect(tv.remoteAttempts, 0, reason: 'no point trying an unpaired host');
    expect(tv.pairingAttempts, 1);
    provider.dispose();
  });

  test('6. a rejected (stale) identity falls through to pairing required, '
      'never gets stuck', () async {
    final store = AndroidTvPairedDeviceStore(
      secureStore: InMemoryCredentialStore(),
    );
    final tv = _Tv(); // trusts nobody - as if it forgot every client
    final staleIdentity = AndroidTvIdentity.generate();
    await store.saveIdentity(device.id, staleIdentity);

    final provider = AndroidTvProvider(store: store, connect: tv.connect);
    final states = <TvConnectionState>[];
    provider.connectionState.listen(states.add);

    final request = await provider.connect(device);

    expect(request, isA<TvPinPairingRequest>());
    expect(tv.remoteAttempts, 1, reason: 'tried the stale identity once');
    expect(tv.pairingAttempts, 1);
    expect(states, contains(TvConnectionState.pairingRequired));
    provider.dispose();
  });

  test('7/8. a connect that never resolves times out and exits Connecting - '
      'the caller gets a real answer to build Retry/Back from', () {
    final store = AndroidTvPairedDeviceStore(
      secureStore: InMemoryCredentialStore(),
    );
    fakeAsync((async) {
      final tv = _Tv()..hangRemote = true;
      final clientIdentity = AndroidTvIdentity.generate();
      tv.trustedCertPems.add(clientIdentity.certificatePem);
      unawaited(store.saveIdentity(device.id, clientIdentity));
      async.flushMicrotasks();

      final provider = AndroidTvProvider(store: store, connect: tv.connect);
      final states = <TvConnectionState>[];
      provider.connectionState.listen(states.add);

      Object? error;
      provider.connect(device).catchError((Object e) {
        error = e;
        return TvPairingRequest.none;
      });
      async.elapse(const Duration(seconds: 30));

      expect(
        error,
        isNotNull,
        reason: 'the connect() call itself must resolve, not hang',
      );
      expect(states.last, TvConnectionState.error);
      expect(states, isNot(contains(TvConnectionState.connected)));
      provider.dispose();
    });
  });

  test('9. explicit disconnect does not start a reconnect', () async {
    // Already covered by
    // test/tv/providers/android_tv/android_tv_reconnect_test.dart's
    // "disconnect stops reconnect attempts" - kept out of this file to
    // avoid duplicating the same fakeAsync scenario.
  }, skip: 'covered by android_tv_reconnect_test.dart');

  test('11/12. rediscovering the same device at a new host (DHCP) updates the '
      'saved host without creating a duplicate entry', () async {
    final secureStore = InMemoryCredentialStore();
    final store = AndroidTvPairedDeviceStore(secureStore: secureStore);
    final tv = _Tv();
    final clientIdentity = AndroidTvIdentity.generate();
    final provider = AndroidTvProvider(
      store: store,
      connect: tv.connect,
      generateIdentity: () => clientIdentity,
    );
    await pair(provider, tv, clientIdentity);
    expect((await store.loadAll()).single.lastKnownHost, '192.168.1.42');

    // Rediscovered under a new IP - same stable id, different host.
    const rediscovered = TvDevice(
      id: 'android_tv:family-room',
      name: 'Family room TV',
      platform: TvPlatform.androidTv,
      host: '192.168.1.77',
    );
    await provider.connect(rediscovered);

    final all = await store.loadAll();
    expect(all, hasLength(1), reason: 'no duplicate saved device');
    expect(all.single.lastKnownHost, '192.168.1.77');
    provider.dispose();
  });

  test('13. switching to another device while a connect is still pending '
      'discards the superseded attempt instead of wiring it in', () async {
    final secureStore = InMemoryCredentialStore();
    final store = AndroidTvPairedDeviceStore(secureStore: secureStore);
    final tv = _Tv()..controlledRemote = true;
    final identityA = AndroidTvIdentity.generate();
    final identityB = AndroidTvIdentity.generate();
    tv.trustedCertPems.addAll([
      identityA.certificatePem,
      identityB.certificatePem,
    ]);
    const deviceA = TvDevice(
      id: 'android_tv:tv-a',
      name: 'TV A',
      platform: TvPlatform.androidTv,
      host: '192.168.1.10',
    );
    const deviceB = TvDevice(
      id: 'android_tv:tv-b',
      name: 'TV B',
      platform: TvPlatform.androidTv,
      host: '192.168.1.11',
    );
    await store.saveIdentity(deviceA.id, identityA);
    await store.saveIdentity(deviceB.id, identityB);

    final provider = AndroidTvProvider(store: store, connect: tv.connect);
    final states = <TvConnectionState>[];
    provider.connectionState.listen(states.add);

    final firstAttempt = provider.connect(deviceA);
    await Future<void>.delayed(Duration.zero);
    expect(tv.pendingRemote, hasLength(1));

    // The user switches to TV B before TV A's connect settles.
    final secondAttempt = provider.connect(deviceB);
    await Future<void>.delayed(Duration.zero);
    expect(tv.pendingRemote, hasLength(2));

    // TV B's transport resolves first, fully scripted so its `ready`
    // handshake actually completes...
    tv.pendingRemote[1].complete(tv._remoteTransport());
    // ...then TV A's late-arriving transport finally resolves too. It's
    // discarded before a RemoteSession is ever built for it, so it
    // doesn't need to be scripted - just closed.
    final staleTransport = FakeAndroidTvTransport();
    tv.pendingRemote[0].complete(staleTransport);

    await expectLater(
      firstAttempt,
      throwsA(isA<TvException>()),
      reason: 'the superseded attempt must not resolve successfully',
    );
    await secondAttempt;

    expect(
      staleTransport.closed,
      isTrue,
      reason: "TV A's abandoned socket must be closed, not left open",
    );
    provider.dispose();
  });
}
