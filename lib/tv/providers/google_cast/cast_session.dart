import 'dart:async';

import '../../domain/tv_domain.dart';
import 'cast_message.dart';
import 'cast_transport.dart';

class CastApplication {
  const CastApplication({
    required this.appId,
    required this.sessionId,
    required this.transportId,
    this.displayName,
    this.namespaces = const {},
  });

  final String appId;
  final String sessionId;
  final String transportId;
  final String? displayName;
  final Set<String> namespaces;

  bool get supportsMedia => namespaces.contains(CastConstants.nsMedia);
}

class CastReceiverStatus {
  const CastReceiverStatus({
    this.applications = const [],
    this.volumeLevel,
    this.muted = false,
    this.volumeFixed = false,
  });

  final List<CastApplication> applications;
  final double? volumeLevel;
  final bool muted;

  /// `controlType: fixed` - the device (e.g. a TV's built-in Cast) doesn't
  /// let senders change volume.
  final bool volumeFixed;

  static CastReceiverStatus parse(Map<String, Object?> status) {
    final volume = status['volume'];
    final apps = <CastApplication>[];
    for (final raw in (status['applications'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final appId = raw['appId'];
      final sessionId = raw['sessionId'];
      final transportId = raw['transportId'];
      if (appId is! String || sessionId is! String || transportId is! String) {
        continue;
      }
      apps.add(
        CastApplication(
          appId: appId,
          sessionId: sessionId,
          transportId: transportId,
          displayName: raw['displayName'] as String?,
          namespaces: {
            for (final ns in (raw['namespaces'] as List?) ?? const [])
              if (ns is Map && ns['name'] is String) ns['name'] as String,
          },
        ),
      );
    }
    return CastReceiverStatus(
      applications: apps,
      volumeLevel: volume is Map ? (volume['level'] as num?)?.toDouble() : null,
      muted: volume is Map && volume['muted'] == true,
      volumeFixed: volume is Map && volume['controlType'] == 'fixed',
    );
  }
}

/// Parsed `MEDIA_STATUS` entry plus the receiver's media session id.
class CastMediaStatus {
  const CastMediaStatus({required this.mediaSessionId, required this.status});

  final int mediaSessionId;
  final TvMediaStatus status;

  static CastMediaStatus? parse(Map<String, Object?> body) {
    final list = body['status'];
    if (list is! List || list.isEmpty || list.first is! Map) return null;
    final entry = list.first as Map;
    final id = entry['mediaSessionId'];
    if (id is! num) return null;
    final media = entry['media'];
    final metadata = media is Map ? media['metadata'] : null;
    final duration = media is Map ? media['duration'] as num? : null;
    final current = entry['currentTime'] as num? ?? 0;
    return CastMediaStatus(
      mediaSessionId: id.toInt(),
      status: TvMediaStatus(
        playerState: switch (entry['playerState']) {
          'PLAYING' => TvPlayerState.playing,
          'PAUSED' => TvPlayerState.paused,
          'BUFFERING' || 'LOADING' => TvPlayerState.buffering,
          _ => TvPlayerState.idle,
        },
        position: Duration(milliseconds: (current * 1000).round()),
        duration: duration == null || duration <= 0
            ? null
            : Duration(milliseconds: (duration * 1000).round()),
        title: metadata is Map ? metadata['title'] as String? : null,
        idleReason: entry['idleReason'] as String?,
      ),
    );
  }
}

/// One CASTV2 connection: virtual-connection handshake, heartbeat, and
/// request/response correlation by `requestId`. Everything is bounded:
/// each request has a timeout, and a device that goes silent for
/// [idleTimeout] closes the session (surfaced via [done]).
class CastSession {
  CastSession(
    this._transport, {
    this.requestTimeout = const Duration(seconds: 8),
    this.launchTimeout = const Duration(seconds: 20),
    this.heartbeatInterval = const Duration(seconds: 5),
    this.idleTimeout = const Duration(seconds: 15),
  });

  final CastTransport _transport;
  final Duration requestTimeout;
  final Duration launchTimeout;
  final Duration heartbeatInterval;
  final Duration idleTimeout;

  final _pending = <int, Completer<Map<String, Object?>>>{};
  final _receiverStatus = StreamController<CastReceiverStatus>.broadcast();
  final _mediaStatus = StreamController<CastMediaStatus?>.broadcast();
  final _connectedTransports = <String>{};
  StreamSubscription<CastMessage>? _sub;
  Timer? _heartbeat;
  Timer? _watchdog;
  var _nextRequestId = 1;
  var _closed = false;

  CastMediaStatus? lastMediaStatus;
  CastApplication? mediaApp;

  Stream<CastReceiverStatus> get receiverStatus => _receiverStatus.stream;
  Stream<CastMediaStatus?> get mediaStatus => _mediaStatus.stream;
  Future<void> get done => _transport.done;

  void open() {
    _sub = _transport.messages.listen(_onMessage);
    unawaited(_transport.done.then((_) => _shutdown()));
    _connect(CastConstants.platformReceiverId);
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      _send(CastConstants.nsHeartbeat, CastConstants.platformReceiverId, {
        'type': 'PING',
      });
    });
    _resetWatchdog();
  }

  void _connect(String destination) {
    _send(CastConstants.nsConnection, destination, {
      'type': 'CONNECT',
      'userAgent': 'Remote TV 2026',
    });
  }

  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(idleTimeout, () => unawaited(close()));
  }

  void _send(String namespace, String destination, Map<String, Object?> body) {
    if (_closed) return;
    _transport.send(
      CastMessage.withJson(
        sourceId: CastConstants.senderId,
        destinationId: destination,
        namespace: namespace,
        body: body,
      ),
    );
  }

  Future<Map<String, Object?>> _request(
    String namespace,
    String destination,
    Map<String, Object?> body, {
    Duration? timeout,
  }) {
    if (_closed) {
      return Future.error(
        const ConnectionLostException('The Cast connection is closed.'),
      );
    }
    final id = _nextRequestId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _send(namespace, destination, {...body, 'requestId': id});
    return completer.future
        .timeout(
          timeout ?? requestTimeout,
          onTimeout: () => throw DeviceNotReachableException(
            'The Cast device did not answer ${body['type']}.',
          ),
        )
        .whenComplete(() => _pending.remove(id));
  }

  void _onMessage(CastMessage message) {
    _resetWatchdog();
    final body = message.json;
    final type = body['type'];

    if (message.namespace == CastConstants.nsHeartbeat) {
      if (type == 'PING') {
        _send(CastConstants.nsHeartbeat, message.sourceId, {'type': 'PONG'});
      }
      return;
    }
    if (message.namespace == CastConstants.nsConnection && type == 'CLOSE') {
      _connectedTransports.remove(message.sourceId);
      if (message.sourceId == CastConstants.platformReceiverId) {
        unawaited(close());
      }
      return;
    }
    if (type == 'RECEIVER_STATUS' && body['status'] is Map) {
      final status = CastReceiverStatus.parse(
        (body['status'] as Map).cast<String, Object?>(),
      );
      final app = mediaApp;
      if (app != null &&
          !status.applications.any((a) => a.sessionId == app.sessionId)) {
        // The media app was stopped (from the TV or another sender).
        mediaApp = null;
        lastMediaStatus = null;
        _mediaStatus.add(null);
      }
      _receiverStatus.add(status);
    }
    if (type == 'MEDIA_STATUS') {
      final media = CastMediaStatus.parse(body);
      lastMediaStatus = media;
      _mediaStatus.add(media);
    }

    final requestId = body['requestId'];
    if (requestId is num && requestId > 0) {
      final completer = _pending[requestId.toInt()];
      if (completer == null || completer.isCompleted) return;
      switch (type) {
        case 'LAUNCH_ERROR':
          completer.completeError(
            TvMediaSessionException(
              'The Cast device could not start the media player '
              '(${body['reason'] ?? 'unknown reason'}).',
            ),
          );
        case 'LOAD_FAILED' ||
            'LOAD_CANCELLED' ||
            'INVALID_REQUEST' ||
            'INVALID_PLAYER_STATE':
          completer.completeError(
            TvMediaSessionException(
              type == 'LOAD_FAILED'
                  ? 'The Cast device could not play this media. Check that '
                        'the link is a direct, publicly reachable media file.'
                  : 'The Cast device rejected the request ($type).',
            ),
          );
        default:
          completer.complete(body);
      }
    }
  }

  Future<CastReceiverStatus> getStatus() async {
    final body = await _request(
      CastConstants.nsReceiver,
      CastConstants.platformReceiverId,
      {'type': 'GET_STATUS'},
    );
    return CastReceiverStatus.parse(
      ((body['status'] as Map?) ?? const {}).cast<String, Object?>(),
    );
  }

  Future<void> setVolume({double? level, bool? muted}) async {
    await _request(CastConstants.nsReceiver, CastConstants.platformReceiverId, {
      'type': 'SET_VOLUME',
      'volume': {'level': ?level, 'muted': ?muted},
    });
  }

  /// Reuses [appId] if it's already running (e.g. a previous cast), else
  /// launches it, then opens a virtual connection to its transport.
  Future<CastApplication> ensureApp(String appId) async {
    var app = (await getStatus()).applications
        .where((a) => a.appId == appId)
        .firstOrNull;
    if (app == null) {
      final body = await _request(
        CastConstants.nsReceiver,
        CastConstants.platformReceiverId,
        {'type': 'LAUNCH', 'appId': appId},
        timeout: launchTimeout,
      );
      app = CastReceiverStatus.parse(
        ((body['status'] as Map?) ?? const {}).cast<String, Object?>(),
      ).applications.where((a) => a.appId == appId).firstOrNull;
      if (app == null) {
        throw const TvMediaSessionException(
          'The Cast device did not start the media player.',
        );
      }
    }
    if (_connectedTransports.add(app.transportId)) _connect(app.transportId);
    mediaApp = app;
    return app;
  }

  Future<CastMediaStatus> load(TvMediaItem item) async {
    final app = await ensureApp(CastConstants.defaultMediaReceiverAppId);
    final body = await _request(CastConstants.nsMedia, app.transportId, {
      'type': 'LOAD',
      'sessionId': app.sessionId,
      'autoplay': true,
      'currentTime': 0,
      'media': {
        'contentId': item.url.toString(),
        'contentUrl': item.url.toString(),
        'contentType': item.contentType,
        'streamType': item.isLive ? 'LIVE' : 'BUFFERED',
        'metadata': {'metadataType': 0, 'title': ?item.title},
      },
    }, timeout: launchTimeout);
    final status = CastMediaStatus.parse(body);
    if (status == null) {
      throw const TvMediaSessionException(
        'The Cast device accepted the media but reported no playback.',
      );
    }
    return status;
  }

  /// PLAY / PAUSE / STOP / SEEK against the current media session.
  Future<void> mediaCommand(String type, {Map<String, Object?>? extra}) async {
    final app = mediaApp;
    final media = lastMediaStatus;
    if (app == null || media == null) {
      throw const TvMediaSessionException(
        'Nothing is playing on this Cast device.',
      );
    }
    await _request(CastConstants.nsMedia, app.transportId, {
      'type': type,
      'mediaSessionId': media.mediaSessionId,
      ...?extra,
    });
  }

  Future<void> close() async {
    if (_closed) return;
    for (final transportId in _connectedTransports) {
      _send(CastConstants.nsConnection, transportId, {'type': 'CLOSE'});
    }
    _send(CastConstants.nsConnection, CastConstants.platformReceiverId, {
      'type': 'CLOSE',
    });
    _shutdown();
    await _transport.close();
  }

  void _shutdown() {
    if (_closed) return;
    _closed = true;
    _heartbeat?.cancel();
    _watchdog?.cancel();
    unawaited(_sub?.cancel());
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const ConnectionLostException('The Cast connection closed.'),
        );
      }
    }
    _pending.clear();
    unawaited(_receiverStatus.close());
    unawaited(_mediaStatus.close());
  }
}
