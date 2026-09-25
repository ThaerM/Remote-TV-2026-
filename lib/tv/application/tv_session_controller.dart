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
    this.mediaStatus,
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

  /// What a casting-capable device is playing, when it reports it.
  final TvMediaStatus? mediaStatus;
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
    TvMediaStatus? mediaStatus,
    bool clearMediaStatus = false,
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
      mediaStatus: clearMediaStatus ? null : (mediaStatus ?? this.mediaStatus),
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
  StreamSubscription<TvMediaStatus?>? _mediaSub;
  TvProvider? _activeProvider;

  Future<void> discover() async {
    // One scan at a time: overlapping scans would contend for the same
    // mDNS/SSDP sockets and native Bonjour browsers.
    if (state.isDiscovering) return;
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
  /// discovery by definition can't see them. A manual entry is dropped once
  /// discovery finds the same service (same platform at the same host)
  /// under its discovered identity, so one TV never shows twice.
  List<TvDevice> _withManualDevices(List<TvDevice> discovered) {
    bool alreadyFound(TvDevice manual) => discovered.any(
      (d) =>
          d.id == manual.id ||
          (d.platform == manual.platform &&
              d.host != null &&
              d.host == manual.host),
    );
    return [
      ...discovered,
      for (final d in _manualDevices)
        if (!alreadyFound(d)) d,
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
    final previous = _activeProvider;
    if (previous != null && !identical(previous, provider)) {
      // Switching to a TV owned by another provider: close the old
      // connection instead of leaving it running in the background.
      try {
        await previous.disconnect();
      } catch (error) {
        _logger.warning(
          '[TV][CONNECTION] previous_disconnect_failed '
          'type=${error.runtimeType}',
        );
      }
    }
    _activeProvider = provider;
    unawaited(_connectionSub?.cancel());
    _connectionSub = provider.connectionState.listen((connectionState) {
      state = state.copyWith(connectionState: connectionState);
      if (connectionState == TvConnectionState.connected) {
        unawaited(_loadConnectedDeviceDetails());
      }
    });

    unawaited(_mediaSub?.cancel());
    _mediaSub = null;
    if (provider case final TvMediaCaster caster) {
      _mediaSub = caster.mediaStatus.listen((status) {
        state = status == null
            ? state.copyWith(clearMediaStatus: true)
            : state.copyWith(mediaStatus: status);
      });
    }

    // The previous device's controls must never render for the new one.
    state = state.copyWith(
      selectedDevice: device,
      capabilities: TvCapabilities.none,
      applications: const [],
      clearPairingRequest: true,
      clearError: true,
      clearMediaStatus: true,
    );
    try {
      final pairingRequest = await provider.connect(device);
      if (!identical(_activeProvider, provider)) return;
      state = state.copyWith(pairingRequest: pairingRequest);
    } catch (error) {
      _logger.warning(
        '[TV][CONNECTION] connect_failed platform=${device.platform.name} '
        'type=${error.runtimeType}',
      );
      state = state.copyWith(lastError: 'Could not connect to ${device.name}.');
    }
  }

  Future<void> submitPairingCode(String input) async {
    final provider = _activeProvider;
    if (provider == null) return;
    var code = input;
    if (state.pairingRequest case final TvPinPairingRequest request) {
      final valid = request.validate(input);
      if (valid == null) {
        // Rejected before anything is sent to the TV.
        state = state.copyWith(
          lastError:
              'Enter the ${request.expectedLength}-character pairing code '
              'shown on your TV.',
        );
        return;
      }
      code = valid;
    }
    state = state.copyWith(clearError: true);
    try {
      await provider.submitPairingCode(code);
      state = state.copyWith(clearPairingRequest: true, clearError: true);
    } on PairingTimeoutException {
      _logger.warning('[TV][PAIRING] submit_timed_out');
      state = state.copyWith(
        lastError: 'The TV did not respond. Go back and select it again.',
      );
    } catch (error) {
      // Never log the code or the error text (which could echo it).
      _logger.warning('[TV][PAIRING] submit_failed type=${error.runtimeType}');
      state = state.copyWith(lastError: 'Incorrect pairing code.');
    }
  }

  /// Abandons an unfinished pairing (the user left the pairing screen), so
  /// the TV's pairing socket doesn't stay open behind the user's back.
  Future<void> cancelPairing() async {
    if (_activeProvider == null || state.isConnected) return;
    await disconnect();
  }

  Future<void> _loadConnectedDeviceDetails() async {
    final provider = _activeProvider;
    if (provider == null) return;
    try {
      final capabilities = await provider.getCapabilities();
      final applications = await provider.getApplications();
      if (!identical(_activeProvider, provider) || !mounted) return;
      state = state.copyWith(
        capabilities: capabilities,
        applications: applications,
      );
    } catch (error) {
      _logger.warning(
        '[TV][CONNECTION] details_failed type=${error.runtimeType}',
      );
    }
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
      // Type and command kind only: a text command's payload is whatever
      // the user typed.
      _logger.warning(
        '[TV][COMMAND] failed type=${error.runtimeType} '
        'command=${command.type.name}',
      );
      state = state.copyWith(lastError: error.message);
    } catch (error) {
      _logger.warning(
        '[TV][COMMAND] failed type=${error.runtimeType} '
        'command=${command.type.name}',
      );
      state = state.copyWith(lastError: 'The TV did not accept that command.');
    }
  }

  /// The active provider's casting surface, when the connected device can
  /// cast. Capability-gated - never a platform check.
  TvMediaCaster? get _caster {
    if (!state.capabilities.casting) return null;
    return switch (_activeProvider) {
      final TvMediaCaster caster => caster,
      _ => null,
    };
  }

  /// Returns a human-readable error, or null on success.
  Future<String?> castMedia(TvMediaItem item) =>
      _mediaAction((caster) => caster.castMedia(item));

  Future<String?> togglePlayback() =>
      _mediaAction((caster) => caster.togglePlayback());

  Future<String?> seekMedia(Duration position) =>
      _mediaAction((caster) => caster.seek(position));

  Future<String?> stopMedia() => _mediaAction((caster) => caster.stopMedia());

  Future<String?> _mediaAction(
    Future<void> Function(TvMediaCaster caster) action,
  ) async {
    final caster = _caster;
    if (caster == null) return 'This TV does not support casting.';
    try {
      await action(caster);
      return null;
    } on TvException catch (error) {
      _logger.warning('[TV][CAST] action_failed type=${error.runtimeType}');
      return error.message;
    } catch (error) {
      _logger.warning('[TV][CAST] action_failed type=${error.runtimeType}');
      return 'The TV could not complete that action.';
    }
  }

  Future<void> disconnect() async {
    final provider = _activeProvider;
    _activeProvider = null;
    unawaited(_connectionSub?.cancel());
    _connectionSub = null;
    unawaited(_mediaSub?.cancel());
    _mediaSub = null;
    try {
      await provider?.disconnect();
    } catch (error) {
      _logger.warning(
        '[TV][CONNECTION] disconnect_failed type=${error.runtimeType}',
      );
    }
    // Keep the scan results: the TVs are still on the network.
    state = TvSessionState(
      discoveredDevices: state.discoveredDevices,
      discoveryIssue: state.discoveryIssue,
    );
  }

  @override
  void dispose() {
    unawaited(_connectionSub?.cancel());
    unawaited(_mediaSub?.cancel());
    super.dispose();
  }
}

final tvSessionControllerProvider =
    StateNotifierProvider<TvSessionController, TvSessionState>((ref) {
      return TvSessionController(ref);
    });
