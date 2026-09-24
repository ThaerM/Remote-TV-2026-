import 'dart:async';
import 'dart:typed_data';

import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/transport/android_tv_message_transport.dart';

/// In-memory [AndroidTvMessageTransport] for tests: no sockets, no TLS.
/// The test drives it by calling [receive] to simulate an incoming
/// message and inspects [sent] to assert on outgoing ones.
///
/// [peerCertificatePem] defaults to a freshly generated self-signed
/// certificate, standing in for "the TV's certificate" so pairing-secret
/// tests have something realistic to hash without a real TLS handshake.
class FakeAndroidTvTransport implements AndroidTvMessageTransport {
  FakeAndroidTvTransport({String? peerCertificatePem, this.onSend})
    : peerCertificatePem =
          peerCertificatePem ?? AndroidTvIdentity.generate().certificatePem;

  final _messagesController = StreamController<Uint8List>();
  final _doneCompleter = Completer<Object?>();
  final List<Uint8List> sent = [];
  bool closed = false;

  /// Invoked synchronously from [send], letting a test react to an
  /// outgoing message (e.g. to script an auto-responder). [send] and
  /// [receive] are deliberately two separate one-way channels - looping
  /// [send] back into [messages] would make "what the code under test
  /// sent" indistinguishable from "what a test injects as incoming".
  final void Function(Uint8List messageBytes)? onSend;

  @override
  final String peerCertificatePem;

  @override
  Stream<Uint8List> get messages => _messagesController.stream;

  @override
  Future<Object?> get done => _doneCompleter.future;

  @override
  void send(Uint8List messageBytes) {
    sent.add(messageBytes);
    onSend?.call(messageBytes);
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_doneCompleter.isCompleted) _doneCompleter.complete(null);
    // Not awaited - matches TlsAndroidTvTransport.close(): a transport
    // nothing ever subscribed to `messages` (e.g. a superseded connect
    // attempt, discarded before a RemoteSession/PairingHandshake
    // attaches) would otherwise hang here forever.
    unawaited(_messagesController.close());
  }

  void receive(Uint8List messageBytes) {
    _messagesController.add(messageBytes);
  }

  Future<void> closeWithError(Object error) async {
    closed = true;
    if (!_doneCompleter.isCompleted) _doneCompleter.complete(error);
    unawaited(_messagesController.close());
  }
}
