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

  static const _okDiameter = 92.0;

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
          // Cross-shaped separation lines from the OK button's edge out to
          // the disc's edge - the subtle housing seams a physical D-pad
          // has between its Up/Down/Left/Right zones.
          SizedBox(
            width: AppControlSize.dpadDiameter,
            height: AppControlSize.dpadDiameter,
            child: CustomPaint(
              painter: _SpokesPainter(
                color: borderColor.withValues(alpha: 0.6),
                innerRadius: _okDiameter / 2,
              ),
            ),
          ),
          Positioned(
            top: 22,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              semanticLabel: 'Navigate Up',
              theaterModeEnabled: theaterModeEnabled,
              onTap: () => onCommand(TvCommandKey.dpadUp),
            ),
          ),
          Positioned(
            bottom: 22,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticLabel: 'Navigate Down',
              theaterModeEnabled: theaterModeEnabled,
              onTap: () => onCommand(TvCommandKey.dpadDown),
            ),
          ),
          Positioned(
            left: 22,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              semanticLabel: 'Navigate Left',
              theaterModeEnabled: theaterModeEnabled,
              onTap: () => onCommand(TvCommandKey.dpadLeft),
            ),
          ),
          Positioned(
            right: 22,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              semanticLabel: 'Navigate Right',
              theaterModeEnabled: theaterModeEnabled,
              onTap: () => onCommand(TvCommandKey.dpadRight),
            ),
          ),
          _DpadButton(
            isPrimary: true,
            semanticLabel: 'Select',
            theaterModeEnabled: theaterModeEnabled,
            onTap: () => onCommand(TvCommandKey.select),
          ),
        ],
      ),
    );
  }
}

class _DpadButton extends ConsumerStatefulWidget {
  const _DpadButton({
    required this.onTap,
    required this.semanticLabel,
    this.icon,
    this.isPrimary = false,
    this.theaterModeEnabled = false,
  });

  final IconData? icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool isPrimary;
  final bool theaterModeEnabled;

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
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );
    final accentAlpha = widget.theaterModeEnabled ? 0.55 : 1.0;
    final accent = AppColors.glow.withValues(alpha: accentAlpha);

    if (widget.isPrimary) {
      // The OK/Select button is the D-pad's visual hero: a large solid
      // cyan disc with an "OK" label - not a dot icon - matching the
      // approved hardware-remote reference. Theater Mode swaps the
      // solid fill for a dim outline so it reads as "present but calm."
      return PressableScale(
        hapticsEnabled: hapticsEnabled,
        semanticLabel: widget.semanticLabel,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: DpadControl._okDiameter,
          height: DpadControl._okDiameter,
          decoration: BoxDecoration(
            color: widget.theaterModeEnabled
                ? Colors.transparent
                : AppColors.glow.withValues(alpha: _pressed ? 1 : 0.92),
            shape: BoxShape.circle,
            border: widget.theaterModeEnabled
                ? Border.all(color: accent, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(
                  alpha:
                      (widget.theaterModeEnabled ? 0.12 : 0.3) *
                      (_pressed ? 1.4 : 1),
                ),
                blurRadius: _pressed ? 18 : 12,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          // The "OK" label is decorative - PressableScale already
          // supplies the real "Select" semantic label above, and an
          // un-excluded Text here would merge its own "OK" label into
          // that node instead of just displaying visually.
          child: ExcludeSemantics(
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: widget.theaterModeEnabled
                    ? accent
                    : AppColors.darkBackground,
              ),
            ),
          ),
        ),
      );
    }

    return PressableScale(
      hapticsEnabled: hapticsEnabled,
      semanticLabel: widget.semanticLabel,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _pressed ? accent.withValues(alpha: 0.14) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, size: 26, color: accent),
      ),
    );
  }
}

class _SpokesPainter extends CustomPainter {
  const _SpokesPainter({required this.color, required this.innerRadius});

  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2;
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
      oldDelegate.color != color || oldDelegate.innerRadius != innerRadius;
}
