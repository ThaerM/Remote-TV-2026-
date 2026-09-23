import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_errors.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/generated/polo.pb.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/protocol/pairing_handshake.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';

import 'fake_android_tv_transport.dart';

/// Finds a code whose first byte does NOT match what
/// [AndroidTvPairingSecret.compute] would derive for it, so a mismatch
/// test is deterministic instead of relying on a 255/256 chance.
String _findMismatchingCode(
  RsaPublicKeyComponents client,
  RsaPublicKeyComponents server,
) {
  for (var candidate = 0; candidate < 0x1000000; candidate++) {
    final code = candidate.toRadixString(16).padLeft(6, '0').toUpperCase();
    try {
      AndroidTvPairingSecret.compute(
        client: client,
        server: server,
        pairingCode: code,
      );
    } on AndroidTvPairingSecretMismatch {
      return code;
    }
  }
  throw StateError('Could not find a mismatching code.');
}

OuterMessage _lastSent(FakeAndroidTvTransport transport) =>
    OuterMessage.fromBuffer(transport.sent.last);

void main() {
  group('PairingHandshake.start', () {
    test(
      'sends pairing_request and walks the ack/options/configuration exchange',
      () async {
        final transport = FakeAndroidTvTransport();
        final handshake = PairingHandshake(transport);

        final startFuture = handshake.start();
        await Future<void>.delayed(Duration.zero);

        expect(_lastSent(transport).hasPairingRequest(), isTrue);
        expect(_lastSent(transport).pairingRequest.serviceName, 'atvremote');

        transport.receive(
          OuterMessage(
            status: OuterMessage_Status.STATUS_OK,
            pairingRequestAck: PairingRequestAck(serverName: 'Living Room TV'),
          ).writeToBuffer(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(_lastSent(transport).hasOptions(), isTrue);
        expect(
          _lastSent(transport).options.inputEncodings.single.symbolLength,
          6,
        );

        transport.receive(
          OuterMessage(
            status: OuterMessage_Status.STATUS_OK,
            options: Options(preferredRole: Options_RoleType.ROLE_TYPE_INPUT),
          ).writeToBuffer(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(_lastSent(transport).hasConfiguration(), isTrue);

        transport.receive(
          OuterMessage(
            status: OuterMessage_Status.STATUS_OK,
            configurationAck: ConfigurationAck(),
          ).writeToBuffer(),
        );

        await expectLater(startFuture, completes);
        await handshake.dispose();
      },
    );

    test(
      'fails with PairingRejectedException when the TV returns a non-OK status',
      () async {
        final transport = FakeAndroidTvTransport();
        final handshake = PairingHandshake(transport);

        final startFuture = handshake.start();
        await Future<void>.delayed(Duration.zero);
        transport.receive(
          OuterMessage(status: OuterMessage_Status.STATUS_ERROR)
              .writeToBuffer(),
        );

        await expectLater(
          startFuture,
          throwsA(isA<PairingRejectedException>()),
        );
        await handshake.dispose();
      },
    );
  });

  group('PairingHandshake.submitCode', () {
    test('rejects a code that does not match the connection', () async {
      final transport = FakeAndroidTvTransport();
      final handshake = PairingHandshake(transport);
      final clientIdentity = AndroidTvIdentity.generate();
      final serverIdentity = AndroidTvIdentity.generate();
      final clientComponents = RsaPublicKeyComponents.fromCertificatePem(
        clientIdentity.certificatePem,
      );
      final serverComponents = RsaPublicKeyComponents.fromCertificatePem(
        serverIdentity.certificatePem,
      );
      final mismatchingCode = _findMismatchingCode(
        clientComponents,
        serverComponents,
      );

      await expectLater(
        handshake.submitCode(
          pairingCode: mismatchingCode,
          identity: clientIdentity,
          peerCertificatePem: serverIdentity.certificatePem,
        ),
        throwsA(isA<PairingRejectedException>()),
      );
      expect(transport.sent, isEmpty);
      await handshake.dispose();
    });
  });
}
