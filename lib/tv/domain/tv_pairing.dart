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

/// The TV is displaying a short code; the user must enter it in-app via
/// [TvProvider.submitPairingCode].
class TvPinPairingRequest extends TvPairingRequest {
  const TvPinPairingRequest({this.expectedLength = 4});

  final int expectedLength;
}

/// The user must confirm the pairing prompt shown on the TV itself; the app
/// just waits on [TvProvider.connectionState] to move to `connected`.
class TvConfirmOnDevicePairingRequest extends TvPairingRequest {
  const TvConfirmOnDevicePairingRequest();
}
