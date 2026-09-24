/// A pairing challenge issued by a [TvProvider] during `connect`.
///
/// `TvPairingRequest.none` means the device connected without any user
/// interaction. `pin` means the TV is displaying a code the user must type
/// into the app; `confirm` means the TV is showing a prompt the user must
/// accept on the TV itself.
sealed class TvPairingRequest {
  const TvPairingRequest();

  static const TvPairingRequest none = _NoPairingRequired();
}

class _NoPairingRequired extends TvPairingRequest {
  const _NoPairingRequired();
}

/// Which characters a pairing code shown on the TV can contain.
enum TvPinAlphabet {
  digits,

  /// 0-9 and A-F, e.g. Android TV's 6-character codes like `A4F29C`.
  hex;

  bool allows(String character) => switch (this) {
    TvPinAlphabet.digits => _digits.hasMatch(character),
    TvPinAlphabet.hex => _hex.hasMatch(character),
  };

  static final _digits = RegExp(r'^[0-9]+$');
  static final _hex = RegExp(r'^[0-9A-F]+$');
}

/// The TV is displaying a short code; the user must enter it in-app via
/// [TvProvider.submitPairingCode].
class TvPinPairingRequest extends TvPairingRequest {
  const TvPinPairingRequest({
    this.expectedLength = 4,
    this.alphabet = TvPinAlphabet.digits,
  });

  final int expectedLength;
  final TvPinAlphabet alphabet;

  /// Canonical form of what the user typed or pasted: surrounding and
  /// inner whitespace removed and hex letters upper-cased. Doesn't check
  /// length or characters - see [validate].
  String normalize(String input) {
    final compact = input.replaceAll(RegExp(r'\s'), '');
    return alphabet == TvPinAlphabet.hex ? compact.toUpperCase() : compact;
  }

  /// The normalized code if [input] is exactly [expectedLength] characters
  /// from [alphabet] (`a4f29c` -> `A4F29C`), otherwise null. Checked before
  /// anything is sent to the TV.
  String? validate(String input) {
    final code = normalize(input);
    if (code.length != expectedLength || !alphabet.allows(code)) return null;
    return code;
  }
}

/// The user must confirm the pairing prompt shown on the TV itself; the app
/// just waits on [TvProvider.connectionState] to move to `connected`.
class TvConfirmOnDevicePairingRequest extends TvPairingRequest {
  const TvConfirmOnDevicePairingRequest();
}
