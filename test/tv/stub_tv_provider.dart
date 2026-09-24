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
  });

  @override
  final TvPlatform platform;
  TvDiscoveryOutcome outcome;
  final Object? discoverError;
  TvDevice? probeResult;
  final Object? probeError;
  final probedHosts = <String>[];

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

  @override
  Future<TvPairingRequest> connect(TvDevice device) async =>
      TvPairingRequest.none;

  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<TvConnectionState> get connectionState => const Stream.empty();

  @override
  Future<TvCapabilities> getCapabilities() async => TvCapabilities.none;

  @override
  Future<void> sendCommand(TvCommand command) async {}

  @override
  Future<List<TvApplication>> getApplications() async => const [];
}
