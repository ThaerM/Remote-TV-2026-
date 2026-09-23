import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_spacing.dart';

/// Wraps [child] with the app's standard tactile press feedback: a small
/// scale-down (1.0 -> 0.96) on press, springing back on release, plus
/// haptic feedback gated on the user's Settings preference.
///
/// Used by every remote control (D-pad, rocker, action buttons) so the
/// "press" feel is consistent everywhere without each widget
/// reimplementing it - see docs/design/design-system.md ("Motion system").
///
/// The scale animation never delays [onTap]/[onTapDown]/[onTapUp]: those
/// fire immediately, independent of the animation's own timing, since
/// remote responsiveness matters more than motion polish.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.hapticsEnabled = true,
    this.scaleFactor = 0.96,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<TapDownDetails>? onTapDown;
  final ValueChanged<TapUpDetails>? onTapUp;
  final VoidCallback? onTapCancel;
  final bool hapticsEnabled;
  final double scaleFactor;
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _pressed ? widget.scaleFactor : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: widget.child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (details) {
        _setPressed(true);
        if (widget.hapticsEnabled) HapticFeedback.selectionClick();
        widget.onTapDown?.call(details);
      },
      onTapUp: (details) {
        _setPressed(false);
        widget.onTapUp?.call(details);
      },
      onTapCancel: () {
        _setPressed(false);
        widget.onTapCancel?.call();
      },
      child: widget.semanticLabel != null
          ? Semantics(button: true, label: widget.semanticLabel, child: content)
          : content,
    );
  }
}
