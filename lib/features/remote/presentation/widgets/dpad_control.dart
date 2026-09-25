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
    // A single physical control surface: one near-black/graphite disc,
    // not four Material buttons scattered around a circle - so the
    // housing is deliberately darker than the panel it sits on.
    final discColor = theme.brightness == Brightness.dark
        ? AppColors.darkSurface
        : theme.cardTheme.color;
    final borderColor = theme.dividerColor.withValues(
      alpha: theaterModeEnabled ? 0.35 : 0.6,
    );

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
                    alpha: theaterModeEnabled ? 0.04 : 0.1,
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
              color: discColor,
              border: Border.all(color: borderColor),
            ),
          ),
          // Faint radial spokes at the four compass points - the subtle
          // separation lines a physical D-pad's cross housing has
          // between its Up/Down/Left/Right zones.
          SizedBox(
            width: AppControlSize.dpadDiameter,
            height: AppControlSize.dpadDiameter,
            child: CustomPaint(
              painter: _SpokesPainter(
                color: borderColor.withValues(alpha: 0.5),
              ),
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
              border: Border.all(color: borderColor),
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

    // The OK/Select button is the D-pad's visual hero: a dark hardware
    // button with a restrained cyan accent ring and glow, not a solid
    // brand-green fill - the four directional zones stay unaccented so
    // the accent reads as "this is the one that matters."
    final okFill = theme.brightness == Brightness.dark
        ? AppColors.darkSurfaceRaised
        : theme.cardTheme.color;

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
              ? okFill
              : (_pressed
                    ? AppColors.glow.withValues(alpha: 0.14)
                    : Colors.transparent),
          shape: BoxShape.circle,
          border: widget.isPrimary
              ? Border.all(
                  color: AppColors.glow.withValues(alpha: _pressed ? 1 : 0.7),
                  width: 1.5,
                )
              : (_pressed
                    ? Border.all(color: AppColors.glow.withValues(alpha: 0.5))
                    : null),
          boxShadow: widget.isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.glow.withValues(
                      alpha: _pressed ? 0.45 : 0.25,
                    ),
                    blurRadius: _pressed ? 14 : 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.isPrimary ? AppColors.glow : theme.iconTheme.color,
        ),
      ),
    );
  }
}

class _SpokesPainter extends CustomPainter {
  const _SpokesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    const innerRadius = 42.0;
    final outerRadius = size.width / 2 - 4;
    const directions = [
      Offset(0, -1), // top
      Offset(1, 0), // right
      Offset(0, 1), // bottom
      Offset(-1, 0), // left
    ];
    for (final direction in directions) {
      canvas.drawLine(
        center + direction * innerRadius,
        center + direction * outerRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpokesPainter oldDelegate) =>
      oldDelegate.color != color;
}
