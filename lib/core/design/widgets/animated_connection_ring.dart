import 'package:flutter/material.dart';

/// A soft ring that expands and fades around [child], looping while
/// [active] is true. Used behind a TV/device icon during connecting/
/// pairing states.
///
/// Respects `MediaQuery.disableAnimations` (the platform's reduced-motion
/// setting): when set, the ring is drawn as a single static outline
/// instead of animating, per the design direction's accessibility
/// requirement.
class AnimatedConnectionRing extends StatefulWidget {
  const AnimatedConnectionRing({
    required this.child,
    required this.active,
    this.color = const Color(0xFF4FD1FF),
    this.size = 96,
    super.key,
  });

  final Widget child;
  final bool active;
  final Color color;
  final double size;

  @override
  State<AnimatedConnectionRing> createState() => _AnimatedConnectionRingState();
}

class _AnimatedConnectionRingState extends State<AnimatedConnectionRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedConnectionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active && !reducedMotion)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
                  child: Container(
                    width: widget.size * (0.7 + 0.3 * t),
                    height: widget.size * (0.7 + 0.3 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color, width: 2),
                    ),
                  ),
                );
              },
            )
          else if (widget.active)
            Container(
              width: widget.size * 0.85,
              height: widget.size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}
