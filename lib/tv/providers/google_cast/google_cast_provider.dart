import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show max, min;

import '../../../core/logging/app_logger.dart';
import '../../domain/tv_domain.dart';
import '../shared/service_discovery/mdns_service_discovery.dart';
import '../shared/service_discovery/native_bonjour_service_discovery.dart';
import '../shared/service_discovery/service_discovery.dart';
import 'cast_message.dart';
import 'cast_session.dart';
import 'cast_transport.dart';

typedef CastConnector = Future<CastTransport> Function(String host, int port);

/// [TvProvider] + [TvMediaCaster] for Google Cast receivers (Chromecast,
/// Google TV / Android TV with Chromecast built-in, Cast-enabled TVs and
/// speakers, Cast groups), speaking CASTV2 directly - see
/// `docs/decisions/ADR-004-google-cast-castv2.md` for why this isn't the
/// native Cast SDK.
///
/// Cast is a media target, not a D-pad remote: capabilities are casting,
/// volume/mute (unless the device fixes volume) and playback controls for
/// what's playing. It never reports D-pad/keyboard/app-launch, and a TV
/// that's also an Android TV shows up separately under that provider for
/// remote control.
class GoogleCastProvider implements TvProvider, TvMediaCaster {
  GoogleCastProvider({
    ServiceDiscovery? discovery,
    CastConnector? connector,
    Duration Function(int attempt)? reconnectDelay,
  }) : _discovery = discovery ?? _defaultDiscovery(),
       _connector = connector ?? TlsCastTransport.connect,
       _reconnectDelay = reconnectDelay ?? _defaultReconnectDelay,
       _logger = AppLogger('TV.GoogleCast');

  static const _maxReconnectAttempts = 3;
  static const _volumeStep = 0.05;

  static ServiceDiscovery _defaultDiscovery() => Platform.isIOS
      ? NativeBonjourServiceDiscovery(
          serviceType: CastConstants.serviceType,
          logTag: 'GOOGLE_CAST',
        )
      : MdnsServiceDiscovery(
          serviceType: CastConstants.serviceType,
          logTag: 'GOOGLE_CAST',
          collectTxt: true,
        );

  static Duration _defaultReconnectDelay(int attempt) =>
      Duration(seconds: min(8, 1 << attempt));

  final ServiceDiscovery _discovery;
  final CastConnector _connector;
  final Duration Function(int attempt) _reconnectDelay;
  final AppLogger _logger;

  final _states = StreamController<TvConnectionState>.broadcast();
  final _media = StreamController<TvMediaStatus?>.broadcast();

  TvDevice? _device;
  CastSession? _session;
  CastReceiverStatus? _receiver;
  TvConnectionState _state = TvConnectionState.disconnected;
  var _userDisconnected = false;

  @override
  TvPlatform get platform => TvPlatform.googleCast;

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  @override
  Stream<TvMediaStatus?> get mediaStatus => _media.stream;

  void _setState(TvConnectionState state) {
    if (_state == state) return;
    _state = state;
    _logger.info('[TV][CAST][GOOGLE_CAST] state=${state.name}');
    _states.add(state);
  }

  // ---- Discovery -------------------------------------------------------

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final scan = await _discovery.discover();
    return TvDiscoveryOutcome(
      devices: scan.results.map(_deviceFrom).toList(),
      issues: {?scan.issue},
    );
  }

  TvDevice _deviceFrom(ServiceDiscoveryResult result) {
    final model = result.txt['md'];
    return TvDevice(
      // TXT `id` is the receiver's stable UUID; fall back to the SRV host.
      id: 'cast:${result.txt['id'] ?? result.id}',
      name: result.txt['fn'] ?? result.name,
      platform: TvPlatform.googleCast,
      host: result.host,
      port: result.port == CastConstants.defaultPort ? null : result.port,
      iconKey: model == 'Google Cast Group' ? 'speaker_group' : 'cast',
    );
  }

  /// A TLS connection plus `GET_STATUS` - answered only by a real Cast
  /// receiver, and invisible on the TV.
  @override
  Future<TvDevice?> probeHost(String host) async {
    CastSession? session;
    try {
      final transport = await _connector(host, CastConstants.defaultPort);
      session = CastSession(
        transport,
        requestTimeout: const Duration(seconds: 3),
      )..open();
      await session.getStatus();
      return TvDevice(
        id: 'cast:$host',
        name: 'Cast device ($host)',
        platform: TvPlatform.googleCast,
        host: host,
        iconKey: 'cast',
      );
    } catch (_) {
      return null;
    } finally {
      await session?.close();
    }
  }

  // ---- Connection ------------------------------------------------------

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    await _closeSession();
    _device = device;
    _userDisconnected = false;
    _setState(TvConnectionState.connecting);
    try {
      await _openSession(device);
      _setState(TvConnectionState.connected);
      return TvPairingRequest.none;
    } catch (error) {
      _setState(TvConnectionState.error);
      rethrow;
    }
  }

  Future<void> _openSession(TvDevice device) async {
    final host = device.host;
    if (host == null) {
      throw const DeviceNotReachableException(
        'This Cast device has no address.',
      );
    }
    final transport = await _connector(
      host,
      device.port ?? CastConstants.defaultPort,
    );
    final session = CastSession(transport)..open();
    _session = session;
    session.receiverStatus.listen((status) => _receiver = status);
    session.mediaStatus.listen((media) => _media.add(media?.status));
    unawaited(session.done.then((_) => _onSessionClosed(session)));
    _receiver = await session.getStatus();
    _logger.info(
      '[TV][CAST][GOOGLE_CAST] connected apps=${_receiver!.applications.length} '
      'volumeFixed=${_receiver!.volumeFixed}',
    );
  }

  void _onSessionClosed(CastSession session) {
    if (!identical(session, _session)) return;
    _session = null;
    _media.add(null);
    if (_userDisconnected || _device == null) return;
    unawaited(_reconnect());
  }

  /// Bounded exponential backoff; gives up (state `error`) after
  /// [_maxReconnectAttempts] rather than retrying forever.
  Future<void> _reconnect() async {
    final device = _device;
    if (device == null) return;
    _setState(TvConnectionState.reconnecting);
    for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
      await Future<void>.delayed(_reconnectDelay(attempt));
      if (_userDisconnected || !identical(device, _device)) return;
      try {
        await _openSession(device);
        _setState(TvConnectionState.connected);
        return;
      } catch (error) {
        _logger.warning(
          '[TV][CAST][GOOGLE_CAST] reconnect_failed attempt=${attempt + 1} '
          'type=${error.runtimeType}',
        );
      }
    }
    _setState(TvConnectionState.error);
  }

  /// Cast has no pairing step.
  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {
    _userDisconnected = true;
    _device = null;
    await _closeSession();
    _setState(TvConnectionState.disconnected);
  }

  Future<void> _closeSession() async {
    final session = _session;
    _session = null;
    _receiver = null;
    await session?.close();
  }

  // ---- Capabilities & commands ------------------------------------------

  @override
  Future<TvCapabilities> getCapabilities() async {
    final receiver = _receiver;
    if (receiver == null || _state != TvConnectionState.connected) {
      return TvCapabilities.none;
    }
    final canSetVolume = !receiver.volumeFixed;
    return TvCapabilities(
      casting: true,
      volume: canSetVolume,
      mute: canSetVolume,
      mediaControls: true,
      // Play toggles play/pause; rewind/forward seek -10 s/+30 s. No
      // queue, so no previous/next.
      unsupportedKeys: const {
        TvCommandKey.mediaPrevious,
        TvCommandKey.mediaNext,
      },
    );
  }

  @override
  Future<List<TvApplication>> getApplications() async => const [];

  CastSession _requireSession() {
    final session = _session;
    if (session == null || _state != TvConnectionState.connected) {
      throw const TvNotConnectedException();
    }
    return session;
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    final session = _requireSession();
    if (command.type != TvCommandType.key) {
      throw UnsupportedTvCommandException(
        'Cast devices have no ${command.type.name} input.',
      );
    }
    final receiver = _receiver;
    switch (command.key) {
      case TvCommandKey.volumeUp || TvCommandKey.volumeDown:
        if (receiver == null || receiver.volumeFixed) {
          throw const UnsupportedTvCommandException(
            'This Cast device controls its own volume.',
          );
        }
        final current = receiver.volumeLevel ?? 0.5;
        final delta = command.key == TvCommandKey.volumeUp
            ? _volumeStep
            : -_volumeStep;
        await session.setVolume(level: max(0, min(1, current + delta)));
      case TvCommandKey.mute:
        if (receiver == null || receiver.volumeFixed) {
          throw const UnsupportedTvCommandException(
            'This Cast device controls its own volume.',
          );
        }
        await session.setVolume(muted: !receiver.muted);
      case TvCommandKey.mediaPlay || TvCommandKey.mediaPause:
        await togglePlayback();
      case TvCommandKey.mediaStop:
        await stopMedia();
      case TvCommandKey.mediaRewind:
        await _seekBy(const Duration(seconds: -10));
      case TvCommandKey.mediaForward:
        await _seekBy(const Duration(seconds: 30));
      default:
        throw UnsupportedTvCommandException(
          'Cast devices have no ${command.key.name} key.',
        );
    }
  }

  // ---- TvMediaCaster -------------------------------------------------------

  @override
  Future<void> castMedia(TvMediaItem item) async {
    final scheme = item.url.scheme;
    if (scheme != 'http' && scheme != 'https') {
      throw const TvMediaSessionException(
        'Cast devices can only play http(s) links they can reach themselves.',
      );
    }
    final session = _requireSession();
    _logger.info(
      '[TV][CAST][GOOGLE_CAST] load contentType=${item.contentType} '
      'live=${item.isLive}',
    );
    final status = await session.load(item);
    _media.add(status.status);
  }

  @override
  Future<void> togglePlayback() async {
    final session = _requireSession();
    final playing =
        session.lastMediaStatus?.status.playerState == TvPlayerState.playing;
    await session.mediaCommand(playing ? 'PAUSE' : 'PLAY');
  }

  @override
  Future<void> seek(Duration position) async {
    await _requireSession().mediaCommand(
      'SEEK',
      extra: {'currentTime': max(0, position.inMilliseconds) / 1000},
    );
  }

  Future<void> _seekBy(Duration delta) async {
    final current = _requireSession().lastMediaStatus?.status.position;
    if (current == null) {
      throw const TvMediaSessionException(
        'Nothing is playing on this Cast device.',
      );
    }
    await seek(current + delta);
  }

  @override
  Future<void> stopMedia() => _requireSession().mediaCommand('STOP');

  void dispose() {
    _userDisconnected = true;
    unawaited(_closeSession());
    unawaited(_states.close());
    unawaited(_media.close());
  }
}
