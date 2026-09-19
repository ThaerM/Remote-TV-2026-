import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';

/// Directional pad used when [TvCapabilities.dpad] is true. A future
/// touchpad alternative is chosen via Settings > Remote Behavior.
class DpadControl extends StatelessWidget {
  const DpadControl({required this.onCommand, super.key});

  final void Function(TvCommandKey key) onCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: AppControlSize.dpadDiameter,
      height: AppControlSize.dpadDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerColor),
            ),
          ),
          Positioned(
            top: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_up_rounded,
              onTap: () => onCommand(TvCommandKey.dpadUp),
            ),
          ),
          Positioned(
            bottom: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => onCommand(TvCommandKey.dpadDown),
            ),
          ),
          Positioned(
            left: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              onTap: () => onCommand(TvCommandKey.dpadLeft),
            ),
          ),
          Positioned(
            right: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              onTap: () => onCommand(TvCommandKey.dpadRight),
            ),
          ),
          _DpadButton(
            icon: Icons.circle,
            iconSize: 14,
            isPrimary: true,
            onTap: () => onCommand(TvCommandKey.select),
          ),
        ],
      ),
    );
  }
}

class _DpadButton extends StatelessWidget {
  const _DpadButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 28,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = isPrimary ? 72.0 : AppControlSize.secondaryButton;
    return Material(
      color: isPrimary ? theme.colorScheme.primary : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: isPrimary
                ? theme.colorScheme.onPrimary
                : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}
