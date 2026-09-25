import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../../tv/domain/tv_domain.dart';

/// Premium device card for the discovery list and the device switcher:
/// platform icon, name, a status line or capability badges, and a
/// chevron. Demo devices are always labelled as such - see
/// [TvDevice.isDevelopmentFake]. Never renders transport/protocol
/// internals (service types, endpoint hosts) - only what a person would
/// recognize about their own TV.
class TvDeviceCard extends StatelessWidget {
  const TvDeviceCard({
    required this.device,
    required this.onTap,
    this.statusLabel,
    this.capabilityBadges,
    super.key,
  });

  final TvDevice device;
  final VoidCallback onTap;

  /// Overrides the default platform-name subtitle, e.g. "Connected" or
  /// "Ready to pair" - only ever real state the caller already knows,
  /// never invented. Ignored when [capabilityBadges] is set.
  final String? statusLabel;

  /// When set (a grouped physical TV with more than one endpoint), shown
  /// as small pill badges - e.g. "Remote", "Cast" - instead of
  /// [statusLabel]. Always the plain capability name, never the
  /// underlying provider/protocol.
  final List<String>? capabilityBadges;

  IconData get _icon => switch (device.platform) {
    TvPlatform.fake => Icons.smart_display_outlined,
    TvPlatform.androidTv => Icons.smart_display_rounded,
    _ => Icons.tv_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = capabilityBadges;

    return PressableScale(
      // Discovery isn't a remote-control action, so it stays silent
      // regardless of the user's haptics preference rather than reading
      // SettingsState here just for this one tap.
      hapticsEnabled: false,
      scaleFactor: 0.98,
      semanticLabel: device.name,
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _DeviceIcon(icon: _icon),
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
                    const SizedBox(height: AppSpacing.xs),
                    if (badges != null && badges.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final badge in badges) _CapabilityBadge(badge),
                        ],
                      )
                    else
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
              const SizedBox(width: AppSpacing.xs),
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

/// The platform icon with a small static "available" accent - this card
/// only ever represents a device discovery actually found on the
/// network, so unlike [ConnectionStatusIndicator] (which tracks the
/// live session) this dot never animates or changes color.
class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityBadge extends StatelessWidget {
  const _CapabilityBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: surfaces?.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
