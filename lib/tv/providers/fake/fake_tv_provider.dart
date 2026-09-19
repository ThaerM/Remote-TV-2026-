import 'dart:async';
import 'dart:math';

import '../../../core/logging/app_logger.dart';
import '../../domain/tv_domain.dart';

/// A single simulated device offered by [FakeTvProvider], along with the
/// capabilities it should report once connected. This is how the app
/// exercises capability-driven UI (a full remote vs. a limited one) without
/// any physical television.
class FakeTvDeviceProfile {
  const FakeTvDeviceProfile({
    required this.device,
    required this.capabilities,
    this.pairingCode = '1234',
    this.applications = const [],
  });

  final TvDevice device;
  final TvCapabilities capabilities;
  final String pairingCode;
  final List<TvApplication> applications;
}

/// Default catalog of demo devices, covering a full-featured Google TV,
/// a Samsung set with no voice/keyboard, and an LG set with no casting -
/// enough spread to prove the remote UI actually adapts per device.
List<FakeTvDeviceProfile> defaultFakeDeviceProfiles() => [
  FakeTvDeviceProfile(
    device: const TvDevice(
      id: 'fake-living-room-google-tv',
      name: 'Living Room Google TV',
      platform: TvPlatform.fake,
      iconKey: 'android_tv',
      isDevelopmentFake: true,
    ),
    capabilities: const TvCapabilities(
      power: true,
      volume: true,
      mute: true,
      channel: false,
      dpad: true,
      touchpad: true,
      keyboard: true,
      voice: true,
      mediaControls: true,
      numericKeypad: false,
      colorKeys: false,
      inputSwitching: true,
      launchApps: true,
      casting: true,
      screenMirroring: true,
      wakeOnLan: true,
      appInstall: false,
    ),
    applications: const [
      TvApplication(id: 'netflix', name: 'Netflix', iconKey: 'netflix'),
      TvApplication(id: 'youtube', name: 'YouTube', iconKey: 'youtube'),
      TvApplication(id: 'disney_plus', name: 'Disney+', iconKey: 'disney_plus'),
    ],
  ),
  FakeTvDeviceProfile(
    device: const TvDevice(
      id: 'fake-bedroom-samsung-tv',
      name: 'Bedroom Samsung TV',
      platform: TvPlatform.fake,
      iconKey: 'samsung',
      isDevelopmentFake: true,
    ),
    pairingCode: '2580',
    capabilities: const TvCapabilities(
      power: true,
      volume: true,
      mute: true,
      channel: true,
      dpad: true,
      touchpad: false,
      keyboard: false,
      voice: false,
      mediaControls: true,
      numericKeypad: true,
      colorKeys: true,
      inputSwitching: true,
      launchApps: true,
      casting: false,
      screenMirroring: false,
      wakeOnLan: true,
      appInstall: false,
    ),
    applications: const [
      TvApplication(id: 'netflix', name: 'Netflix', iconKey: 'netflix'),
      TvApplication(
        id: 'prime_video',
        name: 'Prime Video',
        iconKey: 'prime_video',
      ),
    ],
  ),
  FakeTvDeviceProfile(
    device: const TvDevice(
      id: 'fake-office-lg-tv',
      name: 'Office LG TV',
      platform: TvPlatform.fake,
      iconKey: 'lg',
      isDevelopmentFake: true,
    ),
    pairingCode: '9137',
    capabilities: const TvCapabilities(
      power: true,
      volume: true,
      mute: true,
      channel: true,
      dpad: true,
      touchpad: false,
      keyboard: true,
      voice: false,
      mediaControls: true,
      numericKeypad: true,
      colorKeys: false,
      inputSwitching: true,
      launchApps: true,
      casting: false,
      screenMirroring: false,
      wakeOnLan: false,
      appInstall: false,
    ),
    applications: const [
      TvApplication(id: 'youtube', name: 'YouTube', iconKey: 'youtube'),
      TvApplication(id: 'spotify', name: 'Spotify', iconKey: 'spotify'),
    ],
  ),
];

/// Simulates a real [TvProvider] end-to-end: discovery latency, a PIN
/// pairing challenge, a connection state stream, and commands that are
/// logged rather than sent over a network. Used to build and test the whole
/// app experience before any real vendor integration exists.
class FakeTvProvider implements TvProvider {
  FakeTvProvider({
    List<FakeTvDeviceProfile>? profiles,
    Random? random,
    AppLogger? logger,
  }) : _profiles = profiles ?? defaultFakeDeviceProfiles(),
       _random = random ?? Random(),
       _logger = logger ?? AppLogger('TV.Fake');

  final List<FakeTvDeviceProfile> _profiles;
  final Random _random;
  final AppLogger _logger;

  final _connectionStateController =
      StreamController<TvConnectionState>.broadcast();
  TvConnectionState _state = TvConnectionState.disconnected;

  FakeTvDeviceProfile? _pendingProfile;
  FakeTvDeviceProfile? _connectedProfile;

  @override
  TvPlatform get platform => TvPlatform.fake;

  @override
  Stream<TvConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Future<List<TvDevice>> discover() async {
    _logger.info('Scanning for demo devices...');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final devices = _profiles.map((p) => p.device).toList(growable: false);
    _logger.info('Found ${devices.length} demo device(s).');
    return devices;
  }

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    final profile = _profiles.firstWhere(
      (p) => p.device.id == device.id,
      orElse: () => throw const TvConnectionException('Unknown demo device.'),
    );
    _pendingProfile = profile;
    _setState(TvConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _setState(TvConnectionState.pairingRequired);
    _logger.info('Pairing required for ${device.name}.');
    return TvPinPairingRequest(expectedLength: profile.pairingCode.length);
  }

  @override
  Future<void> submitPairingCode(String code) async {
    final profile = _pendingProfile;
    if (profile == null) {
      throw const TvConnectionException('No pairing in progress.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code != profile.pairingCode) {
      _logger.warning('Pairing code rejected for ${profile.device.name}.');
      throw const TvConnectionException('Incorrect pairing code.');
    }
    _connectedProfile = profile;
    _pendingProfile = null;
    _setState(TvConnectionState.connected);
    _logger.info('Paired and connected to ${profile.device.name}.');
  }

  @override
  Future<void> disconnect() async {
    _connectedProfile = null;
    _pendingProfile = null;
    _setState(TvConnectionState.disconnected);
    _logger.info('Disconnected.');
  }

  @override
  Future<TvCapabilities> getCapabilities() async {
    return _connectedProfile?.capabilities ?? TvCapabilities.none;
  }

  @override
  Future<void> sendCommand(TvCommand command) async {
    final profile = _connectedProfile;
    if (profile == null) {
      throw const TvNotConnectedException();
    }
    if (!_isSupported(command, profile.capabilities)) {
      throw UnsupportedTvCommandException(
        '${profile.device.name} does not support ${command.key}.',
      );
    }
    // Simulate real-world jitter so the UI's loading/pressed states are
    // exercised realistically.
    await Future<void>.delayed(
      Duration(milliseconds: 40 + _random.nextInt(80)),
    );
    _logger.info('[${profile.device.name}] command: $command');
  }

  @override
  Future<List<TvApplication>> getApplications() async {
    return _connectedProfile?.applications ?? const [];
  }

  void _setState(TvConnectionState state) {
    _state = state;
    _connectionStateController.add(state);
  }

  TvConnectionState get currentState => _state;

  bool _isSupported(TvCommand command, TvCapabilities caps) {
    return switch (command.key) {
      TvCommandKey.power => caps.power,
      TvCommandKey.volumeUp || TvCommandKey.volumeDown => caps.volume,
      TvCommandKey.mute => caps.mute,
      TvCommandKey.channelUp ||
      TvCommandKey.channelDown ||
      TvCommandKey.previousChannel => caps.channel,
      TvCommandKey.digit0 ||
      TvCommandKey.digit1 ||
      TvCommandKey.digit2 ||
      TvCommandKey.digit3 ||
      TvCommandKey.digit4 ||
      TvCommandKey.digit5 ||
      TvCommandKey.digit6 ||
      TvCommandKey.digit7 ||
      TvCommandKey.digit8 ||
      TvCommandKey.digit9 => caps.numericKeypad,
      TvCommandKey.dpadUp ||
      TvCommandKey.dpadDown ||
      TvCommandKey.dpadLeft ||
      TvCommandKey.dpadRight ||
      TvCommandKey.select => caps.dpad,
      TvCommandKey.home || TvCommandKey.back || TvCommandKey.menu => true,
      TvCommandKey.guide || TvCommandKey.info => caps.dpad,
      TvCommandKey.inputSource => caps.inputSwitching,
      TvCommandKey.colorRed ||
      TvCommandKey.colorGreen ||
      TvCommandKey.colorYellow ||
      TvCommandKey.colorBlue => caps.colorKeys,
      TvCommandKey.mediaPlay ||
      TvCommandKey.mediaPause ||
      TvCommandKey.mediaStop ||
      TvCommandKey.mediaRewind ||
      TvCommandKey.mediaForward ||
      TvCommandKey.mediaPrevious ||
      TvCommandKey.mediaNext => caps.mediaControls,
      TvCommandKey.voiceStart => caps.voice,
      TvCommandKey.textInput => caps.keyboard,
      TvCommandKey.launchApp => caps.launchApps,
    };
  }

  void dispose() {
    unawaited(_connectionStateController.close());
  }
}
