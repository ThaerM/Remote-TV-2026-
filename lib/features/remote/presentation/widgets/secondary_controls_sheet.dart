import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';
import 'remote_action_button.dart';

/// Bottom sheet holding controls that don't need to be on-screen at all
/// times: keyboard/voice input, the numeric keypad, and color keys. Media
/// transport lives on the main Remote screen now - see
/// docs/product/screen-inventory.md - this sheet is strictly for genuinely
/// secondary controls.
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
          children: [
            if (capabilities.keyboard || capabilities.voice) ...[
              Text(
                'Advanced controls',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (capabilities.keyboard)
                    RemoteActionButton(
                      icon: Icons.keyboard_alt_outlined,
                      label: 'Keyboard',
                      onPressed: onOpenKeyboard ?? () {},
                    ),
                  if (capabilities.voice)
                    RemoteActionButton(
                      icon: Icons.mic_rounded,
                      label: 'Voice',
                      onPressed: () => onCommand(
                        const TvCommand.key(TvCommandKey.voiceStart),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (capabilities.numericKeypad) ...[
              Text(
                'Number pad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _NumericKeypad(onCommand: onCommand),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (capabilities.colorKeys) ...[
              Text(
                'Color keys',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onCommand});

  final void Function(TvCommand command) onCommand;

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
        for (final key in _keys)
          if (key == null)
            const SizedBox.shrink()
          else
            OutlinedButton(
              onPressed: () => onCommand(TvCommand.key(key)),
              child: Text(key.name.replaceFirst('digit', '')),
            ),
      ],
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
