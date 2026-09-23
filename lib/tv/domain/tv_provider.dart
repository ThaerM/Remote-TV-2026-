import 'tv_application.dart';
import 'tv_capabilities.dart';
import 'tv_command.dart';
import 'tv_connection_state.dart';
import 'tv_device.dart';
import 'tv_discovery.dart';
import 'tv_pairing.dart';
import 'tv_platform.dart';

/// A single TV ecosystem's implementation: discovery, pairing, connection
/// and command delivery for one [TvPlatform].
///
/// **No manufacturer-specific branching outside a provider.** UI and shared
/// domain code talk only to this interface (and to [TvCapabilities]); a
/// vendor SDK or protocol client is a private implementation detail of the
/// provider that wraps it.
abstract interface class TvProvider {
  TvPlatform get platform;

  /// Search the local network for devices this provider can control.
  /// Implementations apply their own bounded timeout, never throw, and
  /// report anything that may explain missing devices as a
  /// [TvDiscoveryIssue] rather than silently returning nothing.
  Future<TvDiscoveryOutcome> discover();

  /// Checks whether a device this provider can control answers at [host]
  /// (an IP address or hostname the user typed), for TVs that discovery
  /// can't see - another subnet, a router that blocks multicast, or a
  /// platform that restricts multicast. Returns `null` if nothing
  /// recognizable answers. Must be bounded and never throw.
  Future<TvDevice?> probeHost(String host);

  /// Begin connecting to [device]. If pairing is required, the returned
  /// value describes it and [connectionState] will emit
  /// [TvConnectionState.pairingRequired] until [submitPairingCode] (for PIN
  /// flows) resolves it or the user confirms on-device.
  Future<TvPairingRequest> connect(TvDevice device);

  /// Completes a [TvPinPairingRequest] started by [connect].
  Future<void> submitPairingCode(String code);

  Future<void> disconnect();

  Stream<TvConnectionState> get connectionState;

  /// The capabilities of the currently connected device. Callers should
  /// treat this as unavailable (throw or return [TvCapabilities.none])
  /// unless [connectionState] is `connected`.
  Future<TvCapabilities> getCapabilities();

  /// Sends [command] to the connected device.
  ///
  /// Throws [UnsupportedTvCommandException] if unsupported by the current
  /// device's capabilities, [TvNotConnectedException] if not connected.
  Future<void> sendCommand(TvCommand command);

  /// Apps/channels launchable on the connected device, when
  /// [TvCapabilities.launchApps] is true. Returns an empty list otherwise.
  Future<List<TvApplication>> getApplications();
}
