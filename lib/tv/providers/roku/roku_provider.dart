import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/ssdp.dart';
import '../../domain/tv_domain.dart';
import 'roku_ecp_client.dart';

/// Maps the shared [TvCommandKey] vocabulary onto Roku ECP key names.
///
/// Roku remotes have no digits, colors, guide, stop or previous/next, and
/// Play is a single play/pause toggle; the options key (`*`, ECP `Info`)
/// is what the Remote screen's "Menu" button means. Volume/channel/power
/// keys only exist on Roku TVs (`is-tv`), not on streaming players.
abstract final class RokuKeyMap {
  static const Map<TvCommandKey, String> everyDevice = {
    TvCommandKey.dpadUp: 'Up',
    TvCommandKey.dpadDown: 'Down',
    TvCommandKey.dpadLeft: 'Left',
    TvCommandKey.dpadRight: 'Right',
    TvCommandKey.select: 'Select',
    TvCommandKey.home: 'Home',
    TvCommandKey.back: 'Back',
    TvCommandKey.menu: 'Info',
    TvCommandKey.mediaPlay: 'Play',
    TvCommandKey.mediaPause: 'Play',
    TvCommandKey.mediaRewind: 'Rev',
    TvCommandKey.mediaForward: 'Fwd',
  };

  static const Map<TvCommandKey, String> rokuTvOnly = {
    TvCommandKey.volumeUp: 'VolumeUp',
    TvCommandKey.volumeDown: 'VolumeDown',
    TvCommandKey.mute: 'VolumeMute',
    TvCommandKey.channelUp: 'ChannelUp',
    TvCommandKey.channelDown: 'ChannelDown',
    // ECP has no documented power toggle; PowerOff is the documented key.
    TvCommandKey.power: 'PowerOff',
  };

  /// Keys in otherwise-enabled groups that no Roku has.
  static const Set<TvCommandKey> neverSupported = {
    TvCommandKey.info,
    TvCommandKey.guide,
    TvCommandKey.mediaStop,
    TvCommandKey.mediaPrevious,
    TvCommandKey.mediaNext,
  };

  static String? keyFor(TvCommandKey key, {required bool isTv}) =>
      everyDevice[key] ?? (isTv ? rokuTvOnly[key] : null);

  static TvCapabilities capabilities({required bool isTv}) => TvCapabilities(
    dpad: true,
    keyboard: true,
    mediaControls: true,
    launchApps: true,
    volume: isTv,
    mute: isTv,
    channel: isTv,
    power: isTv,
    unsupportedKeys: neverSupported,
  );
}

/// [TvProvider] for Roku players and Roku TVs over the official External
/// Control Protocol: SSDP discovery (`roku:ecp`), then stateless HTTP on
/// port 8060. No pairing exists in ECP - "connected" means the device
/// answered `/query/device-info` and accepts control.
class RokuProvider implements TvProvider {
  RokuProvider({
    SsdpSearcher? ssdp,
    RokuHttpTransport? transport,
    this._discoveryTimeout = const Duration(seconds: 4),
  }) : _ssdp = ssdp ?? SsdpSearcher(),
       _transport = transport ?? IoRokuHttpTransport(),
       _logger = AppLogger('TV.Roku');

  final SsdpSearcher _ssdp;
  final RokuHttpTransport _transport;
  final Duration _discoveryTimeout;
  final AppLogger _logger;
  final _states = StreamController<TvConnectionState>.broadcast();

  RokuEcpClient? _client;
  RokuDeviceInfo? _info;
  TvConnectionState _state = TvConnectionState.disconnected;

  @override
  TvPlatform get platform => TvPlatform.roku;

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  void _setState(TvConnectionState state) {
    if (_state == state) return;
    _state = state;
    _logger.info('[TV][CONNECTION][ROKU] state=${state.name}');
    _states.add(state);
  }

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][ROKU] started');
    final search = await _ssdp.search(
      RokuConstants.ssdpSearchTarget,
      timeout: _discoveryTimeout,
    );
    final byId = <String, TvDevice>{};
    await Future.wait(
      search.responses.map((response) async {
        final host = _hostFrom(response);
        if (host == null) return;
        final device = await _describe(host, usn: response.usn);
        byId[device.id] = device;
        _logger.info('[TV][DISCOVERY][ROKU] found device=${device.name}');
      }),
    );
    final issue = switch (search.failure) {
      null => null,
      SsdpFailure.multicastRestricted => TvDiscoveryIssue.multicastRestricted,
      SsdpFailure.networkUnavailable => TvDiscoveryIssue.networkUnavailable,
      SsdpFailure.failed => TvDiscoveryIssue.failed,
    };
    _logger.info(
      '[TV][DISCOVERY][ROKU] completed count=${byId.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return TvDiscoveryOutcome(devices: byId.values.toList(), issues: {?issue});
  }

  @override
  Future<TvDevice?> probeHost(String host) async {
    try {
      final info = await RokuEcpClient(host, _transport).deviceInfo();
      return _deviceFrom(host, info);
    } catch (_) {
      return null;
    }
  }

  String? _hostFrom(SsdpResponse response) {
    final location = response.location;
    final parsed = location == null ? null : Uri.tryParse(location);
    return parsed?.host.isNotEmpty == true
        ? parsed!.host
        : response.sender.address;
  }

  /// Names a discovered Roku from device-info; if that fails, still lists
  /// it (by its SSDP serial) so a slow answer doesn't hide the device.
  Future<TvDevice> _describe(String host, {String? usn}) async {
    try {
      final info = await RokuEcpClient(host, _transport).deviceInfo();
      return _deviceFrom(host, info);
    } catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ROKU] device_info_failed host=$host '
        'type=${error.runtimeType}',
      );
      final serial = usn?.split(':').last;
      return TvDevice(
        id: 'roku:${serial != null && serial.isNotEmpty ? serial : host}',
        name: 'Roku ($host)',
        platform: TvPlatform.roku,
        host: host,
      );
    }
  }

  TvDevice _deviceFrom(String host, RokuDeviceInfo info) => TvDevice(
    // Serial number, not IP: stable across DHCP lease changes.
    id: 'roku:${info.serialNumber}',
    name: info.name,
    platform: TvPlatform.roku,
    host: host,
    iconKey: info.isTv ? 'tv' : 'streaming_player',
  );

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    final host = device.host;
    if (host == null) {
      throw const DeviceNotReachableException('This Roku has no address.');
    }
    _setState(TvConnectionState.connecting);
    final client = RokuEcpClient(host, _transport);
    try {
      _info = await client.deviceInfo();
      _client = client;
      _setState(TvConnectionState.connected);
      return TvPairingRequest.none;
    } catch (error) {
      _client = null;
      _info = null;
      _setState(TvConnectionState.error);
      rethrow;
    }
  }

  /// ECP has no pairing step.
  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {
    _client = null;
    _info = null;
    _setState(TvConnectionState.disconnected);
  }

  @override
  Future<TvCapabilities> getCapabilities() async {
    final info = _info;
    if (info == null || _state != TvConnectionState.connected) {
      return TvCapabilities.none;
    }
    return RokuKeyMap.capabilities(isTv: info.isTv);
  }

  @override
  Future<List<TvApplication>> getApplications() async {
    final client = _client;
    if (client == null) return const [];
    try {
      return await client.apps();
    } catch (error) {
      _logger.warning(
        '[TV][COMMAND][ROKU] apps_failed type=${error.runtimeType}',
      );
      return const [];
    }
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    final client = _client;
    final info = _info;
    if (client == null || info == null) throw const TvNotConnectedException();

    final Future<void> Function() action = switch (command.type) {
      TvCommandType.text => () => client.typeText(command.payload! as String),
      TvCommandType.launchApp => () => client.launch(
        command.payload! as String,
      ),
      TvCommandType.key => () {
        final key = RokuKeyMap.keyFor(command.key, isTv: info.isTv);
        if (key == null) {
          throw UnsupportedTvCommandException(
            'Roku has no ${command.key.name} key.',
          );
        }
        return client.keypress(key);
      },
    };

    try {
      await action();
    } on DeviceNotReachableException {
      await _recoverOnce(client);
      await action();
    }
  }

  /// HTTP is stateless, so "reconnecting" is one bounded device-info check:
  /// if the Roku answers, the command is retried once; if not, the session
  /// ends in `error` rather than looping.
  Future<void> _recoverOnce(RokuEcpClient client) async {
    _setState(TvConnectionState.reconnecting);
    try {
      _info = await client.deviceInfo();
      _setState(TvConnectionState.connected);
    } catch (error) {
      _setState(TvConnectionState.error);
      rethrow;
    }
  }

  void dispose() {
    unawaited(_states.close());
  }
}
