/// Lifecycle of a [TvProvider]'s connection to a single [TvDevice].
enum TvConnectionState {
  disconnected,
  connecting,
  pairingRequired,
  connected,
  reconnecting,
  error;

  bool get isActive =>
      this == TvConnectionState.connecting ||
      this == TvConnectionState.pairingRequired ||
      this == TvConnectionState.connected ||
      this == TvConnectionState.reconnecting;
}
