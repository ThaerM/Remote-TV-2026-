import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';

/// A single labelled circular remote button, used for volume, power, home,
/// back, menu, etc. Long-press repeats [onCommand] while held, for
/// volume/channel-style controls - see docs/design/design-system.md.
class RemoteActionButton extends StatefulWidget {
  const RemoteActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = AppControlSize.secondaryButton,
    this.repeatWhileHeld = false,
    this.emphasized = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final bool repeatWhileHeld;
  final bool emphasized;

  @override
  State<RemoteActionButton> createState() => _RemoteActionButtonState();
}

class _RemoteActionButtonState extends State<RemoteActionButton> {
  bool _pressed = false;

  void _startRepeating() async {
    if (!widget.repeatWhileHeld) return;
    _pressed = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    while (_pressed && mounted) {
      widget.onPressed();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  void _stopRepeating() {
    _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: widget.emphasized
              ? theme.colorScheme.primary
              : theme.cardTheme.color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onTapDown: (_) => _startRepeating(),
            onTapUp: (_) => _stopRepeating(),
            onTapCancel: _stopRepeating,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(
                widget.icon,
                color: widget.emphasized
                    ? theme.colorScheme.onPrimary
                    : theme.iconTheme.color,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
