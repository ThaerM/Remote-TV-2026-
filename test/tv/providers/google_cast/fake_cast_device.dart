import 'dart:async';

import 'package:remote_tv_2026/tv/providers/google_cast/cast_message.dart';
import 'package:remote_tv_2026/tv/providers/google_cast/cast_transport.dart';

/// An in-memory Cast receiver that answers the requests a sender makes,
/// the way a real device does (message shapes from the CASTV2 protocol).
class FakeCastDevice implements CastTransport {
  FakeCastDevice({
    this.mediaAppRunning = false,
    this.volumeFixed = false,
    this.loadFails = false,
    this.answerRequests = true,
  });

  bool mediaAppRunning;
  final bool volumeFixed;
  final bool loadFails;
  final bool answerRequests;
  double volume = 0.5;
  bool muted = false;
  String playerState = 'IDLE';
  double currentTime = 0;

  final sent = <CastMessage>[];
  final _messages = StreamController<CastMessage>.broadcast();
  final _done = Completer<void>();

  List<Map<String, Object?>> sentOn(String namespace) => [
    for (final m in sent)
      if (m.namespace == namespace) m.json,
  ];

  List<String> get sentTypes => [for (final m in sent) '${m.json['type']}'];

  @override
  Stream<CastMessage> get messages => _messages.stream;

  @override
  Future<void> get done => _done.future;

  /// Simulates the device (or network) dropping the connection.
  Future<void> drop() => close();

  @override
  Future<void> close() async {
    if (_done.isCompleted) return;
    _done.complete();
    await _messages.close();
  }

  void emit(String namespace, String source, Map<String, Object?> body) {
    if (_done.isCompleted) return;
    scheduleMicrotask(() {
      if (_messages.isClosed) return;
      _messages.add(
        CastMessage.withJson(
          sourceId: source,
          destinationId: CastConstants.senderId,
          namespace: namespace,
          body: body,
        ),
      );
    });
  }

  Map<String, Object?> get _receiverStatus => {
    'applications': [
      if (mediaAppRunning)
        {
          'appId': CastConstants.defaultMediaReceiverAppId,
          'displayName': 'Default Media Receiver',
          'sessionId': 'session-1',
          'transportId': 'transport-1',
          'namespaces': [
            {'name': CastConstants.nsMedia},
          ],
        },
    ],
    'volume': {
      'controlType': volumeFixed ? 'fixed' : 'attenuation',
      'level': volume,
      'muted': muted,
    },
  };

  Map<String, Object?> _mediaStatus(Object? requestId) => {
    'type': 'MEDIA_STATUS',
    'requestId': requestId ?? 0,
    'status': [
      {
        'mediaSessionId': 7,
        'playerState': playerState,
        'currentTime': currentTime,
        'media': {
          'duration': 600,
          'metadata': {'title': 'Big Buck Bunny'},
        },
      },
    ],
  };

  @override
  void send(CastMessage message) {
    sent.add(message);
    final body = message.json;
    final requestId = body['requestId'];
    if (message.namespace == CastConstants.nsHeartbeat ||
        message.namespace == CastConstants.nsConnection ||
        !answerRequests) {
      return;
    }
    if (message.namespace == CastConstants.nsReceiver) {
      switch (body['type']) {
        case 'GET_STATUS':
          break;
        case 'LAUNCH':
          mediaAppRunning = true;
        case 'SET_VOLUME':
          final v = body['volume'] as Map;
          if (v['level'] is num) volume = (v['level'] as num).toDouble();
          if (v['muted'] is bool) muted = v['muted'] as bool;
      }
      emit(CastConstants.nsReceiver, CastConstants.platformReceiverId, {
        'type': 'RECEIVER_STATUS',
        'requestId': requestId,
        'status': _receiverStatus,
      });
      return;
    }
    if (message.namespace == CastConstants.nsMedia) {
      switch (body['type']) {
        case 'LOAD':
          if (loadFails) {
            emit(CastConstants.nsMedia, 'transport-1', {
              'type': 'LOAD_FAILED',
              'requestId': requestId,
            });
            return;
          }
          playerState = 'PLAYING';
        case 'PLAY':
          playerState = 'PLAYING';
        case 'PAUSE':
          playerState = 'PAUSED';
        case 'STOP':
          playerState = 'IDLE';
        case 'SEEK':
          currentTime = (body['currentTime'] as num).toDouble();
      }
      emit(CastConstants.nsMedia, 'transport-1', _mediaStatus(requestId));
    }
  }
}
