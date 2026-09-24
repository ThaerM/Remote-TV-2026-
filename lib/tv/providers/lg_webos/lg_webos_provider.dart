import 'dart:async';
import 'dart:math' show min;

import '../../../core/logging/app_logger.dart';
import '../../../core/network/ssdp.dart';
import '../../../core/network/text_socket.dart';
import '../../../core/network/upnp_description.dart';
import '../../../core/storage/secure_credential_store.dart';
import '../../domain/tv_domain.dart';
import 'lg_webos_session.dart';

/// Shared-vocabulary keys -> webOS input-socket button names.
abstract final class LgWebOsKeyMap {
  static const Map<TvCommandKey, String> buttons = {
    TvCommandKey.dpadUp: 'UP',
    TvCommandKey.dpadDown: 'DOWN',
    TvCommandKey.dpadLeft: 'LEFT',
    TvCommandKey.dpadRight: 'RIGHT',
    TvCommandKey.select: 'ENTER',
    TvCommandKey.back: 'BACK',
    TvCommandKey.home: 'HOME',
    TvCommandKey.menu: 'MENU',
    TvCommandKey.guide: 'GUIDE',
    TvCommandKey.info: 'INFO',
    TvCommandKey.volumeUp: 'VOLUMEUP',
    TvCommandKey.volumeDown: 'VOLUMEDOWN',
    TvCommandKey.mute: 'MUTE',
    TvCommandKey.channelUp: 'CHANNELUP',
    TvCommandKey.channelDown: 'CHANNELDOWN',
    TvCommandKey.colorRed: 'RED',
    TvCommandKey.colorGreen: 'GREEN',
    TvCommandKey.colorYellow: 'YELLOW',
    TvCommandKey.colorBlue: 'BLUE',
    TvCommandKey.mediaPlay: 'PLAY',
    TvCommandKey.mediaPause: 'PAUSE',
    TvCommandKey.mediaStop: 'STOP',
    TvCommandKey.mediaRewind: 'REWIND',
    TvCommandKey.mediaForward: 'FASTFORWARD',
    TvCommandKey.digit0: '0',
    TvCommandKey.digit1: '1',
    TvCommandKey.digit2: '2',
    TvCommandKey.digit3: '3',
    TvCommandKey.digit4: '4',
    TvCommandKey.digit5: '5',
    TvCommandKey.digit6: '6',
    TvCommandKey.digit7: '7',
    TvCommandKey.digit8: '8',
    TvCommandKey.digit9: '9',
  };

  static const TvCapabilities capabilities = TvCapabilities(
    // Power is off-only: SSAP can't wake a TV that's off (that needs
    // Wake-on-LAN, not implemented).
    power: true,
    volume: true,
    mute: true,
    channel: true,
    dpad: true,
    keyboard: true,
    mediaControls: true,
    numericKeypad: true,
    colorKeys: true,
    launchApps: true,
    unsupportedKeys: {TvCommandKey.mediaPrevious, TvCommandKey.mediaNext},
  );
}

/// Opens the main SSAP socket: `ws://:3000` first, then `wss://:3001`
/// (self-signed), which newer firmware requires.
typedef LgSocketOpener = Future<TextSocket> Function(String host);

Future<TextSocket> _openMainSocket(String host) async {
  try {
    return await IoTextSocket.connect(
      Uri(scheme: 'ws', host: host, port: LgWebOsConstants.wsPort),
      timeout: const Duration(seconds: 4),
    );
  } catch (_) {
    return IoTextSocket.connect(
      Uri(scheme: 'wss', host: host, port: LgWebOsConstants.wssPort),
      timeout: const Duration(seconds: 4),
      allowSelfSigned: true,
    );
  }
}

Future<TextSocket> _openInputSocket(Uri uri) =>
    IoTextSocket.connect(uri, allowSelfSigned: uri.scheme == 'wss');

/// [TvProvider] for LG webOS TVs over SSAP (the "Second Screen" WebSocket
/// API): SSDP discovery, on-TV "allow this device?" pairing with a
/// client-key kept in [SecureCredentialStore], buttons over the separate
/// pointer-input socket, text/app launch/power over SSAP requests.
class LgWebOsProvider implements TvProvider {
  LgWebOsProvider({
    required this._secureStore,
    SsdpSearcher? ssdp,
    HttpTextGetter? httpGet,
    LgSocketOpener? openMainSocket,
    TextSocketConnector? openInputSocket,
    Duration Function(int attempt)? reconnectDelay,
    this._pairingTimeout = const Duration(seconds: 60),
  }) : _ssdp = ssdp ?? SsdpSearcher(),
       _httpGet = httpGet ?? ioHttpGetText,
       _openMain = openMainSocket ?? _openMainSocket,
       _openInput = openInputSocket ?? _openInputSocket,
       _reconnectDelay =
           reconnectDelay ??
           ((attempt) => Duration(seconds: min(8, 1 << attempt))),
       _logger = AppLogger('TV.LgWebOs');

  static const _maxReconnectAttempts = 3;
  static String _keyFor(String deviceId) => 'lg_webos.client_key.$deviceId';

  final SecureCredentialStore _secureStore;
  final SsdpSearcher _ssdp;
  final HttpTextGetter _httpGet;
  final LgSocketOpener _openMain;
  final TextSocketConnector _openInput;
  final Duration Function(int attempt) _reconnectDelay;
  final Duration _pairingTimeout;
  final AppLogger _logger;
  final _states = StreamController<TvConnectionState>.broadcast();

  TvDevice? _device;
  LgWebOsSession? _session;
  TextSocket? _input;
  TvConnectionState _state = TvConnectionState.disconnected;
  var _userDisconnected = false;

  @override
  TvPlatform get platform => TvPlatform.lgWebOs;

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  void _setState(TvConnectionState state) {
    if (_state == state) return;
    _state = state;
    _logger.info('[TV][CONNECTION][LG_WEBOS] state=${state.name}');
    _states.add(state);
  }

  // ---- Discovery -------------------------------------------------------

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][LG_WEBOS] started');
    final search = await _ssdp.search(LgWebOsConstants.ssdpSearchTarget);
    final byId = <String, TvDevice>{};
    await Future.wait(
      search.responses.map((response) async {
        final location = Uri.tryParse(response.location ?? '');
        final host = location?.host.isNotEmpty == true
            ? location!.host
            : response.sender.address;
        final description = location == null
            ? null
            : await UpnpDeviceDescription.fetch(location, get: _httpGet);
        final udn = description?.udn?.replaceFirst('uuid:', '');
        final device = TvDevice(
          // UDN is stable across DHCP; fall back to the address.
          id: 'lg:${udn ?? host}',
          name: description?.friendlyName ?? 'LG TV ($host)',
          platform: TvPlatform.lgWebOs,
          host: host,
          iconKey: 'tv',
        );
        byId[device.id] = device;
        _logger.info('[TV][DISCOVERY][LG_WEBOS] found device=${device.name}');
      }),
    );
    _logger.info(
      '[TV][DISCOVERY][LG_WEBOS] completed count=${byId.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return TvDiscoveryOutcome(
      devices: byId.values.toList(),
      issues: {?_issueFor(search.failure)},
    );
  }

  static TvDiscoveryIssue? _issueFor(SsdpFailure? failure) => switch (failure) {
    null => null,
    SsdpFailure.multicastRestricted => TvDiscoveryIssue.multicastRestricted,
    SsdpFailure.networkUnavailable => TvDiscoveryIssue.networkUnavailable,
    SsdpFailure.failed => TvDiscoveryIssue.failed,
  };

  /// Opens the SSAP socket and says `hello` - no registration, so nothing
  /// appears on the TV.
  @override
  Future<TvDevice?> probeHost(String host) async {
    LgWebOsSession? session;
    try {
      session = LgWebOsSession(
        await _openMain(host),
        requestTimeout: const Duration(seconds: 3),
      )..open();
      await session.hello();
      return TvDevice(
        id: 'lg:$host',
        name: 'LG TV ($host)',
        platform: TvPlatform.lgWebOs,
        host: host,
        iconKey: 'tv',
      );
    } catch (_) {
      return null;
    } finally {
      await session?.close();
    }
  }

  // ---- Connection & pairing ---------------------------------------------

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    await _closeSession();
    _device = device;
    _userDisconnected = false;
    _setState(TvConnectionState.connecting);

    try {
      final session = await _openSession(device);
      final storedKey = await _secureStore.read(key: _keyFor(device.id));
      final prompted = Completer<void>();
      final registration = session.register(
        clientKey: storedKey,
        onPrompt: () {
          if (!prompted.isCompleted) prompted.complete();
        },
      );

      final promptedFirst = await Future.any([
        registration.then((_) => false),
        prompted.future.then((_) => true),
      ]);
      if (!promptedFirst) {
        await _finishConnecting(session, device, await registration);
        return TvPairingRequest.none;
      }

      _logger.info('[TV][PAIRING][LG_WEBOS] prompt_shown');
      _setState(TvConnectionState.pairingRequired);
      unawaited(
        registration.then(
          (key) => _finishConnecting(session, device, key),
          onError: (Object error) {
            _logger.warning(
              '[TV][PAIRING][LG_WEBOS] pairing_failed type=${error.runtimeType}',
            );
            _setState(TvConnectionState.error);
            unawaited(_closeSession());
          },
        ),
      );
      return const TvConfirmOnDevicePairingRequest();
    } catch (error) {
      _setState(TvConnectionState.error);
      await _closeSession();
      rethrow;
    }
  }

  Future<LgWebOsSession> _openSession(TvDevice device) async {
    final host = device.host;
    if (host == null) {
      throw const DeviceNotReachableException('This TV has no address.');
    }
    final TextSocket socket;
    try {
      socket = await _openMain(host);
    } catch (_) {
      throw DeviceNotReachableException('Could not reach the LG TV at $host.');
    }
    final session = LgWebOsSession(socket, pairingTimeout: _pairingTimeout)
      ..open();
    _session = session;
    await session.hello();
    return session;
  }

  Future<void> _finishConnecting(
    LgWebOsSession session,
    TvDevice device,
    String clientKey,
  ) async {
    if (!identical(session, _session)) return;
    await _secureStore.write(key: _keyFor(device.id), value: clientKey);
    final pointer = await session.request(
      LgWebOsConstants.getPointerInputSocket,
    );
    final path = Uri.tryParse(pointer['socketPath'] as String? ?? '');
    if (path == null || !path.hasScheme) {
      throw const ProtocolErrorException(
        'The TV did not provide a button input socket.',
      );
    }
    _input = await _openInput(path);
    unawaited(session.done.then((_) => _onSessionClosed(session)));
    _setState(TvConnectionState.connected);
  }

  void _onSessionClosed(LgWebOsSession session) {
    if (!identical(session, _session)) return;
    _session = null;
    unawaited(_input?.close());
    _input = null;
    if (_userDisconnected || _device == null) return;
    unawaited(_reconnect());
  }

  /// Re-registers with the stored key; a TV that asks for the prompt again
  /// (key revoked) ends in `error` rather than surprising the user.
  Future<void> _reconnect() async {
    final device = _device;
    if (device == null) return;
    _setState(TvConnectionState.reconnecting);
    final key = await _secureStore.read(key: _keyFor(device.id));
    var promptedAgain = false;
    for (
      var attempt = 0;
      attempt < _maxReconnectAttempts && key != null && !promptedAgain;
      attempt++
    ) {
      await Future<void>.delayed(_reconnectDelay(attempt));
      if (_userDisconnected || !identical(device, _device)) return;
      try {
        final session = await _openSession(device);
        final newKey = await session.register(
          clientKey: key,
          onPrompt: () {
            promptedAgain = true;
            unawaited(session.close());
          },
        );
        await _finishConnecting(session, device, newKey);
        return;
      } catch (error) {
        _logger.warning(
          '[TV][CONNECTION][LG_WEBOS] reconnect_failed attempt=${attempt + 1} '
          'type=${error.runtimeType}',
        );
      }
    }
    _setState(TvConnectionState.error);
  }

  /// SSAP pairing is confirmed on the TV, not with a code.
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
    final input = _input;
    _session = null;
    _input = null;
    await input?.close();
    await session?.close();
  }

  /// Removes the stored client key, so the next connect prompts again.
  Future<void> forget(String deviceId) =>
      _secureStore.delete(key: _keyFor(deviceId));

  // ---- Capabilities & commands ------------------------------------------

  @override
  Future<TvCapabilities> getCapabilities() async =>
      _state == TvConnectionState.connected
      ? LgWebOsKeyMap.capabilities
      : TvCapabilities.none;

  @override
  Future<List<TvApplication>> getApplications() async {
    final session = _session;
    if (session == null) return const [];
    try {
      final payload = await session.request(LgWebOsConstants.listLaunchPoints);
      return [
        for (final point in (payload['launchPoints'] as List?) ?? const [])
          if (point is Map && point['id'] is String && point['title'] is String)
            TvApplication(
              id: point['id'] as String,
              name: point['title'] as String,
            ),
      ];
    } catch (error) {
      _logger.warning(
        '[TV][COMMAND][LG_WEBOS] apps_failed type=${error.runtimeType}',
      );
      return const [];
    }
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    final session = _session;
    final input = _input;
    if (session == null ||
        input == null ||
        _state != TvConnectionState.connected) {
      throw const TvNotConnectedException();
    }
    switch (command.type) {
      case TvCommandType.text:
        await session.request(LgWebOsConstants.insertText, {
          'text': command.payload! as String,
          'replace': 0,
        });
      case TvCommandType.launchApp:
        await session.request(LgWebOsConstants.launch, {
          'id': command.payload! as String,
        });
      case TvCommandType.key:
        if (command.key == TvCommandKey.power) {
          session.fireAndForget(LgWebOsConstants.turnOff);
          return;
        }
        final button = LgWebOsKeyMap.buttons[command.key];
        if (button == null) {
          throw UnsupportedTvCommandException(
            'LG webOS has no ${command.key.name} button.',
          );
        }
        input.send('type:button\nname:$button\n\n');
    }
  }

  void dispose() {
    _userDisconnected = true;
    unawaited(_closeSession());
    unawaited(_states.close());
  }
}
