import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart' as crypto;

/// This client's persistent identity for the Android TV pairing protocol:
/// a self-signed RSA-2048 certificate/key pair.
///
/// The protocol does not use a certificate authority - the TV accepts
/// whatever self-signed certificate the client presents during the TLS
/// handshake, and trust is established out-of-band by both sides hashing
/// their public keys together with the pairing code the user reads off
/// the TV screen (see [computePairingSecret]). This is the actual trust
/// model of the protocol (matching the `androidtvremote2` reference
/// implementation), not a shortcut - see
/// `docs/architecture/security.md` and `docs/research/android-google-tv.md`.
///
/// The private key must never be logged and must only be persisted via
/// `SecureCredentialStore`.
class AndroidTvIdentity {
  const AndroidTvIdentity({
    required this.certificatePem,
    required this.privateKeyPem,
  });

  final String certificatePem;
  final String privateKeyPem;

  /// Generates a fresh self-signed identity. Called once per app install
  /// (or after a "forget device" reset) and then persisted - Android TV
  /// devices remember a client by its certificate, so reusing the same
  /// identity across pairings avoids needing to re-pair every device.
  static AndroidTvIdentity generate({String commonName = 'remotetv2026'}) {
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;

    final csrPem = X509Utils.generateRsaCsrPem(
      {'CN': commonName},
      privateKey,
      publicKey,
    );

    final certificatePem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csrPem,
      365 * 10,
      sans: [commonName],
    );

    return AndroidTvIdentity(
      certificatePem: certificatePem,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
    );
  }
}

/// Wraps raw DER certificate bytes (as reported by a TLS peer certificate)
/// into PEM so they can be parsed with the same certificate utilities
/// used for our own identity.
String derCertificateToPem(Uint8List derBytes) {
  final base64Body = base64.encode(derBytes);
  final lines = StringBuffer('-----BEGIN CERTIFICATE-----\n');
  for (var i = 0; i < base64Body.length; i += 64) {
    lines.writeln(
      base64Body.substring(
        i,
        i + 64 > base64Body.length ? base64Body.length : i + 64,
      ),
    );
  }
  lines.write('-----END CERTIFICATE-----\n');
  return lines.toString();
}

/// The (modulus, exponent) pair identifying an RSA public key for the
/// pairing secret computation below.
class RsaPublicKeyComponents {
  const RsaPublicKeyComponents(this.modulus, this.exponent);

  final BigInt modulus;
  final BigInt exponent;

  factory RsaPublicKeyComponents.fromCertificatePem(String pem) {
    final certificate = X509Utils.x509CertificateFromPem(pem);
    final spkiHex = certificate.tbsCertificate!.subjectPublicKeyInfo.bytes!;
    final spkiBytes = _hexStringToBytes(spkiHex);
    final key = CryptoUtils.rsaPublicKeyFromDERBytes(spkiBytes);
    return RsaPublicKeyComponents(key.modulus!, key.exponent!);
  }

  static Uint8List _hexStringToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}

/// Computes the SHA-256 pairing secret and validates it against the
/// 6-hex-digit code shown on the TV.
///
/// This reproduces, byte for byte, the hash the TV itself computes to
/// authenticate the pairing: SHA-256 over the uppercase-hex big-endian
/// encoding of (client modulus, client exponent, server modulus, server
/// exponent, and the last 4 hex digits of the pairing code), with the
/// resulting hash's first byte required to equal the pairing code's
/// first 2 hex digits (see the "Google TV Pairing Protocol" this
/// implements, sourced via `androidtvremote2`, Apache-2.0 - full
/// citation in `docs/research/android-google-tv.md`).
class AndroidTvPairingSecret {
  const AndroidTvPairingSecret._(this.bytes);

  final Uint8List bytes;

  static AndroidTvPairingSecret compute({
    required RsaPublicKeyComponents client,
    required RsaPublicKeyComponents server,
    required String pairingCode,
  }) {
    if (pairingCode.length != 6 || !_isHex(pairingCode)) {
      throw ArgumentError.value(
        pairingCode,
        'pairingCode',
        'Must be 6 hex digits.',
      );
    }

    final input = BytesBuilder()
      ..add(_bigIntToHexBytes(client.modulus))
      ..add(_bigIntToHexBytes(client.exponent, minHexDigits: 2))
      ..add(_bigIntToHexBytes(server.modulus))
      ..add(_bigIntToHexBytes(server.exponent, minHexDigits: 2))
      ..add(_hexToBytes(pairingCode.substring(2)));

    final digest = Uint8List.fromList(
      crypto.sha256.convert(input.toBytes()).bytes,
    );

    final expectedFirstByte = int.parse(pairingCode.substring(0, 2), radix: 16);
    if (digest[0] != expectedFirstByte) {
      throw AndroidTvPairingSecretMismatch(
        'The pairing code does not match this connection.',
      );
    }

    return AndroidTvPairingSecret._(digest);
  }

  static bool _isHex(String value) => RegExp(r'^[0-9a-fA-F]+$').hasMatch(value);

  /// Uppercase-hex big-endian encoding, left-padded with a leading zero
  /// byte's worth of hex if the natural hex length would be odd (RSA
  /// exponents like 65537 == 0x10001 need this; moduli of a full-size
  /// RSA key never do, since their top bit is always set).
  static Uint8List _bigIntToHexBytes(BigInt value, {int minHexDigits = 0}) {
    var hex = value.toRadixString(16).toUpperCase();
    if (hex.length < minHexDigits) {
      hex = hex.padLeft(minHexDigits, '0');
    }
    if (hex.length.isOdd) {
      hex = '0$hex';
    }
    return _hexToBytes(hex);
  }

  static Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}

/// Thrown when the computed pairing hash doesn't match what the TV
/// expects - almost always means the user mistyped the code shown on
/// screen.
class AndroidTvPairingSecretMismatch implements Exception {
  const AndroidTvPairingSecretMismatch(this.message);
  final String message;
}
