import 'dart:async';
import 'dart:convert';

import 'package:remote_tv_2026/core/network/text_socket.dart';

class FakeTextSocket implements TextSocket {
  FakeTextSocket({this.onSend});

  void Function(String data)? onSend;
  final sent = <String>[];
  final _messages = StreamController<String>();
  final _done = Completer<void>();

  void emit(Map<String, Object?> message) => scheduleMicrotask(() {
    if (!_messages.isClosed) _messages.add(jsonEncode(message));
  });

  @override
  void send(String data) {
    sent.add(data);
    onSend?.call(data);
  }

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    unawaited(_messages.close());
  }
}

/// Scripted LG webOS SSAP endpoint (message shapes as aiowebostv sees
/// them from real TVs).
class FakeLgTv {
  FakeLgTv({this.acceptedKey = 'stored-key'});

  final String acceptedKey;
  final mainSockets = <FakeTextSocket>[];
  final inputSocket = FakeTextSocket();
  final requests = <Map<String, Object?>>[];
  var promptsShown = 0;
  FakeTextSocket? _pendingPrompt;

  FakeTextSocket openMain() {
    late final FakeTextSocket socket;
    socket = FakeTextSocket(onSend: (data) => _handle(socket, data));
    mainSockets.add(socket);
    return socket;
  }

  void _handle(FakeTextSocket socket, String data) {
    final message = jsonDecode(data) as Map<String, Object?>;
    final id = message['id'];
    switch (message['type']) {
      case 'hello':
        socket.emit({
          'type': 'hello',
          'id': id,
          'payload': {'deviceOS': 'webOS', 'deviceOSVersion': '6.0'},
        });
      case 'register':
        final payload = message['payload']! as Map;
        if (payload['client-key'] == acceptedKey) {
          socket.emit({
            'type': 'registered',
            'id': 'register_0',
            'payload': {'client-key': acceptedKey},
          });
        } else {
          promptsShown++;
          _pendingPrompt = socket;
          socket.emit({
            'type': 'response',
            'id': 'register_0',
            'payload': {'pairingType': 'PROMPT', 'returnValue': true},
          });
        }
      case 'request':
        requests.add(message);
        final uri = message['uri'];
        final response = switch (uri) {
          'ssap://com.webos.service.networkinput/getPointerInputSocket' => {
            'returnValue': true,
            'socketPath':
                'ws://10.0.0.8:3000/resources/abc/netinput.pointer.sock',
          },
          'ssap://com.webos.applicationManager/listLaunchPoints' => {
            'returnValue': true,
            'launchPoints': [
              {'id': 'netflix', 'title': 'Netflix'},
              {'id': 'youtube.leanback.v4', 'title': 'YouTube'},
            ],
          },
          'ssap://system/turnOff' => null,
          _ => {'returnValue': true},
        };
        if (response != null) {
          socket.emit({'type': 'response', 'id': id, 'payload': response});
        }
    }
  }

  /// The user presses "Allow" on the TV.
  void acceptPrompt() => _pendingPrompt?.emit({
    'type': 'registered',
    'id': 'register_0',
    'payload': {'client-key': 'new-key'},
  });

  /// The user presses "Deny" on the TV.
  void declinePrompt() => _pendingPrompt?.emit({
    'type': 'error',
    'id': 'register_0',
    'error': '403 User denied access',
  });
}
