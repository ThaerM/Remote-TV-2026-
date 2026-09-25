import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import '../../../core/logging/app_logger.dart';
import '../../../core/network/ssdp.dart';
import '../../../core/network/text_socket.dart';
import '../../../core/network/upnp_description.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../domain/tv_domain.dart';

/// Samsung Tizen (2016+) local remote API constants. Protocol facts per
/// `docs/research/samsung.md`; implementation is independent.
abstract final class SamsungConstants {
  static const int wsPort = 8001;
  static const int wssPort = 8002;
  static const String ssdpSearchTarget =
      'urn:samsung.com:device:RemoteControlReceiver:1';
  static const String channel = 'samsung.remote.control';

  /// Shown on the TV's "allow this device?" prompt.
  static const String clientName = 'Remote TV 2026';
}

/// `GET http://<tv>:8001/api/v2/` - the fields this app uses.
class SamsungDeviceInfo {
  const SamsungDeviceInfo({
    required this.id,
    required this.name,
    this.modelName,
    this.tokenAuthSupported = false,
  });

  final String id;
  final String name;
  final String? modelName;

  /// 2018+ models require the secure port and a token; older ones accept
  /// plain `ws://:8001` without one.
  final bool tokenAuthSupported;

  static SamsungDeviceInfo? parse(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final device = decoded['device'];
      if (device is! Map) return null;
      final id = (device['id'] ?? decoded['id'])?.toString();
      if (id == null || id.isEmpty) return null;
      final name = (device['name'] ?? decoded['name'])?.toString();
      return SamsungDeviceInfo(
        id: id.replaceFirst('uuid:', ''),
        name: name == null || name.isEmpty ? 'Samsung TV' : name,
        modelName: device['modelName']?.toString(),
        tokenAuthSupported: device['TokenAuthSupport']?.toString() == 'true',
      );
    } catch (_) {
      return null;
    }
  }
}

abstract final class SamsungKeyMap {
  static const Map<TvCommandKey, String> keys = {
    TvCommandKey.dpadUp: 'KEY_UP',
    TvCommandKey.dpadDown: 'KEY_DOWN',
    TvCommandKey.dpadLeft: 'KEY_LEFT',
    TvCommandKey.dpadRight: 'KEY_RIGHT',
    TvCommandKey.select: 'KEY_ENTER',
    TvCommandKey.back: 'KEY_RETURN',
    TvCommandKey.home: 'KEY_HOME',
    TvCommandKey.menu: 'KEY_MENU',
    TvCommandKey.guide: 'KEY_GUIDE',
    TvCommandKey.info: 'KEY_INFO',
    TvCommandKey.inputSource: 'KEY_SOURCE',
    TvCommandKey.power: 'KEY_POWER',
    TvCommandKey.volumeUp: 'KEY_VOLUP',
    TvCommandKey.volumeDown: 'KEY_VOLDOWN',
    TvCommandKey.mute: 'KEY_MUTE',
    TvCommandKey.channelUp: 'KEY_CHUP',
    TvCommandKey.channelDown: 'KEY_CHDOWN',
    TvCommandKey.previousChannel: 'KEY_PRECH',
    TvCommandKey.colorRed: 'KEY_RED',
    TvCommandKey.colorGreen: 'KEY_GREEN',
    TvCommandKey.colorYellow: 'KEY_YELLOW',
    TvCommandKey.colorBlue: 'KEY_BLUE',
    TvCommandKey.mediaPlay: 'KEY_PLAY',
    TvCommandKey.mediaPause: 'KEY_PAUSE',
    TvCommandKey.mediaStop: 'KEY_STOP',
    TvCommandKey.mediaRewind: 'KEY_REWIND',
    TvCommandKey.mediaForward: 'KEY_FF',
    TvCommandKey.digit0: 'KEY_0',
    TvCommandKey.digit1: 'KEY_1',
    TvCommandKey.digit2: 'KEY_2',
    TvCommandKey.digit3: 'KEY_3',
    TvCommandKey.digit4: 'KEY_4',
    TvCommandKey.digit5: 'KEY_5',
    TvCommandKey.digit6: 'KEY_6',
    TvCommandKey.digit7: 'KEY_7',
    TvCommandKey.digit8: 'KEY_8',
    TvCommandKey.digit9: 'KEY_9',
  };

  static const TvCapabilities capabilities = TvCapabilities(
    // KEY_POWER turns an on TV off (or into standby); turning a TV on from
    // off needs Wake-on-LAN, which isn't implemented.
    power: true,
    volume: true,
    mute: true,
    channel: true,
    dpad: true,
    keyboard: true,
    mediaControls: true,
    numericKeypad: true,
    colorKeys: true,
    inputSwitching: true,
    launchApps: true,
    unsupportedKeys: {TvCommandKey.mediaPrevious, TvCommandKey.mediaNext},
  );
}

/// [TvProvider] for Samsung Tizen TVs (2016+) over the local
/// `samsung.remote.control` WebSocket channel. Pre-2016 Orsay models use a
/// different protocol and aren't supported.
class SamsungTvProvider implements TvProvider {
  SamsungTvProvider({
    required this._secureStore,
    SsdpSearcher? ssdp,
    HttpTextGetter? httpGet,
    TextSocketConnector? connectSocket,
    Duration Function(int attempt)? reconnectDelay,
    this._connectGrace = const Duration(seconds: 3),
    this._pairingTimeout = const Duration(seconds: 60),
  }) : _ssdp = ssdp ?? SsdpSearcher(),
       _httpGet = httpGet ?? ioHttpGetText,
       _connectSocket = connectSocket ?? _defaultConnect,
       _reconnectDelay =
           reconnectDelay ??
           ((attempt) => Duration(seconds: min(8, 1 << attempt))),
       _logger = AppLogger('TV.Samsung');

  static Future<TextSocket> _defaultConnect(Uri uri) => IoTextSocket.connect(
    uri,
    // The secure port serves a self-signed certificate.
    allowSelfSigned: uri.scheme == 'wss',
  );

  static const _maxReconnectAttempts = 3;
  static String _tokenKey(String deviceId) => 'samsung.token.$deviceId';

  final SecureCredentialStore _secureStore;
  final SsdpSearcher _ssdp;
  final HttpTextGetter _httpGet;
  final TextSocketConnector _connectSocket;
  final Duration Function(int attempt) _reconnectDelay;

  /// How long to wait for `ms.channel.connect` before assuming the TV is
  /// showing its "allow" prompt.
  final Duration _connectGrace;
  final Duration _pairingTimeout;
  final AppLogger _logger;
  final _states = StreamController<TvConnectionState>.broadcast();

  TvDevice? _device;
  TextSocket? _socket;
  SamsungDeviceInfo? _info;
  StreamSubscription<String>? _sub;
  Completer<List<TvApplication>>? _appsRequest;
  final Map<String, int> _appTypes = {};
  TvConnectionState _state = TvConnectionState.disconnected;
  var _userDisconnected = false;

  @override
  TvPlatform get platform => TvPlatform.samsungTizen;

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  void _setState(TvConnectionState state) {
    if (_state == state) return;
    _state = state;
    _logger.info('[TV][CONNECTION][SAMSUNG] state=${state.name}');
    _states.add(state);
  }

  Uri _infoUri(String host) => Uri(
    scheme: 'http',
    host: host,
    port: SamsungConstants.wsPort,
    path: '/api/v2/',
  );

  Future<SamsungDeviceInfo?> _fetchInfo(String host) async {
    final body = await _httpGet(_infoUri(host));
    return body == null ? null : SamsungDeviceInfo.parse(body);
  }

  TvDevice _deviceFrom(String host, SamsungDeviceInfo info) => TvDevice(
    id: 'samsung:${info.id}',
    name: info.name,
    platform: TvPlatform.samsungTizen,
    host: host,
    iconKey: 'tv',
  );

  // ---- Discovery -------------------------------------------------------

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][SAMSUNG] started');
    final search = await _ssdp.search(SamsungConstants.ssdpSearchTarget);
    final byId = <String, TvDevice>{};
    await Future.wait(
      search.responses.map((response) async {
        final location = Uri.tryParse(response.location ?? '');
        final host = location?.host.isNotEmpty == true
            ? location!.host
            : response.sender.address;
        final info = await _fetchInfo(host);
        // Only 2016+ Tizen TVs answer /api/v2/; anything else can't be
        // controlled by this provider, so it isn't listed.
        if (info == null) return;
        final device = _deviceFrom(host, info);
        byId[device.id] = device;
        _logger.info('[TV][DISCOVERY][SAMSUNG] found device=${device.name}');
      }),
    );
    _logger.info(
      '[TV][DISCOVERY][SAMSUNG] completed count=${byId.length} '
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

  @override
  Future<TvDevice?> probeHost(String host) async {
    final info = await _fetchInfo(host);
    return info == null ? null : _deviceFrom(host, info);
  }

  // ---- Connection & pairing ---------------------------------------------

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    await _closeSocket();
    _device = device;
    _userDisconnected = false;
    _setState(TvConnectionState.connecting);
    try {
      final host = device.host;
      if (host == null) {
        throw const DeviceNotReachableException('This TV has no address.');
      }
      final info = await _fetchInfo(host);
      if (info == null) {
        throw DeviceNotReachableException(
          'The Samsung TV at $host did not answer. It may be off, or a model '
          'from before 2016 that this app cannot control.',
        );
      }
      _info = info;
      final channel = (await _openChannel(device, info)).connected;

      final connectedQuickly = await Future.any([
        channel.then((_) => true),
        Future<bool>.delayed(_connectGrace, () => false),
      ]);
      if (connectedQuickly) {
        _setState(TvConnectionState.connected);
        return TvPairingRequest.none;
      }
      _logger.info('[TV][PAIRING][SAMSUNG] prompt_assumed');
      _setState(TvConnectionState.pairingRequired);
      unawaited(
        channel.then(
          (_) => _setState(TvConnectionState.connected),
          onError: (Object error) {
            _logger.warning(
              '[TV][PAIRING][SAMSUNG] pairing_failed type=${error.runtimeType}',
            );
            _setState(TvConnectionState.error);
            unawaited(_closeSocket());
          },
        ),
      );
      return const TvConfirmOnDevicePairingRequest();
    } catch (error) {
      _setState(TvConnectionState.error);
      await _closeSocket();
      rethrow;
    }
  }

  /// Opens the remote-control socket and returns (once it's open) a future
  /// that completes on `ms.channel.connect` (saving any new token) and
  /// fails on `ms.channel.unauthorized`, a closed socket, or
  /// [_pairingTimeout].
  Future<({Future<void> connected})> _openChannel(
    TvDevice device,
    SamsungDeviceInfo info,
  ) async {
    final host = device.host!;
    final token = await _secureStore.read(key: _tokenKey(device.id));
    final secure = info.tokenAuthSupported;
    final uri = Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host,
      port: secure ? SamsungConstants.wssPort : SamsungConstants.wsPort,
      path: '/api/v2/channels/${SamsungConstants.channel}',
      queryParameters: {
        'name': base64.encode(utf8.encode(SamsungConstants.clientName)),
        if (secure && token != null) 'token': token,
      },
    );
    final TextSocket socket;
    try {
      socket = await _connectSocket(uri);
    } catch (_) {
      throw DeviceNotReachableException(
        'Could not reach the Samsung TV at $host.',
      );
    }
    _socket = socket;
    final connected = Completer<void>();
    _sub = socket.messages.listen((raw) => _onMessage(raw, device, connected));
    unawaited(
      socket.done.then((_) {
        if (!connected.isCompleted) {
          connected.completeError(
            const ConnectionLostException('The TV closed the connection.'),
          );
        }
        _onSocketClosed(socket);
      }),
    );
    return (
      connected: connected.future.timeout(
        _pairingTimeout,
        onTimeout: () => throw const PairingTimeoutException(
          'The TV did not allow the connection in time.',
        ),
      ),
    );
  }

  void _onMessage(String raw, TvDevice device, Completer<void> connected) {
    final Map<String, Object?> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return;
      message = decoded;
    } catch (_) {
      return;
    }
    final data = message['data'];
    switch (message['event']) {
      case 'ms.channel.connect':
        final token = data is Map ? data['token']?.toString() : null;
        if (token != null && token.isNotEmpty) {
          unawaited(
            _secureStore.write(key: _tokenKey(device.id), value: token),
          );
        }
        if (!connected.isCompleted) connected.complete();
      case 'ms.channel.unauthorized':
        if (!connected.isCompleted) {
          connected.completeError(
            const PairingRejectedException('The TV denied access to this app.'),
          );
        }
      case 'ed.installedApp.get':
        final list = data is Map ? data['data'] : null;
        final apps = <TvApplication>[];
        for (final app in list is List ? list : const []) {
          if (app is! Map || app['appId'] == null || app['name'] == null) {
            continue;
          }
          final id = app['appId'].toString();
          _appTypes[id] = int.tryParse('${app['app_type']}') ?? 0;
          apps.add(TvApplication(id: id, name: app['name'].toString()));
        }
        final request = _appsRequest;
        if (request != null && !request.isCompleted) request.complete(apps);
    }
  }

  void _onSocketClosed(TextSocket socket) {
    if (!identical(socket, _socket)) return;
    _socket = null;
    if (_userDisconnected || _device == null) return;
    if (_state == TvConnectionState.connected) unawaited(_reconnect());
  }

  /// Reconnects with the stored token; if the TV would need the prompt
  /// again (token revoked) the grace period passes and it stops in
  /// `error` rather than leaving a prompt up on the TV.
  Future<void> _reconnect() async {
    final device = _device;
    final info = _info;
    if (device == null || info == null) return;
    _setState(TvConnectionState.reconnecting);
    for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
      await Future<void>.delayed(_reconnectDelay(attempt));
      if (_userDisconnected || !identical(device, _device)) return;
      try {
        await (await _openChannel(
          device,
          info,
        )).connected.timeout(_connectGrace);
        _setState(TvConnectionState.connected);
        return;
      } catch (error) {
        await _closeSocket();
        _logger.warning(
          '[TV][CONNECTION][SAMSUNG] reconnect_failed attempt=${attempt + 1} '
          'type=${error.runtimeType}',
        );
        if (error is PairingRejectedException) break;
      }
    }
    _setState(TvConnectionState.error);
  }

  /// Samsung pairing is confirmed on the TV, not with a code.
  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {
    _userDisconnected = true;
    _device = null;
    await _closeSocket();
    _setState(TvConnectionState.disconnected);
  }

  Future<void> _closeSocket() async {
    final socket = _socket;
    _socket = null;
    await _sub?.cancel();
    _sub = null;
    await socket?.close();
  }

  Future<void> forget(String deviceId) =>
      _secureStore.delete(key: _tokenKey(deviceId));

  // ---- Capabilities & commands ------------------------------------------

  @override
  Future<TvCapabilities> getCapabilities() async =>
      _state == TvConnectionState.connected
      ? SamsungKeyMap.capabilities
      : TvCapabilities.none;

  /// Newer firmware silently ignores the installed-apps request; that
  /// just means an empty list (the quick-apps row stays hidden).
  @override
  Future<List<TvApplication>> getApplications() async {
    final socket = _socket;
    if (socket == null) return const [];
    final request = Completer<List<TvApplication>>();
    _appsRequest = request;
    _emit(socket, {
      'method': 'ms.channel.emit',
      'params': {'event': 'ed.installedApp.get', 'to': 'host'},
    });
    return request.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => const [],
    );
  }

  void _emit(TextSocket socket, Map<String, Object?> message) =>
      socket.send(jsonEncode(message));

  @override
  Future<void> sendCommand(TvCommand command) async {
    final socket = _socket;
    if (socket == null || _state != TvConnectionState.connected) {
      throw const TvNotConnectedException();
    }
    switch (command.type) {
      case TvCommandType.text:
        // Types into whatever text field has focus on the TV.
        _emit(socket, {
          'method': 'ms.remote.control',
          'params': {
            'Cmd': base64.encode(utf8.encode(command.payload! as String)),
            'DataOfCmd': 'base64',
            'TypeOfRemote': 'SendInputString',
          },
        });
        _emit(socket, {
          'method': 'ms.remote.control',
          'params': {'TypeOfRemote': 'SendInputEnd'},
        });
      case TvCommandType.launchApp:
        final appId = command.payload! as String;
        _emit(socket, {
          'method': 'ms.channel.emit',
          'params': {
            'event': 'ed.apps.launch',
            'to': 'host',
            'data': {
              'appId': appId,
              'action_type': _appTypes[appId] == 2
                  ? 'DEEP_LINK'
                  : 'NATIVE_LAUNCH',
              'metaTag': '',
            },
          },
        });
      case TvCommandType.key:
        final key = SamsungKeyMap.keys[command.key];
        if (key == null) {
          throw UnsupportedTvCommandException(
            'Samsung TVs have no ${command.key.name} key here.',
          );
        }
        _emit(socket, {
          'method': 'ms.remote.control',
          'params': {
            'Cmd': 'Click',
            'DataOfCmd': key,
            'Option': 'false',
            'TypeOfRemote': 'SendRemoteKey',
          },
        });
    }
  }

  void dispose() {
    _userDisconnected = true;
    unawaited(_closeSocket());
    unawaited(_states.close());
  }
}
