import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';

/// Premium device card for the discovery list and the device switcher:
/// platform icon, name, a status line, and a chevron. Demo devices are
/// always labelled as such - see [TvDevice.isDevelopmentFake].
class TvDeviceCard extends StatelessWidget {
  const TvDeviceCard({
    required this.device,
    required this.onTap,
    this.statusLabel,
    super.key,
  });

  final TvDevice device;
  final VoidCallback onTap;

  /// Overrides the default platform-name subtitle, e.g. "Connected" or
  /// "Ready to pair" - only ever real state the caller already knows,
  /// never invented.
  final String? statusLabel;

  IconData get _icon => switch (device.platform) {
    TvPlatform.fake => Icons.smart_display_outlined,
    TvPlatform.androidTv => Icons.smart_display_rounded,
    _ => Icons.tv_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel ??
                          (device.isDevelopmentFake
                              ? 'Demo device · not a real TV'
                              : device.platform.displayName),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
