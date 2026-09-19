import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../domain/tv_errors.dart';
import '../security/android_tv_identity.dart';
import 'android_tv_message_transport.dart';

/// Real [AndroidTvMessageTransport] backed by a `dart:io` [SecureSocket].
///
/// The Android TV Remote protocol has no certificate authority: both the
/// pairing and remote-control endpoints present a self-signed
/// certificate, and trust is established either by the pairing-code hash
/// (pairing port) or by having already paired and persisted the TV's
/// certificate (remote-control port - not yet cross-checked on
/// reconnect in this phase, see `docs/research/android-google-tv.md`).
///
/// This is why [SecurityContext.setTrustedCertificatesBytes] is not used
/// and the socket is connected with `onBadCertificate` accepting the
/// peer unconditionally - that is the protocol's actual trust model, not
/// a general TLS shortcut, and it is scoped to this one transport class.
/// See `docs/architecture/security.md`.
class TlsAndroidTvTransport implements AndroidTvMessageTransport {
  TlsAndroidTvTransport._(this._socket);

  final SecureSocket _socket;
  final _messagesController = StreamController<Uint8List>.broadcast();
  final _defragmenter = MessageDefragmenter();
  final _doneCompleter = Completer<Object?>();
  StreamSubscription<Uint8List>? _rawSub;

  static Future<TlsAndroidTvTransport> connect({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
    required Duration timeout,
  }) async {
    final context = SecurityContext(withTrustedRoots: false);
    context.useCertificateChainBytes(utf8.encode(identity.certificatePem));
    context.usePrivateKeyBytes(utf8.encode(identity.privateKeyPem));

    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        context: context,
        onBadCertificate: (_) => true,
        timeout: timeout,
      );
      final transport = TlsAndroidTvTransport._(socket);
      transport._listen();
      return transport;
    } on SocketException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the TV at $host:$port (${error.osError?.message ?? error.message}).',
      );
    } on TlsException catch (error) {
      throw AuthenticationFailedException(
        'TLS handshake with the TV failed: ${error.message}.',
      );
    } on TimeoutException {
      throw DeviceNotReachableException('Connecting to $host:$port timed out.');
    }
  }

  /// The peer certificate presented during the TLS handshake, wrapped as
  /// PEM. Needed during pairing to compute the pairing secret.
  String get peerCertificatePem {
    final der = _socket.peerCertificate?.der;
    if (der == null) {
      throw const ProtocolErrorException(
        'The TV did not present a certificate.',
      );
    }
    return derCertificateToPem(der);
  }

  void _listen() {
    _rawSub = _socket.listen(
      (chunk) {
        for (final message in _defragmenter.add(chunk)) {
          _messagesController.add(message);
        }
      },
      onError: (Object error) {
        if (!_doneCompleter.isCompleted) _doneCompleter.complete(error);
        unawaited(_messagesController.close());
      },
      onDone: () {
        if (!_doneCompleter.isCompleted) _doneCompleter.complete(null);
        unawaited(_messagesController.close());
      },
      cancelOnError: true,
    );
  }

  @override
  Stream<Uint8List> get messages => _messagesController.stream;

  @override
  Future<Object?> get done => _doneCompleter.future;

  @override
  void send(Uint8List messageBytes) {
    _socket.add(VarintFramer.encodeLength(messageBytes.length));
    _socket.add(messageBytes);
  }

  @override
  Future<void> close() async {
    await _rawSub?.cancel();
    if (!_doneCompleter.isCompleted) _doneCompleter.complete(null);
    await _messagesController.close();
    await _socket.close();
  }
}
