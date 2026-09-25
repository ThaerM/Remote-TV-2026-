import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../../tv/domain/tv_domain.dart';
import '../../../settings/application/settings_controller.dart';

/// Directional pad used when [TvCapabilities.dpad] is true and the user's
/// Remote Layout preference is D-pad (vs. touchpad - see
/// `TouchpadSurface`).
class DpadControl extends StatelessWidget {
  const DpadControl({
    this.theaterModeEnabled = false,
    required this.onCommand,
    super.key,
  });

  final void Function(TvCommandKey key) onCommand;

  /// Dims the decorative outer glow - Theater Mode keeps the surface
  /// dark and calm without touching command behavior or hit targets.
  final bool theaterModeEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const footprint = AppControlSize.dpadDiameter + 16;
    return SizedBox(
      width: footprint,
      height: footprint,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // A soft ambient glow behind the housing gives the control real
          // depth instead of a flat disc - subdued rather than removed
          // under Theater Mode, so the surface still reads as "on."
          Container(
            width: footprint,
            height: footprint,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.glow.withValues(
                    alpha: theaterModeEnabled ? 0.05 : 0.12,
                  ),
                  AppColors.glow.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: AppControlSize.dpadDiameter,
            height: AppControlSize.dpadDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerColor),
            ),
          ),
          // The ring the Select button sits inside - separates the
          // "select" hierarchy from the four directional presses around
          // it, the way a real remote's raised center cluster reads.
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            top: 8,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              semanticLabel: 'Navigate Up',
              onTap: () => onCommand(TvCommandKey.dpadUp),
            ),
          ),
          Positioned(
            bottom: 8,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticLabel: 'Navigate Down',
              onTap: () => onCommand(TvCommandKey.dpadDown),
            ),
          ),
          Positioned(
            left: 8,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              semanticLabel: 'Navigate Left',
              onTap: () => onCommand(TvCommandKey.dpadLeft),
            ),
          ),
          Positioned(
            right: 8,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              semanticLabel: 'Navigate Right',
              onTap: () => onCommand(TvCommandKey.dpadRight),
            ),
          ),
          _DpadButton(
            icon: Icons.circle,
            iconSize: 12,
            isPrimary: true,
            semanticLabel: 'Select',
            onTap: () => onCommand(TvCommandKey.select),
          ),
        ],
      ),
    );
  }
}

class _DpadButton extends ConsumerStatefulWidget {
  const _DpadButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 22,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double iconSize;
  final bool isPrimary;

  @override
  ConsumerState<_DpadButton> createState() => _DpadButtonState();
}

class _DpadButtonState extends ConsumerState<_DpadButton> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.isPrimary ? 52.0 : 40.0;
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );

    return PressableScale(
      hapticsEnabled: hapticsEnabled,
      semanticLabel: widget.semanticLabel,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.isPrimary
              ? theme.colorScheme.primary
              : (_pressed
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent),
          shape: BoxShape.circle,
          border: !widget.isPrimary && _pressed
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.isPrimary
              ? theme.colorScheme.onPrimary
              : theme.iconTheme.color,
        ),
      ),
    );
  }
}
