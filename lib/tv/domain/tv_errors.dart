/// Base type for all TV-domain failures, so callers can catch one type at
/// the UI boundary instead of guessing at provider-specific exceptions.
sealed class TvException implements Exception {
  const TvException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown by [TvProvider.sendCommand] when the connected device does not
/// support the requested command. Callers should prevent this by checking
/// [TvCapabilities] before showing/enabling a control.
class UnsupportedTvCommandException extends TvException {
  const UnsupportedTvCommandException(super.message);
}

/// Thrown when an operation is attempted while not connected.
class TvNotConnectedException extends TvException {
  const TvNotConnectedException([
    super.message = 'No active connection to a TV device.',
  ]);
}

/// Thrown when discovery, connection, or pairing fails at the transport
/// level (network error, timeout, rejected pairing, etc).
class TvConnectionException extends TvException {
  const TvConnectionException(super.message);
}
