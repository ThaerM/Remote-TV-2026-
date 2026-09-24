import 'dart:async';
import 'dart:io';

import '../../domain/tv_errors.dart';
import 'cast_message.dart';

/// Message-level connection to one Cast device, injectable for tests.
abstract interface class CastTransport {
  void send(CastMessage message);
  Stream<CastMessage> get messages;

  /// Completes when the connection closes, for any reason.
  Future<void> get done;
  Future<void> close();
}

/// TLS on port 8009 (or a group's advertised port).
///
/// Cast devices present certificates chained to Google's private device
/// CA, not a public root, so they're accepted without CA validation - the
/// same as every open-source sender. Sender-side device authentication
/// (the optional `deviceauth` challenge) isn't performed; the connection
/// is local-network only and carries no user credentials. Scoped to this
/// class; see `docs/architecture/security.md`.
class TlsCastTransport implements CastTransport {
  TlsCastTransport._(this._socket) {
    _socket.listen(
      (chunk) {
        try {
          for (final frame in _reader.add(chunk)) {
            final message = CastMessage.decode(frame);
            if (message != null) _messages.add(message);
          }
        } on FormatException {
          unawaited(close());
        }
      },
      onError: (Object _) => unawaited(close()),
      onDone: () => unawaited(close()),
      cancelOnError: true,
    );
  }

  static Future<TlsCastTransport> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        onBadCertificate: (_) => true,
        timeout: timeout,
      );
      return TlsCastTransport._(socket);
    } on SocketException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the Cast device at $host:$port '
        '(${error.osError?.message ?? error.message}).',
      );
    } on HandshakeException catch (error) {
      throw DeviceNotReachableException(
        'TLS handshake with the Cast device failed (${error.message}).',
      );
    } on TimeoutException {
      throw DeviceNotReachableException(
        'Connecting to the Cast device at $host:$port timed out.',
      );
    }
  }

  final SecureSocket _socket;
  final _reader = CastFrameReader();
  final _messages = StreamController<CastMessage>.broadcast();
  final _done = Completer<void>();

  @override
  void send(CastMessage message) => _socket.add(message.frame());

  @override
  Stream<CastMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    await _messages.close();
    _socket.destroy();
  }
}
