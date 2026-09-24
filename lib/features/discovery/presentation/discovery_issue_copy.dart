import 'package:flutter/material.dart';

import '../../../tv/domain/tv_domain.dart';

/// Human-readable wording for a [TvDiscoveryIssue]. Technical detail
/// (errno, protocol stage) stays in the diagnostics logs.
class DiscoveryIssueCopy {
  const DiscoveryIssueCopy({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  static const noDevices = DiscoveryIssueCopy(
    icon: Icons.wifi_find_rounded,
    title: 'No TVs found',
    body:
        'Make sure your TV is on and connected to the same Wi-Fi network as '
        'this phone. If it still does not appear, add it by its IP address.',
  );

  static DiscoveryIssueCopy forIssue(TvDiscoveryIssue? issue) {
    return switch (issue) {
      null => noDevices,
      TvDiscoveryIssue.localNetworkDenied => const DiscoveryIssueCopy(
        icon: Icons.lock_outline_rounded,
        title: 'Local network access is off',
        body:
            'Remote TV 2026 needs permission to find devices on your '
            'network. Turn it on in Settings > Privacy & Security > Local '
            'Network, then scan again.',
      ),
      TvDiscoveryIssue.networkUnavailable => const DiscoveryIssueCopy(
        icon: Icons.wifi_off_rounded,
        title: 'Not connected to Wi-Fi',
        body:
            'Connect this phone to the same Wi-Fi network as your TV. TVs '
            "can't be found over mobile data.",
      ),
      TvDiscoveryIssue.multicastRestricted => const DiscoveryIssueCopy(
        icon: Icons.router_outlined,
        title: "Automatic search isn't available",
        body:
            'This phone blocked the network search some TVs need. You can '
            'still add your TV by its IP address (on the TV: Settings > '
            'Network > Status).',
      ),
      TvDiscoveryIssue.timedOut => const DiscoveryIssueCopy(
        icon: Icons.timer_outlined,
        title: 'The search took too long',
        body:
            'Your network was slow to answer. Scan again, or add your TV '
            'by its IP address.',
      ),
      TvDiscoveryIssue.failed => const DiscoveryIssueCopy(
        icon: Icons.error_outline_rounded,
        title: "Couldn't finish the search",
        body:
            'Something went wrong while looking for TVs. Scan again, or add '
            'your TV by its IP address. Details are in Settings > '
            'Diagnostics.',
      ),
    };
  }
}
