import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../tv/domain/tv_domain.dart';

/// Segmented pairing-code entry: one box per character, matching the code
/// the TV displays (`TvPinPairingRequest` length and alphabet - Android TV
/// uses 6 hex characters like `A4F29C`). Wraps a single hidden [TextField]
/// so the platform keyboard works normally - each box just renders one
/// character of its value. [onSubmitted] only ever receives a complete,
/// valid, normalized code.
///
/// Call [shake] to play a brief horizontal-shake error animation (wrong
/// code); this widget never vibrates on its own - haptics are triggered
/// by the caller so they stay gated on the Remote Behavior setting.
class PairingCodeInput extends StatefulWidget {
  const PairingCodeInput({
    required this.length,
    required this.controller,
    required this.onSubmitted,
    this.alphabet = TvPinAlphabet.digits,
    super.key,
  });

  final int length;
  final TvPinAlphabet alphabet;
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

  late TvPinPairingRequest _request = _requestFor(widget);
  String? _pasteError;

  static TvPinPairingRequest _requestFor(PairingCodeInput widget) =>
      TvPinPairingRequest(
        expectedLength: widget.length,
        alphabet: widget.alphabet,
      );

  @override
  void didUpdateWidget(covariant PairingCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _request = _requestFor(widget);
  }

  void _submitIfComplete(String value) {
    final code = _request.validate(value);
    if (code != null) widget.onSubmitted(code);
  }

  /// The field itself is hidden (the boxes are the visuals), so paste gets
  /// an explicit button. Only a complete, valid code is accepted.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final code = _request.validate(data?.text ?? '');
    setState(() {
      _pasteError = code == null
          ? "The copied text isn't a ${widget.length}-character pairing code."
          : null;
    });
    if (code == null) return;
    widget.controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    widget.onSubmitted(code);
  }

  String get _hint => widget.alphabet == TvPinAlphabet.hex
      ? '${widget.length} characters: numbers 0 to 9 and letters A to F'
      : '${widget.length} digits';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hidden field drives real text input; the boxes below are
              // purely visual, so it keeps its semantics for screen readers.
              Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Pairing code',
                      hintText: _hint,
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    // Letters + digits for hex codes; a number pad would make
                    // A-F impossible to type.
                    keyboardType: widget.alphabet == TvPinAlphabet.hex
                        ? TextInputType.visiblePassword
                        : TextInputType.number,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [_PairingCodeFormatter(_request)],
                    onChanged: (value) {
                      setState(() => _pasteError = null);
                      _submitIfComplete(value);
                    },
                  ),
                ),
              ),
              ExcludeSemantics(
                child: AnimatedBuilder(
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
                            _CharacterBox(
                              character: i < value.text.length
                                  ? value.text[i]
                                  : null,
                              isActive: i == value.text.length,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _paste,
          icon: const Icon(Icons.content_paste_rounded),
          label: const Text('Paste code'),
        ),
        if (_pasteError != null)
          Text(
            _pasteError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

/// Keeps the field a valid prefix of a code: whitespace is dropped and hex
/// letters upper-cased; an edit that would add any other character, or
/// make the code longer than expected (e.g. pasting 7 characters), is
/// rejected as a whole rather than silently trimmed into a wrong code.
class _PairingCodeFormatter extends TextInputFormatter {
  const _PairingCodeFormatter(this.request);

  final TvPinPairingRequest request;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = request.normalize(newValue.text);
    if (text.length > request.expectedLength ||
        (text.isNotEmpty && !request.alphabet.allows(text))) {
      return oldValue;
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CharacterBox extends StatelessWidget {
  const _CharacterBox({required this.character, required this.isActive});

  final String? character;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = character != null;

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
        child: Text(character ?? '', style: theme.textTheme.headlineMedium),
      ),
    );
  }
}
