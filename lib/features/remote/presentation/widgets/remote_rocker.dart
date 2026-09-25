import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../settings/application/settings_controller.dart';

/// A physical-rocker-style control for volume/channel: a single pill
/// with an up/increase half and a down/decrease half, separated by a
/// hairline - closer to a real remote's rocker switch than two separate
/// round buttons. Press-and-hold repeats. An optional widget (an icon,
/// or a short label like "CH") can be slotted between the two halves.
class RemoteRocker extends ConsumerStatefulWidget {
  const RemoteRocker({
    required this.onIncrease,
    required this.onDecrease,
    required this.increaseSemanticLabel,
    required this.decreaseSemanticLabel,
    this.icon,
    this.dimmed = false,
    super.key,
  });

  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final String increaseSemanticLabel;
  final String decreaseSemanticLabel;

  /// Optional slot between the two halves (e.g. a mute icon, or a
  /// short "CH" label for the channel rocker).
  final Widget? icon;

  /// Theater Mode: lower-contrast border, same functionality.
  final bool dimmed;

  @override
  ConsumerState<RemoteRocker> createState() => _RemoteRockerState();
}

class _RemoteRockerState extends ConsumerState<RemoteRocker> {
  _RockerHalf? _held;

  void _startRepeating(_RockerHalf half, VoidCallback action) async {
    setState(() => _held = half);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    while (_held == half && mounted) {
      action();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  void _stopRepeating() => setState(() => _held = null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );
    final borderColor = theme.dividerColor.withValues(
      alpha: widget.dimmed ? 0.35 : 1,
    );

    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RockerButton(
            icon: Icons.add_rounded,
            semanticLabel: widget.increaseSemanticLabel,
            hapticsEnabled: hapticsEnabled,
            pressed: _held == _RockerHalf.up,
            onTap: widget.onIncrease,
            onTapDown: () => _startRepeating(_RockerHalf.up, widget.onIncrease),
            onTapUp: _stopRepeating,
            onTapCancel: _stopRepeating,
          ),
          Divider(height: 1, color: borderColor),
          if (widget.icon != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: widget.icon,
            ),
            Divider(height: 1, color: borderColor),
          ],
          _RockerButton(
            icon: Icons.remove_rounded,
            semanticLabel: widget.decreaseSemanticLabel,
            hapticsEnabled: hapticsEnabled,
            pressed: _held == _RockerHalf.down,
            onTap: widget.onDecrease,
            onTapDown: () =>
                _startRepeating(_RockerHalf.down, widget.onDecrease),
            onTapUp: _stopRepeating,
            onTapCancel: _stopRepeating,
          ),
        ],
      ),
    );
  }
}

enum _RockerHalf { up, down }

class _RockerButton extends StatelessWidget {
  const _RockerButton({
    required this.icon,
    required this.semanticLabel,
    required this.hapticsEnabled,
    required this.pressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final IconData icon;
  final String semanticLabel;
  final bool hapticsEnabled;
  final bool pressed;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      hapticsEnabled: hapticsEnabled,
      semanticLabel: semanticLabel,
      scaleFactor: 0.9,
      onTap: onTap,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 44,
        height: 40,
        color: pressed
            ? AppColors.glow.withValues(alpha: 0.14)
            : Colors.transparent,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: theme.iconTheme.color),
      ),
    );
  }
}
