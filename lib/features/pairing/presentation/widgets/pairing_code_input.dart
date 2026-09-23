import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';

/// Segmented PIN entry: one box per digit, matching the code length the
/// TV displays (see `TvPinPairingRequest.expectedLength`). Wraps a
/// single hidden [TextField] so the platform keyboard and autofill still
/// work normally - each box just renders one character of its value.
///
/// Call [shake] to play a brief horizontal-shake error animation (wrong
/// code); this widget never vibrates on its own - haptics are triggered
/// by the caller so they stay gated on the Remote Behavior setting.
class PairingCodeInput extends StatefulWidget {
  const PairingCodeInput({
    required this.length,
    required this.controller,
    required this.onSubmitted,
    super.key,
  });

  final int length;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  State<PairingCodeInput> createState() => PairingCodeInputState();
}

class PairingCodeInputState extends State<PairingCodeInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Plays the error shake. Public so the pairing screen can trigger it
  /// when the TV rejects the code.
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden field drives real text input/autofill; boxes below
          // are purely visual.
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: (value) {
                  setState(() {});
                  if (value.length == widget.length) widget.onSubmitted(value);
                },
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shake.value, 0),
              child: child,
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      _DigitBox(
                        digit: i < value.text.length ? value.text[i] : null,
                        isActive: i == value.text.length,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit, required this.isActive});

  final String? digit;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = digit != null;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isActive
              ? AppColors.glow
              : filled
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.glow.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: filled ? 1.0 : 0.8,
        duration: AppMotion.fast,
        child: Text(digit ?? '', style: theme.textTheme.headlineMedium),
      ),
    );
  }
}
