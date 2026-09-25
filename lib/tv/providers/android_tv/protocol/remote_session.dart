import 'dart:async';
import 'dart:typed_data';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_errors.dart';
import '../android_tv_constants.dart';
import '../transport/android_tv_message_transport.dart';
import 'generated/remotemessage.pb.dart';

/// Feature bits negotiated with the TV in `remote_configure`, matching
/// the `androidtvremote2` reference client's `Feature` flags (Apache-2.0)
/// - see `docs/research/android-google-tv.md`. `IME` and `VOICE` are
/// requested as unsupported by this client: IME is used by the reference
/// client only to read back the current foreground app, which this phase
/// doesn't surface; voice is explicitly out of scope (see
/// docs/research/android-google-tv.md's "Voice" section).
abstract final class _Feature {
  static const int ping = 1 << 0;
  static const int key = 1 << 1;
  static const int power = 1 << 5;
  static const int volume = 1 << 6;
  static const int appLink = 1 << 9;

  static const int requested = ping | key | power | volume | appLink;
}

/// Information about the connected device, parsed from `remote_configure`.
class AndroidTvDeviceInfo {
  const AndroidTvDeviceInfo({required this.vendor, required this.model});

  final String vendor;
  final String model;
}

/// Drives the authenticated remote-control protocol
/// (`remotemessage.proto` / `RemoteMessage`) over an
/// [AndroidTvMessageTransport] on the remote-control port (6466), after
/// pairing has completed.
///
/// Reproduces the reference client's `remote_configure` negotiation,
/// idle-disconnect watchdog, and ping/pong keep-alive (the TV pings
/// every ~5s and closes the connection after repeated silence) - see
/// `docs/research/android-google-tv.md`.
class RemoteSession {
  RemoteSession(this._transport)
    : _logger = AppLogger('TV.Connection.AndroidTV') {
    _sub = _transport.messages.listen(
      _handleMessage,
      onDone: () {
        _resetIdleWatchdog(cancelOnly: true);
        if (!_startedCompleter.isCompleted) {
          _startedCompleter.completeError(
            const ConnectionLostException(
              'Connection to the TV closed before it became ready.',
            ),
          );
        }
      },
    );
    _resetIdleWatchdog();
  }

  final AndroidTvMessageTransport _transport;
  final AppLogger _logger;
  late final StreamSubscription<Uint8List> _sub;
  Timer? _idleTimer;

  final _startedCompleter = Completer<void>();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _volumeController =
      StreamController<({int level, int max, bool muted})>.broadcast();

  int _negotiatedFeatures = 0;
  AndroidTvDeviceInfo? deviceInfo;
  bool isOn = false;

  /// Completes once `remote_start` is received (the TV is ready to
  /// accept commands).
  Future<void> get ready => _startedCompleter.future;

  /// Emits `true`/`false` power state updates from `remote_start`.
  Stream<bool> get powerState => _connectionStateController.stream;

  Stream<({int level, int max, bool muted})> get volumeUpdates =>
      _volumeController.stream;

  bool get supportsVolume => _negotiatedFeatures & _Feature.volume != 0;
  bool get supportsPower => _negotiatedFeatures & _Feature.power != 0;
  bool get supportsAppLink => _negotiatedFeatures & _Feature.appLink != 0;

  void sendKey(
    RemoteKeyCode keyCode, {
    RemoteDirection direction = RemoteDirection.SHORT,
  }) {
    _resetIdleWatchdog();
    final message = RemoteMessage(
      remoteKeyInject: RemoteKeyInject(keyCode: keyCode, direction: direction),
    );
    _send(
      message,
      log: '[TV][COMMAND][ANDROID_TV] ${keyCode.name} ${direction.name}',
    );
  }

  void sendAppLink(String appLink) {
    _resetIdleWatchdog();
    final message = RemoteMessage(
      remoteAppLinkLaunchRequest: RemoteAppLinkLaunchRequest(appLink: appLink),
    );
    _send(message, log: '[TV][COMMAND][ANDROID_TV] launch_app_link');
  }

  void sendText(String text) {
    if (text.isEmpty) return;
    _resetIdleWatchdog();
    final lastIndex = text.length - 1;
    final message = RemoteMessage(
      remoteImeBatchEdit: RemoteImeBatchEdit(
        editInfo: [
          RemoteEditInfo(
            insert: 1,
            textFieldStatus: RemoteImeObject(
              start: lastIndex,
              end: lastIndex,
              value: text,
            ),
          ),
        ],
      ),
    );
    _send(message, log: '[TV][COMMAND][ANDROID_TV] text_input');
  }

  void _handleMessage(Uint8List raw) {
    _resetIdleWatchdog();
    final RemoteMessage incoming;
    try {
      incoming = RemoteMessage.fromBuffer(raw);
    } catch (error) {
      _logger.warning(
        '[TV][CONNECTION][ANDROID_TV] could not parse message type=${error.runtimeType}',
      );
      return;
    }

    if (incoming.hasRemoteConfigure()) {
      final cfg = incoming.remoteConfigure;
      deviceInfo = AndroidTvDeviceInfo(
        vendor: cfg.deviceInfo.vendor,
        model: cfg.deviceInfo.model,
      );
      _negotiatedFeatures = _Feature.requested & cfg.code1;
      _logger.info(
        '[TV][CONNECTION][ANDROID_TV] configured device=${deviceInfo!.model}',
      );
      final reply = RemoteMessage(
        remoteConfigure: RemoteConfigure(
          code1: _negotiatedFeatures,
          deviceInfo: RemoteDeviceInfo(
            unknown1: 1,
            unknown2: '1',
            packageName: 'remotetv2026',
            appVersion: '1.0.0',
          ),
        ),
      );
      _send(reply, log: null);
      return;
    }

    if (incoming.hasRemoteSetActive()) {
      _send(
        RemoteMessage(
          remoteSetActive: RemoteSetActive(active: _negotiatedFeatures),
        ),
        log: null,
      );
      return;
    }

    if (incoming.hasRemoteSetVolumeLevel()) {
      final v = incoming.remoteSetVolumeLevel;
      _volumeController.add((
        level: v.volumeLevel,
        max: v.volumeMax,
        muted: v.volumeMuted,
      ));
      return;
    }

    if (incoming.hasRemoteStart()) {
      isOn = incoming.remoteStart.started;
      _connectionStateController.add(isOn);
      if (!_startedCompleter.isCompleted) _startedCompleter.complete();
      return;
    }

    if (incoming.hasRemotePingRequest()) {
      _send(
        RemoteMessage(
          remotePingResponse: RemotePingResponse(
            val1: incoming.remotePingRequest.val1,
          ),
        ),
        log: null,
      );
      return;
    }

    if (incoming.hasRemoteError()) {
      _logger.warning('[TV][CONNECTION][ANDROID_TV] device reported an error');
      return;
    }
  }

  void _send(RemoteMessage message, {String? log}) {
    if (log != null) _logger.info(log);
    _transport.send(Uint8List.fromList(message.writeToBuffer()));
  }

  /// The reference server pings every ~5s and drops idle connections
  /// around 16s of silence; disconnecting ourselves at that point is
  /// deliberate, not a bug - see `AndroidTvConstants.idleDisconnectAfter`.
  void _resetIdleWatchdog({bool cancelOnly = false}) {
    _idleTimer?.cancel();
    if (cancelOnly) return;
    _idleTimer = Timer(AndroidTvConstants.idleDisconnectAfter, () {
      _logger.info('[TV][CONNECTION][ANDROID_TV] closing idle connection');
      unawaited(_transport.close());
    });
  }

  Future<void> dispose() async {
    _idleTimer?.cancel();
    await _sub.cancel();
    await _connectionStateController.close();
    await _volumeController.close();
  }
}
