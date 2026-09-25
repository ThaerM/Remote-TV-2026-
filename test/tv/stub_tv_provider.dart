import 'dart:async';

import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

/// Minimal scripted [TvProvider] for registry/controller/screen tests that
/// care about discovery and probing, not a real protocol.
class StubTvProvider implements TvProvider {
  StubTvProvider({
    required this.platform,
    this.outcome = const TvDiscoveryOutcome(),
    this.discoverError,
    this.probeResult,
    this.probeError,
    this.capabilities = TvCapabilities.none,
    this.connectError,
    this.commandError,
    this.pairingRequest,
  });

  @override
  final TvPlatform platform;
  TvDiscoveryOutcome outcome;
  final Object? discoverError;
  TvDevice? probeResult;
  final Object? probeError;
  final probedHosts = <String>[];
  TvCapabilities capabilities;
  Object? connectError;
  Object? commandError;

  /// When set, [connect] asks for this pairing instead of connecting.
  TvPairingRequest? pairingRequest;
  int connectCalls = 0;
  int disconnectCalls = 0;
  final _states = StreamController<TvConnectionState>.broadcast();

  @override
  Future<TvDiscoveryOutcome> discover() async {
    if (discoverError != null) throw discoverError!;
    return outcome;
  }

  @override
  Future<TvDevice?> probeHost(String host) async {
    probedHosts.add(host);
    if (probeError != null) throw probeError!;
    return probeResult;
  }

  /// Pairingless by default: reports connected as soon as [connect] is
  /// called, unless [connectError] or [pairingRequest] is set.
  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    connectCalls++;
    if (connectError != null) throw connectError!;
    if (pairingRequest case final request?) {
      _states.add(TvConnectionState.pairingRequired);
      return request;
    }
    _states.add(TvConnectionState.connected);
    return TvPairingRequest.none;
  }

  final submittedCodes = <String>[];

  @override
  Future<void> submitPairingCode(String code) async {
    submittedCodes.add(code);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _states.add(TvConnectionState.disconnected);
  }

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  @override
  Future<TvCapabilities> getCapabilities() async => capabilities;

  @override
  Future<void> sendCommand(TvCommand command) async {
    if (commandError != null) throw commandError!;
  }

  @override
  Future<List<TvApplication>> getApplications() async => const [];
}
