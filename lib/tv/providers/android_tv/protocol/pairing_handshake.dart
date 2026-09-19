import 'dart:async';
import 'dart:typed_data';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_errors.dart';
import '../android_tv_constants.dart';
import '../security/android_tv_identity.dart';
import '../transport/android_tv_message_transport.dart';
import 'generated/polo.pb.dart';

/// Drives the certificate-pairing handshake (`polo.proto` /
/// `OuterMessage`) over an already-connected [AndroidTvMessageTransport]
/// on the pairing port (6467).
///
/// Reproduces, message-for-message, the exchange implemented by the
/// `androidtvremote2` reference client (Apache-2.0) - see
/// `docs/research/android-google-tv.md`:
///
/// ```
/// client -> pairing_request
/// server -> pairing_request_ack        (TV UI shows "pair with <client>")
/// client -> options
/// server -> options
/// client -> configuration
/// server -> configuration_ack          (TV now displays the 6-digit code)
/// [user reads code off the TV, calls submitCode]
/// client -> secret (sha256 hash)
/// server -> secret_ack                 (paired)
/// ```
class PairingHandshake {
  PairingHandshake(this._transport)
    : _logger = AppLogger('TV.Pairing.AndroidTV');

  final AndroidTvMessageTransport _transport;
  final AppLogger _logger;
  StreamSubscription<Uint8List>? _sub;

  Completer<void>? _awaitingConfigurationAck;
  Completer<void>? _awaitingSecretAck;

  /// Sends `pairing_request` and waits through the handshake until the
  /// TV acknowledges configuration - at which point it is displaying the
  /// pairing code on screen.
  Future<void> start() async {
    _sub = _transport.messages.listen(
      _handleMessage,
      onDone: () {
        _failPending(
          const PairingTimeoutException(
            'Connection to the TV closed during pairing.',
          ),
        );
      },
    );

    final request = OuterMessage()
      ..protocolVersion = 2
      ..status = OuterMessage_Status.STATUS_OK
      ..pairingRequest = (PairingRequest()
        ..serviceName = AndroidTvConstants.pairingServiceName
        ..clientName = AndroidTvConstants.clientName);

    _awaitingConfigurationAck = Completer<void>();
    _logger.info('[TV][PAIRING][ANDROID_TV] started');
    _send(request);

    await _awaitingConfigurationAck!.future.timeout(
      AndroidTvConstants.pairingTimeout,
      onTimeout: () => throw const PairingTimeoutException(
        'The TV did not respond to the pairing request in time.',
      ),
    );
  }

  /// Computes the pairing secret from [pairingCode] (as shown on the TV)
  /// using this client's [identity] and the TV's [peerCertificatePem],
  /// sends it, and waits for the TV to accept it.
  Future<void> submitCode({
    required String pairingCode,
    required AndroidTvIdentity identity,
    required String peerCertificatePem,
  }) async {
    final AndroidTvPairingSecret secret;
    try {
      secret = AndroidTvPairingSecret.compute(
        client: RsaPublicKeyComponents.fromCertificatePem(
          identity.certificatePem,
        ),
        server: RsaPublicKeyComponents.fromCertificatePem(peerCertificatePem),
        pairingCode: pairingCode,
      );
    } on AndroidTvPairingSecretMismatch catch (error) {
      throw PairingRejectedException(error.message);
    } on ArgumentError catch (error) {
      throw PairingRejectedException(error.message.toString());
    }

    final message = OuterMessage()
      ..protocolVersion = 2
      ..status = OuterMessage_Status.STATUS_OK
      ..secret = (Secret()..secret = secret.bytes);

    _awaitingSecretAck = Completer<void>();
    _send(message);

    await _awaitingSecretAck!.future.timeout(
      AndroidTvConstants.pairingTimeout,
      onTimeout: () => throw const PairingTimeoutException(
        'The TV did not confirm the pairing code in time.',
      ),
    );
    _logger.info('[TV][PAIRING][ANDROID_TV] completed');
  }

  void _handleMessage(Uint8List raw) {
    final OuterMessage incoming;
    try {
      incoming = OuterMessage.fromBuffer(raw);
    } catch (error) {
      _failPending(
        ProtocolErrorException('Could not parse a pairing message: $error'),
      );
      return;
    }

    if (incoming.status != OuterMessage_Status.STATUS_OK) {
      _failPending(
        PairingRejectedException(
          'The TV rejected pairing (status ${incoming.status}).',
        ),
      );
      return;
    }

    if (incoming.hasPairingRequestAck()) {
      final reply = OuterMessage()
        ..protocolVersion = 2
        ..status = OuterMessage_Status.STATUS_OK
        ..options = (Options()
          ..preferredRole = Options_RoleType.ROLE_TYPE_INPUT
          ..inputEncodings.add(
            Options_Encoding(
              type: Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL,
              symbolLength: AndroidTvConstants.pairingCodeLength,
            ),
          ));
      _send(reply);
      return;
    }

    if (incoming.hasOptions()) {
      final reply = OuterMessage()
        ..protocolVersion = 2
        ..status = OuterMessage_Status.STATUS_OK
        ..configuration = (Configuration()
          ..clientRole = Options_RoleType.ROLE_TYPE_INPUT
          ..encoding = Options_Encoding(
            type: Options_Encoding_EncodingType.ENCODING_TYPE_HEXADECIMAL,
            symbolLength: AndroidTvConstants.pairingCodeLength,
          ));
      _send(reply);
      return;
    }

    if (incoming.hasConfigurationAck()) {
      _awaitingConfigurationAck?.complete();
      return;
    }

    if (incoming.hasSecretAck()) {
      _awaitingSecretAck?.complete();
      return;
    }

    _logger.warning('[TV][PAIRING][ANDROID_TV] unhandled message');
  }

  void _send(OuterMessage message) {
    _transport.send(Uint8List.fromList(message.writeToBuffer()));
  }

  void _failPending(TvException error) {
    if (_awaitingConfigurationAck != null &&
        !_awaitingConfigurationAck!.isCompleted) {
      _awaitingConfigurationAck!.completeError(error);
    }
    if (_awaitingSecretAck != null && !_awaitingSecretAck!.isCompleted) {
      _awaitingSecretAck!.completeError(error);
    }
  }

  Future<void> dispose() => _sub?.cancel() ?? Future<void>.value();
}
