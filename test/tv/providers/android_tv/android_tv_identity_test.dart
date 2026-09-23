import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';

void main() {
  group('AndroidTvIdentity.generate', () {
    test('produces a usable self-signed certificate and key', () {
      final identity = AndroidTvIdentity.generate();

      expect(identity.certificatePem, contains('BEGIN CERTIFICATE'));
      expect(identity.privateKeyPem, contains('PRIVATE KEY'));
    });

    test(
      'RsaPublicKeyComponents can be extracted back out of the certificate',
      () {
        final identity = AndroidTvIdentity.generate();

        final components = RsaPublicKeyComponents.fromCertificatePem(
          identity.certificatePem,
        );

        expect(components.modulus.bitLength, greaterThanOrEqualTo(2040));
        expect(components.exponent, BigInt.from(65537));
      },
    );
  });

  group('AndroidTvPairingSecret.compute', () {
    // RSA key generation is slow enough that we generate once and reuse
    // across cases in this group instead of per-test.
    late RsaPublicKeyComponents client;
    late RsaPublicKeyComponents server;

    setUpAll(() {
      client = RsaPublicKeyComponents.fromCertificatePem(
        AndroidTvIdentity.generate().certificatePem,
      );
      server = RsaPublicKeyComponents.fromCertificatePem(
        AndroidTvIdentity.generate().certificatePem,
      );
    });

    /// Brute-forces a 6-hex-digit code whose SHA-256 hash (per the
    /// protocol) starts with the byte that code's own first 2 hex
    /// digits encode - mirroring what a real TV would display, since we
    /// have no oracle to ask for a code that will validate.
    String findValidCode() {
      for (var candidate = 0; candidate < 0x1000000; candidate++) {
        final code = candidate.toRadixString(16).padLeft(6, '0').toUpperCase();
        try {
          AndroidTvPairingSecret.compute(
            client: client,
            server: server,
            pairingCode: code,
          );
          return code;
        } on AndroidTvPairingSecretMismatch {
          continue;
        }
      }
      fail(
        'Could not find a valid pairing code in range - hash function may be wrong.',
      );
    }

    test('accepts a code whose hash matches and produces a 32-byte secret', () {
      final code = findValidCode();

      final secret = AndroidTvPairingSecret.compute(
        client: client,
        server: server,
        pairingCode: code,
      );

      expect(secret.bytes, hasLength(32));
    });

    test('rejects a code with a mismatching hash', () {
      final valid = findValidCode();
      // Corrupt just the first byte (the part that must equal the
      // digest's first byte) so the check is guaranteed to fail,
      // regardless of what the digest turns out to be.
      final wrongFirstByte = valid.startsWith('00') ? '01' : '00';
      final tampered = '$wrongFirstByte${valid.substring(2)}';

      expect(
        () => AndroidTvPairingSecret.compute(
          client: client,
          server: server,
          pairingCode: tampered,
        ),
        throwsA(isA<AndroidTvPairingSecretMismatch>()),
      );
    });

    test('rejects a code that is not 6 hex digits', () {
      expect(
        () => AndroidTvPairingSecret.compute(
          client: client,
          server: server,
          pairingCode: '123',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AndroidTvPairingSecret.compute(
          client: client,
          server: server,
          pairingCode: 'ZZZZZZ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
