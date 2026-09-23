import '../../../domain/tv_domain.dart';

/// One resolved DNS-SD service instance (Bonjour/mDNS), before a provider
/// turns it into a [TvDevice].
class ServiceDiscoveryResult {
  const ServiceDiscoveryResult({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.txt = const {},
  });

  /// Stable identity: the advertised SRV hostname, never the DHCP IP.
  final String id;

  /// The service instance name (e.g. "Family room TV").
  final String name;

  /// Resolved IPv4 when known, otherwise the `.local` hostname.
  final String host;
  final int port;

  /// TXT record key/value pairs, when the backend collected them (e.g.
  /// Google Cast puts the friendly name in `fn`). Never required.
  final Map<String, String> txt;
}

/// Finds instances of one DNS-SD service type (e.g. `_androidtvremote2._tcp`,
/// `_googlecast._tcp`) on the local network.
///
/// Contract every implementation must honor: `discover()` never throws,
/// never hangs past its timeout, releases every socket/browser it opened,
/// and always logs `[TV][DISCOVERY][<TAG>] started` followed by
/// `[TV][DISCOVERY][<TAG>] completed count=N durationMs=...` - a scan that
/// fails must say why (`resolve_failed stage=... reason=...`) rather than
/// silently returning nothing.
///
/// Two implementations exist because one raw-socket approach does not work
/// everywhere: `MdnsServiceDiscovery` (Android and other non-iOS platforms)
/// speaks mDNS over its own UDP 5353 socket, while
/// `NativeBonjourServiceDiscovery` (iOS) asks the system Bonjour stack,
/// because iOS restricts raw multicast sockets in third-party apps. Each
/// provider picks one by `Platform.isIOS`.
abstract interface class ServiceDiscovery {
  Future<ServiceDiscoveryScan> discover({Duration timeout});
}

/// One scan's answers, plus the [TvDiscoveryIssue] (if any) that may
/// explain missing devices. Finding nothing on a healthy network is not an
/// issue - it's just an empty [results].
class ServiceDiscoveryScan {
  const ServiceDiscoveryScan(this.results, {this.issue});

  final List<ServiceDiscoveryResult> results;
  final TvDiscoveryIssue? issue;
}

String stripTrailingDot(String value) =>
    value.endsWith('.') ? value.substring(0, value.length - 1) : value;

/// Parses DNS-SD TXT strings (`key=value`, one per entry). A key with no
/// `=` is a boolean flag and maps to an empty string.
Map<String, String> parseTxtEntries(Iterable<String> entries) {
  final txt = <String, String>{};
  for (final entry in entries) {
    if (entry.isEmpty) continue;
    final equals = entry.indexOf('=');
    if (equals == 0) continue;
    if (equals < 0) {
      txt[entry.toLowerCase()] = '';
    } else {
      txt[entry.substring(0, equals).toLowerCase()] = entry.substring(
        equals + 1,
      );
    }
  }
  return txt;
}
