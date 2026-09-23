import 'package:flutter/material.dart';

/// A calm, low-cost "scanning" visual: a TV icon with 2-3 concentric
/// rings that fade outward on a loop, used while [DiscoveryScreen] is
/// scanning.
///
/// Deliberately not a particle system or a custom-painted radar sweep -
/// three staggered [AnimatedBuilder]s repainting a ring each is cheap
/// (no shaders, no per-frame layout), and stops entirely once discovery
/// finishes or the widget leaves the tree. Respects
/// `MediaQuery.disableAnimations` by rendering a single static ring.
class DiscoveryRadar extends StatefulWidget {
  const DiscoveryRadar({this.size = 160, super.key});

  final double size;

  @override
  State<DiscoveryRadar> createState() => _DiscoveryRadarState();
}

class _DiscoveryRadarState extends State<DiscoveryRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (reducedMotion)
            _Ring(
              fraction: 0.7,
              opacity: 0.3,
              color: color,
              maxSize: widget.size,
            )
          else
            for (final phase in [0.0, 0.33, 0.66])
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = (_controller.value + phase) % 1.0;
                  return _Ring(
                    fraction: t,
                    opacity: (1 - t) * 0.5,
                    color: color,
                    maxSize: widget.size,
                  );
                },
              ),
          Icon(Icons.tv_rounded, size: widget.size * 0.28, color: color),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.fraction,
    required this.opacity,
    required this.color,
    required this.maxSize,
  });

  final double fraction;
  final double opacity;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final size = maxSize * (0.35 + fraction * 0.65);
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }
}
