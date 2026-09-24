import 'dart:async';
import 'dart:io' show Platform, Socket;
import 'dart:math' show min, pow;

import '../../../core/logging/app_logger.dart';
import '../../domain/tv_domain.dart';
import 'android_tv_constants.dart';
import 'discovery/android_tv_discovery.dart';
import 'discovery/mdns_android_tv_discovery.dart';
import 'discovery/native_bonjour_android_tv_discovery.dart';
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
    AndroidTvDiscovery? discovery,
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
  static AndroidTvDiscovery _defaultDiscovery() => Platform.isIOS
      ? NativeBonjourAndroidTvDiscovery()
      : MdnsAndroidTvDiscovery();

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
  final AndroidTvDiscovery _discovery;
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

  @override
  TvPlatform get platform => TvPlatform.androidTv;

  @override
  Stream<TvConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Future<TvDiscoveryOutcome> discover() async {
    final scan = await _discovery.discover();
    return TvDiscoveryOutcome(
      devices: scan.results.map(discoveryResultToDevice).toList(),
      issues: {?scan.issue},
    );
  }

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

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    _userDisconnected = false;
    _device = device;
    final host = device.host;
    if (host == null) {
      throw const DeviceNotReachableException(
        'This device has no known network address.',
      );
    }

    _setState(TvConnectionState.connecting);

    final existingIdentity = await _store.loadIdentity(device.id);
    if (existingIdentity != null) {
      // Already paired: skip straight to opening the remote-control
      // connection, which reuses the certificate the TV already trusts.
      _identity = existingIdentity;
      try {
        await _openRemoteConnection(host);
        return TvPairingRequest.none;
      } on TvException {
        // Fall through to re-pairing - the TV may have forgotten this
        // client (factory reset, "forget all devices", etc.).
        _logger.warning(
          '[TV][CONNECTION][ANDROID_TV] stored identity was rejected, re-pairing',
        );
      }
    }

    _identity = _generateIdentity();
    _pairingTransport = await _connect(
      host: host,
      port: AndroidTvConstants.pairingPort,
      identity: _identity!,
      timeout: AndroidTvConstants.connectTimeout,
    );
    _setState(TvConnectionState.pairingRequired);
    _pairingHandshake = PairingHandshake(_pairingTransport!);
    await _pairingHandshake!.start();

    return const TvPinPairingRequest(
      expectedLength: AndroidTvConstants.pairingCodeLength,
    );
  }

  @override
  Future<void> submitPairingCode(String code) async {
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
      pairingCode: code,
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

    await _openRemoteConnection(device.host!);
  }

  Future<void> _openRemoteConnection(String host) async {
    final identity = _identity;
    if (identity == null) throw const PairingRequiredException();

    _setState(TvConnectionState.connecting);
    final transport = await _connect(
      host: host,
      port: AndroidTvConstants.remoteControlPort,
      identity: identity,
      timeout: AndroidTvConstants.connectTimeout,
    );
    final session = RemoteSession(transport);
    _remoteTransport = transport;
    _remoteSession = session;

    unawaited(transport.done.then((error) => _handleDisconnect(error)));

    await session.ready.timeout(
      AndroidTvConstants.connectTimeout,
      onTimeout: () =>
          throw const ConnectionLostException('The TV did not become ready.'),
    );
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

  /// Controlled exponential backoff (1s, 2s, 4s, 8s, capped) rather than
  /// hammering the network or the TV while it's briefly unreachable
  /// (backgrounded app, Wi-Fi blip, TV standby).
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final device = _device;
    if (device?.host == null) {
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

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_userDisconnected) return;
      try {
        await _openRemoteConnection(device!.host!);
      } on TvException {
        if (!_userDisconnected) _scheduleReconnect();
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _userDisconnected = true;
    _reconnectTimer?.cancel();
    await _remoteSession?.dispose();
    await _remoteTransport?.close();
    await _pairingHandshake?.dispose();
    await _pairingTransport?.close();
    _remoteSession = null;
    _remoteTransport = null;
    _pairingHandshake = null;
    _pairingTransport = null;
    _setState(TvConnectionState.disconnected);
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
    _reconnectTimer?.cancel();
    unawaited(_connectionStateController.close());
  }
}
