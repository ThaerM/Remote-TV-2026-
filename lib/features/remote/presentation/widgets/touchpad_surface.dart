import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';
import '../../../settings/application/settings_controller.dart';

/// Swipe-to-navigate alternative to [DpadControl], selected via Settings
/// > Remote Layout.
///
/// The Android TV Remote protocol (and every other provider's
/// `TvCommandKey` vocabulary) has no raw pointer/mouse-move command -
/// only discrete directional key events. This surface is therefore a
/// gesture-to-key translator, not a real trackpad: a swipe past a small
/// distance threshold fires one `dpad*` command per threshold crossed
/// (so a longer/faster swipe can repeat), and a tap sends `select`. This
/// is an honest mapping onto real capabilities, not a simulated pointer.
class TouchpadSurface extends ConsumerStatefulWidget {
  const TouchpadSurface({
    required this.onCommand,
    this.theaterModeEnabled = false,
    super.key,
  });

  final void Function(TvCommandKey key) onCommand;

  /// Dims the decorative touch glow - Theater Mode keeps the surface dark
  /// and calm without touching gesture behavior.
  final bool theaterModeEnabled;

  @override
  ConsumerState<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends ConsumerState<TouchpadSurface> {
  static const double _stepDistance = 28;

  Offset? _touchPosition;
  Offset _accumulated = Offset.zero;

  bool get _hapticsEnabled => ref.read(
    settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
  );

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
      _accumulated = Offset.zero;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() => _touchPosition = details.localPosition);
    _accumulated += details.delta;

    while (_accumulated.dx.abs() >= _stepDistance ||
        _accumulated.dy.abs() >= _stepDistance) {
      if (_accumulated.dx.abs() > _accumulated.dy.abs()) {
        widget.onCommand(
          _accumulated.dx > 0 ? TvCommandKey.dpadRight : TvCommandKey.dpadLeft,
        );
        _accumulated -= Offset(_stepDistance * _accumulated.dx.sign, 0);
      } else {
        widget.onCommand(
          _accumulated.dy > 0 ? TvCommandKey.dpadDown : TvCommandKey.dpadUp,
        );
        _accumulated -= Offset(0, _stepDistance * _accumulated.dy.sign);
      }
      if (_hapticsEnabled) HapticFeedback.selectionClick();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _touchPosition = null;
      _accumulated = Offset.zero;
    });
  }

  void _handleTap() {
    if (_hapticsEnabled) HapticFeedback.mediumImpact();
    widget.onCommand(TvCommandKey.select);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Touchpad. Swipe to navigate, tap to select.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: Container(
          width: double.infinity,
          height: AppControlSize.dpadDiameter + 40,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                AppColors.glow.withValues(
                  alpha: widget.theaterModeEnabled ? 0.03 : 0.07,
                ),
                Colors.transparent,
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 28,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Swipe to navigate\nTap to select',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (_touchPosition != null && !reducedMotion)
                AnimatedPositioned(
                  duration: AppMotion.fast,
                  left: _touchPosition!.dx - 28,
                  top: _touchPosition!.dy - 28,
                  child: IgnorePointer(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glow.withValues(alpha: 0.18),
                        border: Border.all(
                          color: AppColors.glow.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
