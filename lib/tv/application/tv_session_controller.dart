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
    this.discoveryIssue,
    this.isProbing = false,
    this.selectedDevice,
    this.pairingRequest,
    this.connectionState = TvConnectionState.disconnected,
    this.capabilities = TvCapabilities.none,
    this.applications = const [],
    this.lastError,
  });

  final List<TvDevice> discoveredDevices;
  final bool isDiscovering;

  /// The most actionable reason the last scan may have missed TVs.
  final TvDiscoveryIssue? discoveryIssue;

  /// A manual "add by address" probe is in flight.
  final bool isProbing;
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
    TvDiscoveryIssue? discoveryIssue,
    bool clearDiscoveryIssue = false,
    bool? isProbing,
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
      discoveryIssue: clearDiscoveryIssue
          ? null
          : (discoveryIssue ?? this.discoveryIssue),
      isProbing: isProbing ?? this.isProbing,
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
    state = state.copyWith(
      isDiscovering: true,
      clearError: true,
      clearDiscoveryIssue: true,
    );
    try {
      final registry = _ref.read(tvProviderRegistryProvider);
      final outcome = await registry.discoverAll();
      state = state.copyWith(
        discoveredDevices: _withManualDevices(outcome.devices),
        isDiscovering: false,
        discoveryIssue: outcome.primaryIssue,
      );
    } catch (error) {
      _logger.warning('[TV][DISCOVERY] scan_failed type=${error.runtimeType}');
      state = state.copyWith(
        isDiscovering: false,
        discoveryIssue: TvDiscoveryIssue.failed,
      );
    }
  }

  final List<TvDevice> _manualDevices = [];

  /// Keeps devices the user added by address visible across rescans, since
  /// discovery by definition can't see them.
  List<TvDevice> _withManualDevices(List<TvDevice> discovered) {
    final ids = {for (final d in discovered) d.id};
    return [
      ...discovered,
      for (final d in _manualDevices)
        if (!ids.contains(d.id)) d,
    ];
  }

  /// Asks every provider whether a TV answers at [host]. Returns how many
  /// devices were added; 0 means nothing recognizable answered.
  Future<int> addDeviceByAddress(String host) async {
    final trimmed = host.trim();
    if (trimmed.isEmpty) return 0;
    state = state.copyWith(isProbing: true);
    try {
      final found = await _ref
          .read(tvProviderRegistryProvider)
          .probeAll(trimmed);
      for (final device in found) {
        _manualDevices.removeWhere((d) => d.id == device.id);
        _manualDevices.add(device);
      }
      state = state.copyWith(
        discoveredDevices: _withManualDevices(
          state.discoveredDevices
              .where((d) => !found.any((f) => f.id == d.id))
              .toList(),
        ),
        isProbing: false,
      );
      return found.length;
    } catch (error) {
      _logger.warning('[TV][DISCOVERY] probe_failed type=${error.runtimeType}');
      state = state.copyWith(isProbing: false);
      return 0;
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
