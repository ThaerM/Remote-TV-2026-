import 'dart:async';
import 'dart:io' show Platform, Socket;
import 'dart:math' show min, pow;

import '../../../core/logging/app_logger.dart';
import '../../domain/tv_domain.dart';
import 'android_tv_constants.dart';
import '../shared/service_discovery/service_discovery.dart';
import '../shared/service_discovery/mdns_service_discovery.dart';
import '../shared/service_discovery/native_bonjour_service_discovery.dart';
import 'protocol/command_mapper.dart';
import 'protocol/generated/remotemessage.pbenum.dart';
import 'protocol/pairing_handshake.dart';
import 'protocol/remote_session.dart';
import 'security/android_tv_identity.dart';
import 'storage/android_tv_paired_device_store.dart';
import 'transport/android_tv_message_transport.dart';
import 'transport/tls_android_tv_transport.dart';

/// Real [TvProvider] for Android TV / Google TV devices.
///
/// Implements the actual mDNS discovery, TLS certificate pairing, and
/// authenticated remote-control protocol described in
/// `docs/research/android-google-tv.md`. Unlike [FakeTvProvider], every
/// operation here talks to a real device over the network - see that
/// document's "Tested vs untested assumptions" section before relying on
/// this against hardware this hasn't been validated on yet.
///
/// `connectFactory`/`discoveryFactory` are injectable purely for tests
/// (see `test/tv/providers/android_tv/`); production code should use the
/// default constructor.
class AndroidTvProvider implements TvProvider {
  AndroidTvProvider({
    required this._store,
    ServiceDiscovery? discovery,
    Future<AndroidTvMessageTransport> Function({
      required String host,
      required int port,
      required AndroidTvIdentity identity,
      required Duration timeout,
    })?
    connect,
    AndroidTvIdentity Function()? generateIdentity,
    Future<bool> Function(String host, int port)? probePort,
  }) : _probePort = probePort ?? _tcpPortOpen,
       _discovery = discovery ?? _defaultDiscovery(),
       _connect = connect ?? TlsAndroidTvTransport.connect,
       _generateIdentity = generateIdentity ?? AndroidTvIdentity.generate,
       _logger = AppLogger('TV.Connection.AndroidTV');

  // iOS restricts raw multicast sockets for third-party apps, so there the
  // system Bonjour stack does discovery; everywhere else raw mDNS works.
  static ServiceDiscovery _defaultDiscovery() => Platform.isIOS
      ? NativeBonjourServiceDiscovery(
          serviceType: AndroidTvConstants.mdnsServiceType,
          logTag: 'ANDROID_TV',
        )
      : MdnsServiceDiscovery(
          serviceType: AndroidTvConstants.mdnsServiceType,
          logTag: 'ANDROID_TV',
        );

  static Future<bool> _tcpPortOpen(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  final Future<bool> Function(String host, int port) _probePort;
  final AndroidTvPairedDeviceStore _store;
  final ServiceDiscovery _discovery;
  final AndroidTvIdentity Function() _generateIdentity;
  final Future<AndroidTvMessageTransport> Function({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
    required Duration timeout,
  })
  _connect;
  final AppLogger _logger;

  final _connectionStateController =
      StreamController<TvConnectionState>.broadcast();
  TvConnectionState _state = TvConnectionState.disconnected;

  TvDevice? _device;
  AndroidTvIdentity? _identity;
  AndroidTvMessageTransport? _pairingTransport;
  PairingHandshake? _pairingHandshake;

  AndroidTvMessageTransport? _remoteTransport;
  RemoteSession? _remoteSession;

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  bool _userDisconnected = false;

  /// Bumped by every [connect] and [disconnect] call. An in-flight attempt
  /// (this device's TLS handshake, a paused reconnect Timer callback) is
  /// abandoned - its socket closed, its result discarded - the moment it
  /// notices its token is stale, so two overlapping attempts (the user taps
  /// a second TV before the first settles, or a reconnect fires just as
  /// the user reconnects by hand) can never cross-contaminate `_device`,
  /// `_identity`, or the live transport/session fields.
  int _connectToken = 0;

  @override
  TvPlatform get platform => TvPlatform.androidTv;

  @override
  Stream<TvConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final scan = await _discovery.discover();
    return TvDiscoveryOutcome(
      devices: scan.results.map(_deviceFrom).toList(),
      issues: {?scan.issue},
    );
  }

  static TvDevice _deviceFrom(ServiceDiscoveryResult result) => TvDevice(
    id: 'android_tv:${result.id}',
    name: result.name,
    platform: TvPlatform.androidTv,
    host: result.host,
  );

  /// A plain TCP connect (no TLS handshake, closed immediately) to the
  /// remote-control or pairing port - enough to know the Android TV Remote
  /// service is listening, without the TV showing anything.
  @override
  Future<TvDevice?> probeHost(String host) async {
    for (final port in const [
      AndroidTvConstants.remoteControlPort,
      AndroidTvConstants.pairingPort,
    ]) {
      if (await _probePort(host, port)) {
        _logger.info(
          '[TV][DISCOVERY][ANDROID_TV] probe_found host=$host port=$port',
        );
        return TvDevice(
          id: 'android_tv:$host',
          name: 'Android TV ($host)',
          platform: TvPlatform.androidTv,
          host: host,
        );
      }
    }
    _logger.info('[TV][DISCOVERY][ANDROID_TV] probe_none host=$host');
    return null;
  }

  /// Wraps [_connect] with a timeout this provider enforces itself,
  /// regardless of whether the injected implementation honors its own
  /// `timeout` parameter.
  ///
  /// The real transport (`TlsAndroidTvTransport.connect`) passes `timeout`
  /// straight to `SecureSocket.connect`, but that only bounds the initial
  /// TCP handshake - dart:io applies no bound at all to the TLS handshake
  /// that follows, so a stalled peer (a half-dead connection left over on
  /// the TV's side, the TV mid-idle-timeout, etc.) can leave that Future
  /// pending forever. That unbounded await, with nothing above it in
  /// [connect]/[_openRemoteConnection] to time it out, was the actual
  /// cause of the reported "stuck on Connecting…" - not a UI bug.
  ///
  /// Dart can't cancel an in-flight Future, so on timeout this discards
  /// the original one but keeps listening to it quietly: if it does
  /// eventually resolve, the transport it produced is closed immediately
  /// instead of being wired in as if it were current.
  Future<AndroidTvMessageTransport> _connectBounded({
    required String host,
    required int port,
    required AndroidTvIdentity identity,
  }) {
    final attempt = _connect(
      host: host,
      port: port,
      identity: identity,
      timeout: AndroidTvConstants.connectTimeout,
    );
    return attempt.timeout(
      AndroidTvConstants.connectTimeout,
      onTimeout: () {
        unawaited(
          attempt.then(
            (transport) => transport.close(),
            onError: (Object _) {},
          ),
        );
        _logger.warning('[TV][CONNECTION][ANDROID_TV] connect_timeout');
        throw const DeviceNotReachableException(
          'Connecting to the TV timed out.',
        );
      },
    );
  }

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    final token = ++_connectToken;
    // Switching TVs (or re-selecting this one) must not leave the previous
    // remote/pairing sockets open alongside the new ones.
    await _closeSockets();
    _userDisconnected = false;
    _reconnectAttempt = 0;
    _device = device;
    final host = device.host;
    if (host == null) {
      throw const DeviceNotReachableException(
        'This device has no known network address.',
      );
    }

    _logger.info(
      '[TV][CONNECTION][ANDROID_TV] connect_started id=${device.id}',
    );
    _setState(TvConnectionState.connecting);

    final existingIdentity = await _store.loadIdentity(device.id);
    if (token != _connectToken) throw _superseded();

    if (existingIdentity != null) {
      _logger.info(
        '[TV][CONNECTION][ANDROID_TV] restoring_saved_device id=${device.id} '
        'using_saved_identity=true',
      );
      // Already paired: skip straight to opening the remote-control
      // connection, which reuses the certificate the TV already trusts.
      _identity = existingIdentity;
      try {
        await _openRemoteConnection(host, token);
        if (token != _connectToken) throw _superseded();
        // Keep the saved host/timestamp current - a saved TV must not
        // need rediscovery just because DHCP gave it a new address.
        await _store.saveMetadata(
          PairedAndroidTvMetadata(
            deviceId: device.id,
            name: device.name,
            lastKnownHost: host,
            lastConnectedAt: DateTime.now(),
          ),
        );
        _logger.info('[TV][CONNECTION][ANDROID_TV] connect_succeeded');
        return TvPairingRequest.none;
      } on AuthenticationFailedException {
        // The TV itself rejected this identity (factory reset, "forget
        // all devices", ...) - and only this - means re-pairing. A
        // reachability/timeout failure must not: the identity is still
        // good, so the user should be able to just retry, never be
        // walked into a fresh pairing code for a TV that's simply off.
        if (token != _connectToken) throw _superseded();
        _logger.warning(
          '[TV][CONNECTION][ANDROID_TV] authentication_rejected '
          'pairing_required=true',
        );
      } on TvException catch (error) {
        if (token != _connectToken) throw _superseded();
        _logger.info(
          '[TV][CONNECTION][ANDROID_TV] connect_failed type=${error.runtimeType}',
        );
        _setState(TvConnectionState.error);
        rethrow;
      }
    } else {
      _logger.info(
        '[TV][CONNECTION][ANDROID_TV] pairing_required id=${device.id} '
        'reason=no_saved_identity',
      );
    }

    _identity = _generateIdentity();
    final AndroidTvMessageTransport pairingTransport;
    try {
      pairingTransport = await _connectBounded(
        host: host,
        port: AndroidTvConstants.pairingPort,
        identity: _identity!,
      );
    } on TvException catch (error) {
      if (token != _connectToken) throw _superseded();
      _logger.info(
        '[TV][CONNECTION][ANDROID_TV] pairing_connect_failed '
        'type=${error.runtimeType}',
      );
      _setState(TvConnectionState.error);
      rethrow;
    }
    if (token != _connectToken) {
      await pairingTransport.close();
      throw _superseded();
    }
    if (_userDisconnected) {
      // Cancelled while the socket was opening.
      await pairingTransport.close();
      throw const TvConnectionException('Pairing was cancelled.');
    }
    _pairingTransport = pairingTransport;
    _setState(TvConnectionState.pairingRequired);
    _pairingHandshake = PairingHandshake(_pairingTransport!);
    await _pairingHandshake!.start();

    return const TvPinPairingRequest(
      expectedLength: AndroidTvConstants.pairingCodeLength,
      alphabet: TvPinAlphabet.hex,
    );
  }

  /// A superseded attempt is not a user-facing failure - it's silently
  /// replaced by whichever [connect]/[disconnect] call came after it - so
  /// it's still a [TvException] (the session controller only special-cases
  /// nothing here) but never surfaces as an error state or message.
  TvException _superseded() =>
      const TvConnectionException('Connection attempt was superseded.');

  @override
  Future<void> submitPairingCode(String code) async {
    final token = _connectToken;
    final transport = _pairingTransport;
    final handshake = _pairingHandshake;
    final identity = _identity;
    final device = _device;
    if (transport == null ||
        handshake == null ||
        identity == null ||
        device == null) {
      throw const PairingRequiredException();
    }

    await handshake.submitCode(
      // The TV shows upper-case hex; accept either case.
      pairingCode: code.trim().toUpperCase(),
      identity: identity,
      peerCertificatePem: transport.peerCertificatePem,
    );

    await handshake.dispose();
    await transport.close();
    _pairingTransport = null;
    _pairingHandshake = null;

    await _store.saveIdentity(device.id, identity);
    await _store.saveMetadata(
      PairedAndroidTvMetadata(
        deviceId: device.id,
        name: device.name,
        lastKnownHost: device.host!,
        lastConnectedAt: DateTime.now(),
      ),
    );

    await _openRemoteConnection(device.host!, token);
  }

  Future<void> _openRemoteConnection(String host, int token) async {
    final identity = _identity;
    if (identity == null) throw const PairingRequiredException();

    if (token == _connectToken) _setState(TvConnectionState.connecting);
    final transport = await _connectBounded(
      host: host,
      port: AndroidTvConstants.remoteControlPort,
      identity: identity,
    );
    if (token != _connectToken) {
      await transport.close();
      throw _superseded();
    }
    final session = RemoteSession(transport);
    _remoteTransport = transport;
    _remoteSession = session;

    // Only the live transport may trigger a reconnect - a socket closed
    // because the user switched TVs must not.
    unawaited(
      transport.done.then((error) {
        if (identical(_remoteTransport, transport)) _handleDisconnect(error);
      }),
    );

    try {
      await session.ready.timeout(
        AndroidTvConstants.connectTimeout,
        onTimeout: () =>
            throw const ConnectionLostException('The TV did not become ready.'),
      );
    } catch (_) {
      if (identical(_remoteTransport, transport)) {
        _remoteSession = null;
        _remoteTransport = null;
      }
      await session.dispose();
      await transport.close();
      rethrow;
    }
    if (token != _connectToken) {
      // Connected just as this attempt was superseded - tear it back
      // down rather than leaving it live under the wrong device/token.
      _remoteSession = null;
      _remoteTransport = null;
      await session.dispose();
      await transport.close();
      throw _superseded();
    }
    _reconnectAttempt = 0;
    _setState(TvConnectionState.connected);
  }

  void _handleDisconnect(Object? error) {
    if (_state != TvConnectionState.connected &&
        _state != TvConnectionState.reconnecting) {
      return;
    }
    _remoteSession = null;
    _remoteTransport = null;

    if (_userDisconnected) {
      _setState(TvConnectionState.disconnected);
      return;
    }

    _setState(TvConnectionState.reconnecting);
    _scheduleReconnect();
  }

  /// Bounded exponential backoff (1s, 2s, 4s, 8s, 16s) rather than
  /// hammering the network or the TV while it's briefly unreachable
  /// (backgrounded app, Wi-Fi blip, TV standby). After
  /// [maxReconnectAttempts] the provider gives up and reports
  /// [TvConnectionState.error] so the user can reconnect deliberately -
  /// never an endless loop against a TV that is off or gone.
  static const maxReconnectAttempts = 5;

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final device = _device;
    if (device?.host == null || _reconnectAttempt >= maxReconnectAttempts) {
      _logger.warning(
        '[TV][CONNECTION][ANDROID_TV] reconnect_gave_up '
        'attempts=$_reconnectAttempt',
      );
      _setState(TvConnectionState.error);
      return;
    }

    const maxDelay = Duration(seconds: 30);
    final delaySeconds = min(
      pow(2, _reconnectAttempt).toInt(),
      maxDelay.inSeconds,
    );
    _reconnectAttempt++;
    _logger.info(
      '[TV][CONNECTION][ANDROID_TV] reconnect_attempt=$_reconnectAttempt',
    );

    if (_state != TvConnectionState.reconnecting) {
      _setState(TvConnectionState.reconnecting);
    }
    final token = _connectToken;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_userDisconnected || token != _connectToken) return;
      try {
        await _openRemoteConnection(device!.host!, token);
      } on AuthenticationFailedException {
        // A newer connect()/disconnect() already took over this token's
        // reconnect duties - let it own the outcome.
        if (token != _connectToken) return;
        // The TV no longer trusts this client - retrying cannot succeed;
        // the user has to pair again.
        _logger.warning('[TV][CONNECTION][ANDROID_TV] reconnect_auth_failed');
        if (!_userDisconnected) _setState(TvConnectionState.error);
      } catch (error) {
        if (token != _connectToken) return;
        _logger.info(
          '[TV][CONNECTION][ANDROID_TV] reconnect_failed '
          'type=${error.runtimeType}',
        );
        if (!_userDisconnected) _scheduleReconnect();
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _userDisconnected = true;
    _connectToken++; // invalidate any in-flight connect/reconnect attempt
    await _closeSockets();
    _setState(TvConnectionState.disconnected);
  }

  Future<void> _closeSockets() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final remoteSession = _remoteSession;
    final remoteTransport = _remoteTransport;
    final pairingHandshake = _pairingHandshake;
    final pairingTransport = _pairingTransport;
    _remoteSession = null;
    _remoteTransport = null;
    _pairingHandshake = null;
    _pairingTransport = null;
    await remoteSession?.dispose();
    await remoteTransport?.close();
    await pairingHandshake?.dispose();
    await pairingTransport?.close();
  }

  @override
  Future<TvCapabilities> getCapabilities() async {
    final session = _remoteSession;
    if (session == null || _state != TvConnectionState.connected) {
      return TvCapabilities.none;
    }
    return TvCapabilities(
      power: session.supportsPower,
      volume: session.supportsVolume,
      mute: session.supportsVolume,
      channel: false,
      dpad: true,
      touchpad: false,
      keyboard: true,
      voice: false,
      mediaControls: true,
      numericKeypad: true,
      colorKeys: false,
      inputSwitching: true,
      launchApps: session.supportsAppLink,
      casting: false,
      screenMirroring: false,
      wakeOnLan: false,
      appInstall: false,
    );
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    final session = _remoteSession;
    if (session == null || _state != TvConnectionState.connected) {
      throw const TvNotConnectedException();
    }

    if (command.type == TvCommandType.text) {
      session.sendText(command.payload! as String);
      return;
    }

    if (command.type == TvCommandType.launchApp) {
      if (!session.supportsAppLink) {
        throw UnsupportedTvCommandException(
          'This TV does not support launching apps.',
        );
      }
      final appId = command.payload! as String;
      final appLink = AndroidTvAppLinks.byAppId[appId];
      if (appLink == null) {
        throw UnsupportedTvCommandException('No known app link for "$appId".');
      }
      session.sendAppLink(appLink);
      return;
    }

    if (AndroidTvCommandMapper.unsupportedByProtocol.contains(command.key)) {
      throw UnsupportedTvCommandException(
        'The Android TV Remote protocol has no "${command.key.name}" command.',
      );
    }

    final keyCode = AndroidTvCommandMapper.supportedKeys[command.key];
    if (keyCode == null) {
      throw UnsupportedTvCommandException(
        'Unrecognized command ${command.key.name}.',
      );
    }
    if ((keyCode == RemoteKeyCode.KEYCODE_POWER && !session.supportsPower) ||
        ((keyCode == RemoteKeyCode.KEYCODE_VOLUME_UP ||
                keyCode == RemoteKeyCode.KEYCODE_VOLUME_DOWN ||
                keyCode == RemoteKeyCode.KEYCODE_VOLUME_MUTE) &&
            !session.supportsVolume)) {
      throw UnsupportedTvCommandException(
        'This TV did not report support for ${command.key.name}.',
      );
    }
    session.sendKey(keyCode);
  }

  @override
  Future<List<TvApplication>> getApplications() async {
    final session = _remoteSession;
    if (session == null || !session.supportsAppLink) return const [];
    return const [
      TvApplication(id: 'netflix', name: 'Netflix', iconKey: 'netflix'),
      TvApplication(id: 'youtube', name: 'YouTube', iconKey: 'youtube'),
    ];
  }

  /// Disconnects, stops any reconnect attempts, and deletes everything
  /// stored about [deviceId] - see docs/architecture/provider-system.md.
  Future<void> forget(String deviceId) async {
    if (_device?.id == deviceId) {
      await disconnect();
      _device = null;
      _identity = null;
    }
    await _store.forget(deviceId);
  }

  void _setState(TvConnectionState state) {
    _state = state;
    _connectionStateController.add(state);
  }

  void dispose() {
    // No in-flight or future connect/reconnect work should touch this
    // instance again once disposed.
    _connectToken++;
    unawaited(_closeSockets());
    unawaited(_connectionStateController.close());
  }
}
