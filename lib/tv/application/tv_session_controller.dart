import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../domain/tv_domain.dart';
import '../providers/tv_provider_registry_provider.dart';

/// Immutable snapshot of "what TV am I talking to right now", shared by
/// discovery, pairing, remote, and devices screens.
class TvSessionState {
  const TvSessionState({
    this.discoveredDevices = const [],
    this.isDiscovering = false,
    this.selectedDevice,
    this.pairingRequest,
    this.connectionState = TvConnectionState.disconnected,
    this.capabilities = TvCapabilities.none,
    this.applications = const [],
    this.lastError,
  });

  final List<TvDevice> discoveredDevices;
  final bool isDiscovering;
  final TvDevice? selectedDevice;
  final TvPairingRequest? pairingRequest;
  final TvConnectionState connectionState;
  final TvCapabilities capabilities;
  final List<TvApplication> applications;
  final String? lastError;

  bool get isConnected => connectionState == TvConnectionState.connected;

  TvSessionState copyWith({
    List<TvDevice>? discoveredDevices,
    bool? isDiscovering,
    TvDevice? selectedDevice,
    TvPairingRequest? pairingRequest,
    bool clearPairingRequest = false,
    TvConnectionState? connectionState,
    TvCapabilities? capabilities,
    List<TvApplication>? applications,
    String? lastError,
    bool clearError = false,
  }) {
    return TvSessionState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      pairingRequest: clearPairingRequest
          ? null
          : (pairingRequest ?? this.pairingRequest),
      connectionState: connectionState ?? this.connectionState,
      capabilities: capabilities ?? this.capabilities,
      applications: applications ?? this.applications,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Orchestrates discovery -> pairing -> connection -> commands against
/// whichever [TvProvider] owns the selected device. UI never talks to a
/// [TvProvider] directly.
class TvSessionController extends StateNotifier<TvSessionState> {
  TvSessionController(this._ref)
    : _logger = AppLogger('TV.Session'),
      super(const TvSessionState());

  final Ref _ref;
  final AppLogger _logger;
  StreamSubscription<TvConnectionState>? _connectionSub;
  TvProvider? _activeProvider;

  Future<void> discover() async {
    state = state.copyWith(isDiscovering: true, clearError: true);
    try {
      final registry = _ref.read(tvProviderRegistryProvider);
      final devices = await registry.discoverAll();
      state = state.copyWith(discoveredDevices: devices, isDiscovering: false);
    } catch (error) {
      _logger.warning('Discovery failed: $error');
      state = state.copyWith(
        isDiscovering: false,
        lastError: 'Could not scan for devices.',
      );
    }
  }

  Future<void> connect(TvDevice device) async {
    final registry = _ref.read(tvProviderRegistryProvider);
    final provider = registry.forPlatform(device.platform);
    if (provider == null) {
      state = state.copyWith(lastError: 'Unsupported device platform.');
      return;
    }
    _activeProvider = provider;
    unawaited(_connectionSub?.cancel());
    _connectionSub = provider.connectionState.listen((connectionState) {
      state = state.copyWith(connectionState: connectionState);
      if (connectionState == TvConnectionState.connected) {
        unawaited(_loadConnectedDeviceDetails());
      }
    });

    state = state.copyWith(selectedDevice: device, clearError: true);
    try {
      final pairingRequest = await provider.connect(device);
      state = state.copyWith(pairingRequest: pairingRequest);
    } catch (error) {
      _logger.warning('Connect failed: $error');
      state = state.copyWith(lastError: 'Could not connect to ${device.name}.');
    }
  }

  Future<void> submitPairingCode(String code) async {
    final provider = _activeProvider;
    if (provider == null) return;
    try {
      await provider.submitPairingCode(code);
      state = state.copyWith(clearPairingRequest: true, clearError: true);
    } catch (error) {
      _logger.warning('Pairing failed: $error');
      state = state.copyWith(lastError: 'Incorrect pairing code.');
    }
  }

  Future<void> _loadConnectedDeviceDetails() async {
    final provider = _activeProvider;
    if (provider == null) return;
    final capabilities = await provider.getCapabilities();
    final applications = await provider.getApplications();
    state = state.copyWith(
      capabilities: capabilities,
      applications: applications,
    );
  }

  Future<void> sendCommand(TvCommand command) async {
    final provider = _activeProvider;
    if (provider == null) {
      state = state.copyWith(lastError: 'Not connected to a TV.');
      return;
    }
    try {
      await provider.sendCommand(command);
    } on TvException catch (error) {
      _logger.warning('Command failed: ${error.message}');
      state = state.copyWith(lastError: error.message);
    }
  }

  Future<void> disconnect() async {
    await _activeProvider?.disconnect();
    await _connectionSub?.cancel();
    _connectionSub = null;
    _activeProvider = null;
    state = const TvSessionState();
  }

  @override
  void dispose() {
    unawaited(_connectionSub?.cancel());
    super.dispose();
  }
}

final tvSessionControllerProvider =
    StateNotifierProvider<TvSessionController, TvSessionState>((ref) {
      return TvSessionController(ref);
    });
