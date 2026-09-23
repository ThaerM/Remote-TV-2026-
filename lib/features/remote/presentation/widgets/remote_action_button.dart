import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../settings/application/settings_controller.dart';

/// A single labelled circular remote button, used for volume, power, home,
/// back, menu, etc. Long-press repeats [onCommand] while held, for
/// volume/channel-style controls - see docs/design/design-system.md.
class RemoteActionButton extends ConsumerStatefulWidget {
  const RemoteActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = AppControlSize.secondaryButton,
    this.repeatWhileHeld = false,
    this.emphasized = false,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final bool repeatWhileHeld;
  final bool emphasized;

  /// Overrides the accessibility label; defaults to [label] when set,
  /// falling back to the icon alone otherwise (e.g. "Volume Up" for a
  /// bare `+` button with no visible label).
  final String? semanticLabel;

  @override
  ConsumerState<RemoteActionButton> createState() => _RemoteActionButtonState();
}

class _RemoteActionButtonState extends ConsumerState<RemoteActionButton> {
  bool _held = false;

  void _startRepeating() async {
    if (!widget.repeatWhileHeld) return;
    _held = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    while (_held && mounted) {
      widget.onPressed();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  void _stopRepeating() {
    _held = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressableScale(
          hapticsEnabled: hapticsEnabled,
          semanticLabel:
              widget.semanticLabel ??
              (widget.label.isEmpty ? null : widget.label),
          onTap: widget.onPressed,
          onTapDown: (_) => _startRepeating(),
          onTapUp: (_) => _stopRepeating(),
          onTapCancel: _stopRepeating,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.emphasized
                  ? theme.colorScheme.primary
                  : theme.cardTheme.color,
              shape: BoxShape.circle,
              border: _held
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      width: 2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              color: widget.emphasized
                  ? theme.colorScheme.onPrimary
                  : theme.iconTheme.color,
            ),
          ),
        ),
        if (widget.label.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.label, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
