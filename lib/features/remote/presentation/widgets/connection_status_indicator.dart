import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';

/// A small dot + label representing [TvConnectionState], used in the
/// Remote header and the device switcher. `connecting`/`reconnecting`
/// pulse gently; `connected` and `disconnected` are static - motion is
/// reserved for states that are actually in flux.
class ConnectionStatusIndicator extends StatefulWidget {
  const ConnectionStatusIndicator({
    required this.state,
    this.compact = false,
    super.key,
  });

  final TvConnectionState state;
  final bool compact;

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _colorFor(TvConnectionState state) => switch (state) {
    TvConnectionState.connected => AppColors.connected,
    TvConnectionState.connecting => AppColors.connecting,
    TvConnectionState.pairingRequired => AppColors.connecting,
    TvConnectionState.reconnecting => AppColors.reconnecting,
    TvConnectionState.disconnected => AppColors.disconnected,
    TvConnectionState.error => AppColors.danger,
  };

  String _labelFor(TvConnectionState state) => switch (state) {
    TvConnectionState.connected => 'Connected',
    TvConnectionState.connecting => 'Connecting…',
    TvConnectionState.pairingRequired => 'Pairing…',
    TvConnectionState.reconnecting => 'Reconnecting…',
    TvConnectionState.disconnected => 'Offline',
    TvConnectionState.error => 'Error',
  };

  bool get _isPulsing =>
      widget.state == TvConnectionState.connecting ||
      widget.state == TvConnectionState.reconnecting ||
      widget.state == TvConnectionState.pairingRequired;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(widget.state);
    final label = _labelFor(widget.state);

    return Semantics(
      label: 'Connection status: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final opacity = _isPulsing ? 0.4 + (_pulse.value * 0.6) : 1.0;
              return Opacity(opacity: opacity, child: child);
            },
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          if (!widget.compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
