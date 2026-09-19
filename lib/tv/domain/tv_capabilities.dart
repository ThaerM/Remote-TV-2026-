/// Declares what a specific connected [TvDevice] can actually do.
///
/// The remote UI is built from this, not from `platform`. Two devices on the
/// same [TvPlatform] can expose different capabilities (e.g. an older
/// Samsung model without voice input) - never branch UI on platform when a
/// capability flag can express the same distinction.
class TvCapabilities {
  const TvCapabilities({
    this.power = false,
    this.volume = false,
    this.mute = false,
    this.channel = false,
    this.dpad = false,
    this.touchpad = false,
    this.keyboard = false,
    this.voice = false,
    this.mediaControls = false,
    this.numericKeypad = false,
    this.colorKeys = false,
    this.inputSwitching = false,
    this.launchApps = false,
    this.casting = false,
    this.screenMirroring = false,
    this.wakeOnLan = false,
    this.appInstall = false,
  });

  /// No capabilities enabled. Useful as a safe default while a device is
  /// still connecting and its real capabilities are unknown.
  static const TvCapabilities none = TvCapabilities();

  final bool power;
  final bool volume;
  final bool mute;
  final bool channel;
  final bool dpad;
  final bool touchpad;
  final bool keyboard;
  final bool voice;
  final bool mediaControls;
  final bool numericKeypad;
  final bool colorKeys;
  final bool inputSwitching;
  final bool launchApps;
  final bool casting;
  final bool screenMirroring;
  final bool wakeOnLan;
  final bool appInstall;

  TvCapabilities copyWith({
    bool? power,
    bool? volume,
    bool? mute,
    bool? channel,
    bool? dpad,
    bool? touchpad,
    bool? keyboard,
    bool? voice,
    bool? mediaControls,
    bool? numericKeypad,
    bool? colorKeys,
    bool? inputSwitching,
    bool? launchApps,
    bool? casting,
    bool? screenMirroring,
    bool? wakeOnLan,
    bool? appInstall,
  }) {
    return TvCapabilities(
      power: power ?? this.power,
      volume: volume ?? this.volume,
      mute: mute ?? this.mute,
      channel: channel ?? this.channel,
      dpad: dpad ?? this.dpad,
      touchpad: touchpad ?? this.touchpad,
      keyboard: keyboard ?? this.keyboard,
      voice: voice ?? this.voice,
      mediaControls: mediaControls ?? this.mediaControls,
      numericKeypad: numericKeypad ?? this.numericKeypad,
      colorKeys: colorKeys ?? this.colorKeys,
      inputSwitching: inputSwitching ?? this.inputSwitching,
      launchApps: launchApps ?? this.launchApps,
      casting: casting ?? this.casting,
      screenMirroring: screenMirroring ?? this.screenMirroring,
      wakeOnLan: wakeOnLan ?? this.wakeOnLan,
      appInstall: appInstall ?? this.appInstall,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvCapabilities &&
          runtimeType == other.runtimeType &&
          power == other.power &&
          volume == other.volume &&
          mute == other.mute &&
          channel == other.channel &&
          dpad == other.dpad &&
          touchpad == other.touchpad &&
          keyboard == other.keyboard &&
          voice == other.voice &&
          mediaControls == other.mediaControls &&
          numericKeypad == other.numericKeypad &&
          colorKeys == other.colorKeys &&
          inputSwitching == other.inputSwitching &&
          launchApps == other.launchApps &&
          casting == other.casting &&
          screenMirroring == other.screenMirroring &&
          wakeOnLan == other.wakeOnLan &&
          appInstall == other.appInstall;

  @override
  int get hashCode => Object.hash(
    power,
    volume,
    mute,
    channel,
    dpad,
    touchpad,
    keyboard,
    voice,
    mediaControls,
    numericKeypad,
    colorKeys,
    inputSwitching,
    launchApps,
    casting,
    screenMirroring,
    wakeOnLan,
    appInstall,
  );
}
