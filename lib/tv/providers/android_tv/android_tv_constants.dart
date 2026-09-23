/// Protocol constants for the Android TV Remote v2 protocol.
///
/// Ports and the mDNS service type match the behavior of the
/// `androidtvremote2` reference implementation (Apache-2.0) - see
/// `docs/research/android-google-tv.md` for sourcing.
abstract final class AndroidTvConstants {
  /// mDNS/Bonjour service type advertised by Android TV Remote-capable
  /// devices on the local network.
  static const String mdnsServiceType = '_androidtvremote2._tcp';

  /// Port used for the initial certificate-pairing handshake.
  static const int pairingPort = 6467;

  /// Port used for the authenticated remote-control connection, reused
  /// on every reconnect once a device has been paired.
  static const int remoteControlPort = 6466;

  /// Shown as the pairing client name on the TV during pairing.
  static const String clientName = 'Remote TV 2026';

  /// Service name sent in the pairing request, matching the reference
  /// implementation's identifier so the TV's pairing UI behaves as
  /// expected.
  static const String pairingServiceName = 'atvremote';

  /// Pairing codes shown on the TV are always 6 hex digits.
  static const int pairingCodeLength = 6;

  static const Duration pairingTimeout = Duration(seconds: 10);
  static const Duration connectTimeout = Duration(seconds: 8);

  /// The device closes an idle remote connection after ~16s without
  /// traffic (it pings every 5s otherwise); matched by
  /// `RemoteSession`'s own idle watchdog so we disconnect deliberately
  /// rather than being dropped.
  static const Duration idleDisconnectAfter = Duration(seconds: 16);
}
