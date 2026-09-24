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

/// The local network is unavailable (no Wi-Fi/no route), so discovery or
/// connection could not even attempt a socket.
class NetworkUnavailableException extends TvException {
  const NetworkUnavailableException([
    super.message = 'No network connection is available.',
  ]);
}

/// The device was found (or previously paired) but did not respond on
/// its expected host/port - distinct from a network-wide outage.
class DeviceNotReachableException extends TvException {
  const DeviceNotReachableException(super.message);
}

/// A command or connection attempt was made before pairing completed.
class PairingRequiredException extends TvException {
  const PairingRequiredException([
    super.message = 'This device has not been paired yet.',
  ]);
}

/// The TV rejected the pairing attempt (wrong code, or the user declined
/// the prompt on the TV itself).
class PairingRejectedException extends TvException {
  const PairingRejectedException(super.message);
}

/// The TV did not respond to a pairing step within the expected time.
class PairingTimeoutException extends TvException {
  const PairingTimeoutException(super.message);
}

/// The connection's cryptographic handshake failed (certificate/key
/// mismatch, TLS failure) after pairing was believed to be complete -
/// typically means stored credentials are stale and the device must be
/// re-paired.
class AuthenticationFailedException extends TvException {
  const AuthenticationFailedException(super.message);
}

/// An established connection was lost unexpectedly (network drop, TV
/// went to sleep, TV closed the socket).
class ConnectionLostException extends TvException {
  const ConnectionLostException(super.message);
}

/// A playback command (play/pause/seek/stop) was sent to a casting device
/// that has nothing loaded, or the device rejected the media.
class TvMediaSessionException extends TvException {
  const TvMediaSessionException(super.message);
}

/// A message could not be parsed/encoded, or the device responded with a
/// protocol-level error - distinct from a transport-level failure.
class ProtocolErrorException extends TvException {
  const ProtocolErrorException(super.message);
}
