import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../../tv/domain/tv_domain.dart';
import '../../../settings/application/settings_controller.dart';

/// Directional pad used when [TvCapabilities.dpad] is true and the user's
/// Remote Layout preference is D-pad (vs. touchpad - see
/// `TouchpadSurface`).
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
              semanticLabel: 'Navigate Up',
              onTap: () => onCommand(TvCommandKey.dpadUp),
            ),
          ),
          Positioned(
            bottom: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticLabel: 'Navigate Down',
              onTap: () => onCommand(TvCommandKey.dpadDown),
            ),
          ),
          Positioned(
            left: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_left_rounded,
              semanticLabel: 'Navigate Left',
              onTap: () => onCommand(TvCommandKey.dpadLeft),
            ),
          ),
          Positioned(
            right: 0,
            child: _DpadButton(
              icon: Icons.keyboard_arrow_right_rounded,
              semanticLabel: 'Navigate Right',
              onTap: () => onCommand(TvCommandKey.dpadRight),
            ),
          ),
          _DpadButton(
            icon: Icons.circle,
            iconSize: 14,
            isPrimary: true,
            semanticLabel: 'Select',
            onTap: () => onCommand(TvCommandKey.select),
          ),
        ],
      ),
    );
  }
}

class _DpadButton extends ConsumerWidget {
  const _DpadButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 28,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double iconSize;
  final bool isPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = isPrimary ? 72.0 : AppControlSize.secondaryButton;
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );

    return PressableScale(
      hapticsEnabled: hapticsEnabled,
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary ? theme.colorScheme.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: isPrimary
              ? theme.colorScheme.onPrimary
              : theme.iconTheme.color,
        ),
      ),
    );
  }
}
