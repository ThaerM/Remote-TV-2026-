import 'dart:async';
import 'dart:math' show max, min;

import '../../../core/logging/app_logger.dart';
import '../../../core/network/ssdp.dart';
import '../../../core/network/upnp_description.dart';
import '../../domain/tv_domain.dart';
import 'dlna_soap.dart';

class _Renderer {
  const _Renderer({required this.avTransport, this.renderingControl});

  final Uri avTransport;
  final Uri? renderingControl;
}

/// [TvProvider] + [TvMediaCaster] for DLNA / UPnP MediaRenderers (many
/// smart TVs, AV receivers, speakers). A media target only: DLNA has no
/// remote-control keys, so it never reports D-pad/keyboard/apps - it plays
/// a URL the TV fetches itself, with transport controls and (when the
/// renderer has RenderingControl) volume/mute.
class DlnaProvider implements TvProvider, TvMediaCaster {
  DlnaProvider({
    SsdpSearcher? ssdp,
    HttpTextGetter? httpGet,
    SoapPoster? post,
    this._pollInterval = const Duration(seconds: 2),
  }) : _ssdp = ssdp ?? SsdpSearcher(),
       _httpGet = httpGet ?? ioHttpGetText,
       _post = post ?? ioSoapPost,
       _logger = AppLogger('TV.Dlna');

  static const _volumeStep = 5;

  final SsdpSearcher _ssdp;
  final HttpTextGetter _httpGet;
  final SoapPoster _post;
  final Duration _pollInterval;
  final AppLogger _logger;
  final _states = StreamController<TvConnectionState>.broadcast();
  final _media = StreamController<TvMediaStatus?>.broadcast();

  /// Control URLs learned during discovery, by device id. DLNA has no
  /// fixed port, so a renderer can only be controlled after it's been
  /// discovered in this app session.
  final _renderers = <String, _Renderer>{};

  UpnpSoapClient? _transport;
  UpnpSoapClient? _rendering;
  Timer? _poll;
  TvMediaStatus? _lastStatus;
  String? _title;
  var _polling = false;
  TvConnectionState _state = TvConnectionState.disconnected;

  @override
  TvPlatform get platform => TvPlatform.dlna;

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  @override
  Stream<TvMediaStatus?> get mediaStatus => _media.stream;

  void _setState(TvConnectionState state) {
    if (_state == state) return;
    _state = state;
    _logger.info('[TV][CAST][DLNA] state=${state.name}');
    _states.add(state);
  }

  // ---- Discovery -------------------------------------------------------

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][DLNA] started');
    final search = await _ssdp.search(DlnaConstants.ssdpSearchTarget);
    final byId = <String, TvDevice>{};
    await Future.wait(
      search.responses.map((response) async {
        final location = Uri.tryParse(response.location ?? '');
        if (location == null || location.host.isEmpty) return;
        final description = await UpnpDeviceDescription.fetch(
          location,
          get: _httpGet,
        );
        final avTransport = description?.service(DlnaConstants.avTransport);
        // Without AVTransport it can't play anything - not a target.
        if (description == null || avTransport == null) return;
        final id =
            'dlna:${description.udn?.replaceFirst('uuid:', '') ?? location.host}';
        _renderers[id] = _Renderer(
          avTransport: avTransport.controlUrl,
          renderingControl: description
              .service(DlnaConstants.renderingControl)
              ?.controlUrl,
        );
        byId[id] = TvDevice(
          id: id,
          name: description.friendlyName,
          platform: TvPlatform.dlna,
          host: location.host,
          iconKey: 'cast',
        );
        _logger.info(
          '[TV][DISCOVERY][DLNA] found device=${description.friendlyName}',
        );
      }),
    );
    _logger.info(
      '[TV][DISCOVERY][DLNA] completed count=${byId.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return TvDiscoveryOutcome(
      devices: byId.values.toList(),
      issues: {
        ?switch (search.failure) {
          null => null,
          SsdpFailure.multicastRestricted =>
            TvDiscoveryIssue.multicastRestricted,
          SsdpFailure.networkUnavailable => TvDiscoveryIssue.networkUnavailable,
          SsdpFailure.failed => TvDiscoveryIssue.failed,
        },
      },
    );
  }

  /// DLNA renderers publish their control URLs only via SSDP (no fixed
  /// port to probe), so a bare address can't be recognized.
  @override
  Future<TvDevice?> probeHost(String host) async => null;

  // ---- Connection ------------------------------------------------------

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    await disconnect();
    final renderer = _renderers[device.id];
    if (renderer == null) {
      _setState(TvConnectionState.error);
      throw const DeviceNotReachableException(
        'Scan again to reconnect to this DLNA device.',
      );
    }
    _setState(TvConnectionState.connecting);
    final transport = UpnpSoapClient(
      DlnaConstants.avTransport,
      renderer.avTransport,
      _post,
    );
    try {
      await transport.call('GetTransportInfo', {'InstanceID': '0'});
    } catch (error) {
      _setState(TvConnectionState.error);
      rethrow;
    }
    _transport = transport;
    final rendering = renderer.renderingControl;
    _rendering = rendering == null
        ? null
        : UpnpSoapClient(DlnaConstants.renderingControl, rendering, _post);
    _setState(TvConnectionState.connected);
    _startPolling();
    return TvPairingRequest.none;
  }

  /// UPnP eventing (GENA) needs an inbound HTTP server; polling transport
  /// state is simpler and bounded.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => unawaited(_refreshStatus()));
  }

  Future<void> _refreshStatus() async {
    final transport = _transport;
    if (transport == null || _polling) return;
    _polling = true;
    try {
      final info = await transport.call('GetTransportInfo', {
        'InstanceID': '0',
      });
      final state = switch (info['CurrentTransportState']) {
        'PLAYING' => TvPlayerState.playing,
        'PAUSED_PLAYBACK' || 'PAUSED_RECORDING' => TvPlayerState.paused,
        'TRANSITIONING' => TvPlayerState.buffering,
        _ => TvPlayerState.idle,
      };
      TvMediaStatus? status;
      if (state != TvPlayerState.idle) {
        final position = await transport.call('GetPositionInfo', {
          'InstanceID': '0',
        });
        status = TvMediaStatus(
          playerState: state,
          position: parseUpnpTime(position['RelTime']) ?? Duration.zero,
          duration: parseUpnpTime(position['TrackDuration']),
          title: _title,
        );
      }
      if (status?.playerState != _lastStatus?.playerState ||
          status?.position != _lastStatus?.position) {
        _lastStatus = status;
        _media.add(status);
      }
    } catch (error) {
      _logger.warning('[TV][CAST][DLNA] poll_failed type=${error.runtimeType}');
    } finally {
      _polling = false;
    }
  }

  /// DLNA has no pairing.
  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {
    _poll?.cancel();
    _poll = null;
    _transport = null;
    _rendering = null;
    _lastStatus = null;
    if (_state != TvConnectionState.disconnected) {
      _setState(TvConnectionState.disconnected);
    }
  }

  // ---- Capabilities & commands ------------------------------------------

  @override
  Future<TvCapabilities> getCapabilities() async {
    if (_transport == null || _state != TvConnectionState.connected) {
      return TvCapabilities.none;
    }
    final hasRendering = _rendering != null;
    return TvCapabilities(
      casting: true,
      mediaControls: true,
      volume: hasRendering,
      mute: hasRendering,
      unsupportedKeys: const {
        TvCommandKey.mediaPrevious,
        TvCommandKey.mediaNext,
      },
    );
  }

  @override
  Future<List<TvApplication>> getApplications() async => const [];

  UpnpSoapClient _requireTransport() {
    final transport = _transport;
    if (transport == null) throw const TvNotConnectedException();
    return transport;
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    _requireTransport();
    if (command.type != TvCommandType.key) {
      throw UnsupportedTvCommandException(
        'DLNA devices have no ${command.type.name} input.',
      );
    }
    switch (command.key) {
      case TvCommandKey.volumeUp || TvCommandKey.volumeDown:
        final rendering = _requireRendering();
        final current =
            int.tryParse(
              (await rendering.call('GetVolume', {
                    'InstanceID': '0',
                    'Channel': 'Master',
                  }))['CurrentVolume'] ??
                  '',
            ) ??
            0;
        final delta = command.key == TvCommandKey.volumeUp
            ? _volumeStep
            : -_volumeStep;
        await rendering.call('SetVolume', {
          'InstanceID': '0',
          'Channel': 'Master',
          'DesiredVolume': '${max(0, min(100, current + delta))}',
        });
      case TvCommandKey.mute:
        final rendering = _requireRendering();
        final muted =
            (await rendering.call('GetMute', {
              'InstanceID': '0',
              'Channel': 'Master',
            }))['CurrentMute'] ==
            '1';
        await rendering.call('SetMute', {
          'InstanceID': '0',
          'Channel': 'Master',
          'DesiredMute': muted ? '0' : '1',
        });
      case TvCommandKey.mediaPlay || TvCommandKey.mediaPause:
        await togglePlayback();
      case TvCommandKey.mediaStop:
        await stopMedia();
      case TvCommandKey.mediaRewind || TvCommandKey.mediaForward:
        final position = _lastStatus?.position;
        if (position == null) {
          throw const TvMediaSessionException('Nothing is playing on this TV.');
        }
        await seek(
          position +
              (command.key == TvCommandKey.mediaForward
                  ? const Duration(seconds: 30)
                  : const Duration(seconds: -10)),
        );
      default:
        throw UnsupportedTvCommandException(
          'DLNA devices have no ${command.key.name} key.',
        );
    }
  }

  UpnpSoapClient _requireRendering() {
    final rendering = _rendering;
    if (rendering == null) {
      throw const UnsupportedTvCommandException(
        'This DLNA device has no volume control.',
      );
    }
    return rendering;
  }

  // ---- TvMediaCaster -------------------------------------------------------

  @override
  Future<void> castMedia(TvMediaItem item) async {
    final scheme = item.url.scheme;
    if (scheme != 'http' && scheme != 'https') {
      throw const TvMediaSessionException(
        'DLNA devices can only play http(s) links they can reach themselves.',
      );
    }
    final transport = _requireTransport();
    _logger.info('[TV][CAST][DLNA] load contentType=${item.contentType}');
    _title = item.title;
    await transport.call('SetAVTransportURI', {
      'InstanceID': '0',
      'CurrentURI': item.url.toString(),
      'CurrentURIMetaData': didlLiteFor(item),
    });
    await transport.call('Play', {'InstanceID': '0', 'Speed': '1'});
    await _refreshStatus();
  }

  @override
  Future<void> togglePlayback() async {
    final transport = _requireTransport();
    final playing = _lastStatus?.playerState == TvPlayerState.playing;
    await transport.call(
      playing ? 'Pause' : 'Play',
      playing ? {'InstanceID': '0'} : {'InstanceID': '0', 'Speed': '1'},
    );
    await _refreshStatus();
  }

  @override
  Future<void> seek(Duration position) async {
    await _requireTransport().call('Seek', {
      'InstanceID': '0',
      'Unit': 'REL_TIME',
      'Target': formatUpnpTime(position),
    });
    await _refreshStatus();
  }

  @override
  Future<void> stopMedia() async {
    await _requireTransport().call('Stop', {'InstanceID': '0'});
    await _refreshStatus();
  }

  void dispose() {
    _poll?.cancel();
    unawaited(_states.close());
    unawaited(_media.close());
  }
}
