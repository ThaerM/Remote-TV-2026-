import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/pressable_scale.dart';
import '../../../../tv/domain/tv_domain.dart';

/// "More Controls" - the bottom sheet holding controls that don't need
/// to be on-screen at all times: the numeric keypad, color keys, and
/// keyboard/voice/guide input. Media transport lives on the main Remote
/// screen - see docs/product/screen-inventory.md - this sheet is
/// strictly for genuinely secondary controls.
class SecondaryControlsSheet extends StatelessWidget {
  const SecondaryControlsSheet({
    required this.capabilities,
    required this.onCommand,
    this.onOpenKeyboard,
    super.key,
  });

  final TvCapabilities capabilities;
  final void Function(TvCommand command) onCommand;

  /// Opens the free-text keyboard input - kept as a caller-provided
  /// callback since it needs its own sheet stacked above this one.
  final VoidCallback? onOpenKeyboard;

  static Future<void> show(
    BuildContext context, {
    required TvCapabilities capabilities,
    required void Function(TvCommand command) onCommand,
    VoidCallback? onOpenKeyboard,
  }) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SecondaryControlsSheet(
        capabilities: capabilities,
        onCommand: onCommand,
        onOpenKeyboard: onOpenKeyboard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGuide =
        capabilities.dpad && capabilities.allows(TvCommandKey.guide);
    final hasBottomActions =
        capabilities.keyboard || capabilities.voice || hasGuide;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('More Controls', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (capabilities.numericKeypad) ...[
              _NumericKeypad(onCommand: onCommand),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (capabilities.colorKeys) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorKey(
                    color: Colors.red,
                    onTap: () =>
                        onCommand(const TvCommand.key(TvCommandKey.colorRed)),
                  ),
                  _ColorKey(
                    color: Colors.green,
                    onTap: () =>
                        onCommand(const TvCommand.key(TvCommandKey.colorGreen)),
                  ),
                  _ColorKey(
                    color: Colors.yellow,
                    onTap: () => onCommand(
                      const TvCommand.key(TvCommandKey.colorYellow),
                    ),
                  ),
                  _ColorKey(
                    color: Colors.blue,
                    onTap: () =>
                        onCommand(const TvCommand.key(TvCommandKey.colorBlue)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (hasBottomActions)
              Row(
                children: [
                  if (capabilities.keyboard)
                    Expanded(
                      child: _BottomActionCard(
                        icon: Icons.keyboard_alt_outlined,
                        label: 'Keyboard',
                        onPressed: onOpenKeyboard ?? () {},
                      ),
                    ),
                  if (capabilities.voice) ...[
                    if (capabilities.keyboard)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _BottomActionCard(
                        icon: Icons.mic_rounded,
                        label: 'Voice',
                        onPressed: () => onCommand(
                          const TvCommand.key(TvCommandKey.voiceStart),
                        ),
                      ),
                    ),
                  ],
                  if (hasGuide) ...[
                    if (capabilities.keyboard || capabilities.voice)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _BottomActionCard(
                        icon: Icons.grid_view_rounded,
                        label: 'Guide',
                        onPressed: () =>
                            onCommand(const TvCommand.key(TvCommandKey.guide)),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onCommand});

  final void Function(TvCommand command) onCommand;

  // The bottom row mirrors a physical remote's keypad shape (*, 0, #) -
  // "*"/"#" render as dim, non-interactive placeholders since no
  // TvCommandKey exists for them; only 0 actually sends a command.
  static const _keys = [
    TvCommandKey.digit1,
    TvCommandKey.digit2,
    TvCommandKey.digit3,
    TvCommandKey.digit4,
    TvCommandKey.digit5,
    TvCommandKey.digit6,
    TvCommandKey.digit7,
    TvCommandKey.digit8,
    TvCommandKey.digit9,
    null,
    TvCommandKey.digit0,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        for (var i = 0; i < _keys.length; i++)
          if (_keys[i] == null)
            _KeypadPlaceholder(symbol: i == 9 ? '*' : '#')
          else
            _KeypadKey(
              label: _keys[i]!.name.replaceFirst('digit', ''),
              onPressed: () => onCommand(TvCommand.key(_keys[i]!)),
            ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: theme.cardTheme.color,
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(label),
    );
  }
}

/// A decorative, non-interactive keypad cell - shows the physical-remote
/// shape ("*"/"#") without wiring a command that doesn't exist.
class _KeypadPlaceholder extends StatelessWidget {
  const _KeypadPlaceholder({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _ColorKey extends StatelessWidget {
  const _ColorKey({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A rounded-rectangle card for the sheet's bottom actions (Keyboard/
/// Voice/Guide) - matching Home/Back/Menu's hardware-button language
/// instead of a circular icon button.
class _BottomActionCard extends StatelessWidget {
  const _BottomActionCard({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      hapticsEnabled: false,
      semanticLabel: label,
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.iconTheme.color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
