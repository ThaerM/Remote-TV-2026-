import 'dart:async';
import 'dart:io';

/// A text-frame WebSocket, injectable so protocol code is testable without
/// a network.
abstract interface class TextSocket {
  void send(String data);
  Stream<String> get messages;

  /// Completes when the socket closes, for any reason.
  Future<void> get done;
  Future<void> close();
}

typedef TextSocketConnector = Future<TextSocket> Function(Uri uri);

/// `dart:io` [WebSocket]. TVs serve `wss://` with self-signed certificates
/// and no CA, so [allowSelfSigned] accepts them - callers opt in per
/// protocol, and only for a TV's local address.
class IoTextSocket implements TextSocket {
  IoTextSocket._(this._socket) {
    _socket.listen(
      (data) {
        if (data is String) _messages.add(data);
      },
      onError: (Object _) => unawaited(close()),
      onDone: () => unawaited(close()),
      cancelOnError: true,
    );
  }

  static Future<IoTextSocket> connect(
    Uri uri, {
    Duration timeout = const Duration(seconds: 6),
    bool allowSelfSigned = false,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    if (allowSelfSigned) {
      client.badCertificateCallback = (_, host, _) => host == uri.host;
    }
    final socket = await WebSocket.connect(
      uri.toString(),
      customClient: client,
    ).timeout(timeout);
    socket.pingInterval = const Duration(seconds: 10);
    return IoTextSocket._(socket);
  }

  final WebSocket _socket;
  final _messages = StreamController<String>.broadcast();
  final _done = Completer<void>();

  @override
  void send(String data) {
    if (!_done.isCompleted) _socket.add(data);
  }

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    await _messages.close();
    await _socket.close();
  }
}
