/// A remote-control command sent to a connected [TvDevice].
///
/// Commands are intentionally generic (`TvCommand.key(...)`) rather than one
/// class per button, so new buttons don't require touching every provider.
/// A provider that cannot fulfil a command must throw
/// [UnsupportedTvCommandException] - callers should check [TvCapabilities]
/// before sending, not rely on catching that exception for control flow.
class TvCommand {
  const TvCommand.key(this.key, {this.payload}) : type = TvCommandType.key;

  const TvCommand.text(String text)
    : key = TvCommandKey.textInput,
      type = TvCommandType.text,
      payload = text;

  const TvCommand.launchApp(String appId)
    : key = TvCommandKey.launchApp,
      type = TvCommandType.launchApp,
      payload = appId;

  final TvCommandType type;
  final TvCommandKey key;

  /// Free-form payload: raw text for [TvCommandType.text], an app id for
  /// [TvCommandType.launchApp], null otherwise.
  final Object? payload;

  @override
  String toString() => 'TvCommand($key${payload != null ? ', $payload' : ''})';
}

enum TvCommandType { key, text, launchApp }

/// The catalog of discrete remote buttons. Not every device supports every
/// key - see [TvCapabilities].
enum TvCommandKey {
  power,
  volumeUp,
  volumeDown,
  mute,
  channelUp,
  channelDown,
  previousChannel,
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  select,
  home,
  back,
  menu,
  guide,
  info,
  inputSource,
  colorRed,
  colorGreen,
  colorYellow,
  colorBlue,
  mediaPlay,
  mediaPause,
  mediaStop,
  mediaRewind,
  mediaForward,
  mediaPrevious,
  mediaNext,
  voiceStart,
  textInput,
  launchApp,
}
