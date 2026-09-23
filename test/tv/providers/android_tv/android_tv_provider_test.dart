import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/polo.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/remotemessage.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart'
    show
        AndroidTvIdentity,
        AndroidTvPairingSecret,
        AndroidTvPairingSecretMismatch,
        RsaPublicKeyComponents;
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/transport/android_tv_message_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_android_tv_transport.dart';

const _fullFeatureSet = (1 << 0) | (1 << 1) | (1 << 5) | (1 << 6) | (1 << 9);

/// Auto-responds to pairing (ack -> options -> configuration_ack) and
/// remote (configure -> ack -> remote_start) messages the moment the
/// provider sends the previous step, so tests can drive
/// [AndroidTvProvider] the way a real TV's responses would, without a
/// socket.
class _ScriptedTransports {
  _ScriptedTransports({AndroidTvIdentity? peerIdentity})
    : peerIdentity = peerIdentity ?? AndroidTvIdentity.generate() {
    connect =
        ({
          required host,
          required port,
          required identity,
          required timeout,
        }) async {
          late FakeAndroidTvTransport transport;
          transport = FakeAndroidTvTransport(
            peerCertificatePem: this.peerIdentity.certificatePem,
            onSend: (bytes) => port == 6467
                ? _respondToPairing(transport, bytes)
                : _respondToRemote(transport, bytes),
          );
          transports.add(transport);
          if (port != 6467) {
            // The TV always speaks first with remote_configure.
            scheduleMicrotask(() => _sendRemoteConfigure(transport));
          }
          return transport;
        };
  }

  /// Stands in for "the TV's identity": its certificate is what
  /// [FakeAndroidTvTransport.peerCertificatePem] reports, so a test can
  /// compute the pairing code that will actually validate.
  final AndroidTvIdentity peerIdentity;
  final List<FakeAndroidTvTransport> transports = [];
  late final Future<AndroidTvMessageTransport> Function({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
    required Duration timeout,
  })
  connect;

  void _respondToPairing(FakeAndroidTvTransport transport, Uint8List raw) {
    final msg = OuterMessage.fromBuffer(raw);
    if (msg.hasPairingRequest()) {
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          pairingRequestAck: PairingRequestAck(serverName: 'Living Room TV'),
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
      transport.receive(
        OuterMessage(
          status: OuterMessage_Status.STATUS_OK,
          secretAck: SecretAck(),
        ).writeToBuffer(),
      );
    }
  }

  void _respondToRemote(FakeAndroidTvTransport transport, Uint8List raw) {
    final msg = RemoteMessage.fromBuffer(raw);
    if (msg.hasRemoteConfigure()) {
      transport.receive(
        RemoteMessage(remoteSetActive: RemoteSetActive()).writeToBuffer(),
      );
      transport.receive(
        RemoteMessage(remoteStart: RemoteStart(started: true)).writeToBuffer(),
      );
    }
  }

  void _sendRemoteConfigure(FakeAndroidTvTransport transport) {
    transport.receive(
      RemoteMessage(
        remoteConfigure: RemoteConfigure(
          code1: _fullFeatureSet,
          deviceInfo: RemoteDeviceInfo(vendor: 'Google', model: 'Google TV'),
        ),
      ).writeToBuffer(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const device = TvDevice(
    id: 'android_tv:192.168.1.42:6466',
    name: 'Living Room TV',
    platform: TvPlatform.androidTv,
    host: '192.168.1.42',
  );

  /// Brute-forces the 6-hex-digit code that will actually validate for
  /// this (client, server) certificate pair - mirroring what the real
  /// TV would compute and display.
  String findValidCode(AndroidTvIdentity client, AndroidTvIdentity server) {
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

  group('AndroidTvProvider first-time pairing', () {
    test('connect requests PIN pairing, submitPairingCode connects', () async {
      final clientIdentity = AndroidTvIdentity.generate();
      final serverIdentity = AndroidTvIdentity.generate();
      final scripted = _ScriptedTransports(peerIdentity: serverIdentity);
      final provider = AndroidTvProvider(
        store: AndroidTvPairedDeviceStore(
          secureStore: InMemoryCredentialStore(),
        ),
        connect: scripted.connect,
        generateIdentity: () => clientIdentity,
      );
      final states = <TvConnectionState>[];
      final sub = provider.connectionState.listen(states.add);

      final request = await provider.connect(device);

      expect(request, isA<TvPinPairingRequest>());
      expect((request as TvPinPairingRequest).expectedLength, 6);
      expect(states, contains(TvConnectionState.pairingRequired));

      final validCode = findValidCode(clientIdentity, serverIdentity);
      await provider.submitPairingCode(validCode);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, TvConnectionState.connected);

      final capabilities = await provider.getCapabilities();
      expect(capabilities.dpad, isTrue);
      expect(capabilities.volume, isTrue);
      expect(capabilities.launchApps, isTrue);

      await sub.cancel();
      provider.dispose();
    });

    test('a wrong pairing code is rejected without connecting', () async {
      final clientIdentity = AndroidTvIdentity.generate();
      final serverIdentity = AndroidTvIdentity.generate();
      final scripted = _ScriptedTransports(peerIdentity: serverIdentity);
      final provider = AndroidTvProvider(
        store: AndroidTvPairedDeviceStore(
          secureStore: InMemoryCredentialStore(),
        ),
        connect: scripted.connect,
        generateIdentity: () => clientIdentity,
      );

      await provider.connect(device);
      final validCode = findValidCode(clientIdentity, serverIdentity);
      // Corrupt the first byte, which must equal the hash's first byte -
      // this is a guaranteed mismatch, not a probabilistic one.
      final wrongFirstByte = validCode.startsWith('00') ? '01' : '00';
      final wrongCode = '$wrongFirstByte${validCode.substring(2)}';

      await expectLater(
        provider.submitPairingCode(wrongCode),
        throwsA(isA<TvException>()),
      );

      provider.dispose();
    });
  });

  group('AndroidTvProvider commands', () {
    test('sendCommand throws when not connected', () async {
      final scripted = _ScriptedTransports();
      final provider = AndroidTvProvider(
        store: AndroidTvPairedDeviceStore(
          secureStore: InMemoryCredentialStore(),
        ),
        connect: scripted.connect,
      );

      await expectLater(
        provider.sendCommand(const TvCommand.key(TvCommandKey.dpadUp)),
        throwsA(isA<TvNotConnectedException>()),
      );

      provider.dispose();
    });
  });

  group('AndroidTvProvider.forget', () {
    test('removes a paired device from storage', () async {
      final scripted = _ScriptedTransports();
      final store = AndroidTvPairedDeviceStore(
        secureStore: InMemoryCredentialStore(),
      );
      final provider = AndroidTvProvider(
        store: store,
        connect: scripted.connect,
      );
      final identity = AndroidTvIdentity.generate();
      await store.saveIdentity(device.id, identity);
      await store.saveMetadata(
        PairedAndroidTvMetadata(
          deviceId: device.id,
          name: device.name,
          lastKnownHost: device.host!,
          lastConnectedAt: DateTime.now(),
        ),
      );

      await provider.forget(device.id);

      expect(await store.loadIdentity(device.id), isNull);
      expect(await store.loadAll(), isEmpty);

      provider.dispose();
    });
  });
}
