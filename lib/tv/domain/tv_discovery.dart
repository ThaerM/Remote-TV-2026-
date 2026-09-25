import 'tv_device.dart';

/// Why a scan may have found fewer TVs than exist. Providers report these
/// instead of throwing, so the UI can say something actionable rather than
/// a bare "No TVs found". Technical detail stays in the logs.
enum TvDiscoveryIssue {
  /// The OS denied local network access to this app (iOS Local Network
  /// privacy, for example).
  localNetworkDenied,

  /// The OS refused raw multicast for this app, so this provider's
  /// discovery protocol (mDNS/SSDP over its own socket) can't run. Adding
  /// the TV by address still works.
  multicastRestricted,

  /// No usable network (Wi-Fi off, no route, cellular only).
  networkUnavailable,

  /// The scan ran out of time before the protocol answered.
  timedOut,

  /// The provider's discovery failed for another reason (see logs).
  failed;

  /// Lower is more specific/actionable - used to pick the one message to
  /// show when several providers report different issues.
  int get priority => switch (this) {
    TvDiscoveryIssue.localNetworkDenied => 0,
    TvDiscoveryIssue.networkUnavailable => 1,
    TvDiscoveryIssue.multicastRestricted => 2,
    TvDiscoveryIssue.timedOut => 3,
    TvDiscoveryIssue.failed => 4,
  };
}

/// What one scan produced: the devices found, plus any issues that may
/// explain missing ones. A scan can both find devices and report issues
/// (e.g. one provider worked, another was restricted).
class TvDiscoveryOutcome {
  const TvDiscoveryOutcome({this.devices = const [], this.issues = const {}});

  TvDiscoveryOutcome.issue(TvDiscoveryIssue issue)
    : devices = const [],
      issues = {issue};

  final List<TvDevice> devices;
  final Set<TvDiscoveryIssue> issues;

  /// The single most actionable issue, if any.
  TvDiscoveryIssue? get primaryIssue {
    final sorted = issues.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.isEmpty ? null : sorted.first;
  }

  static TvDiscoveryOutcome merge(Iterable<TvDiscoveryOutcome> outcomes) {
    return TvDiscoveryOutcome(
      devices: [for (final o in outcomes) ...o.devices],
      issues: {for (final o in outcomes) ...o.issues},
    );
  }
}
