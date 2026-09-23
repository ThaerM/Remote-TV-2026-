import '../../../domain/tv_domain.dart';
import 'generated/remotemessage.pbenum.dart';

/// Maps our shared [TvCommandKey] vocabulary onto the Android TV
/// Remote protocol's [RemoteKeyCode] enum, and reports which of our
/// commands the protocol has no equivalent for at all (as opposed to
/// "not currently supported by this device").
///
/// A command absent from [supportedKeys] is not sent - the protocol has
/// no such button (e.g. there are no color keys or a "guide" key in the
/// Android TV Remote v2 keycode set), so [AndroidTvProvider] never
/// offers it via [TvCapabilities] rather than faking a response.
abstract final class AndroidTvCommandMapper {
  static const Map<TvCommandKey, RemoteKeyCode> supportedKeys = {
    TvCommandKey.power: RemoteKeyCode.KEYCODE_POWER,
    TvCommandKey.volumeUp: RemoteKeyCode.KEYCODE_VOLUME_UP,
    TvCommandKey.volumeDown: RemoteKeyCode.KEYCODE_VOLUME_DOWN,
    TvCommandKey.mute: RemoteKeyCode.KEYCODE_VOLUME_MUTE,
    TvCommandKey.channelUp: RemoteKeyCode.KEYCODE_CHANNEL_UP,
    TvCommandKey.channelDown: RemoteKeyCode.KEYCODE_CHANNEL_DOWN,
    TvCommandKey.digit0: RemoteKeyCode.KEYCODE_0,
    TvCommandKey.digit1: RemoteKeyCode.KEYCODE_1,
    TvCommandKey.digit2: RemoteKeyCode.KEYCODE_2,
    TvCommandKey.digit3: RemoteKeyCode.KEYCODE_3,
    TvCommandKey.digit4: RemoteKeyCode.KEYCODE_4,
    TvCommandKey.digit5: RemoteKeyCode.KEYCODE_5,
    TvCommandKey.digit6: RemoteKeyCode.KEYCODE_6,
    TvCommandKey.digit7: RemoteKeyCode.KEYCODE_7,
    TvCommandKey.digit8: RemoteKeyCode.KEYCODE_8,
    TvCommandKey.digit9: RemoteKeyCode.KEYCODE_9,
    TvCommandKey.dpadUp: RemoteKeyCode.KEYCODE_DPAD_UP,
    TvCommandKey.dpadDown: RemoteKeyCode.KEYCODE_DPAD_DOWN,
    TvCommandKey.dpadLeft: RemoteKeyCode.KEYCODE_DPAD_LEFT,
    TvCommandKey.dpadRight: RemoteKeyCode.KEYCODE_DPAD_RIGHT,
    TvCommandKey.select: RemoteKeyCode.KEYCODE_DPAD_CENTER,
    TvCommandKey.home: RemoteKeyCode.KEYCODE_HOME,
    TvCommandKey.back: RemoteKeyCode.KEYCODE_BACK,
    TvCommandKey.menu: RemoteKeyCode.KEYCODE_MENU,
    TvCommandKey.guide: RemoteKeyCode.KEYCODE_GUIDE,
    TvCommandKey.info: RemoteKeyCode.KEYCODE_INFO,
    TvCommandKey.inputSource: RemoteKeyCode.KEYCODE_TV_INPUT,
    TvCommandKey.mediaPlay: RemoteKeyCode.KEYCODE_MEDIA_PLAY,
    TvCommandKey.mediaPause: RemoteKeyCode.KEYCODE_MEDIA_PAUSE,
    TvCommandKey.mediaStop: RemoteKeyCode.KEYCODE_MEDIA_STOP,
    TvCommandKey.mediaRewind: RemoteKeyCode.KEYCODE_MEDIA_REWIND,
    TvCommandKey.mediaForward: RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD,
    TvCommandKey.mediaPrevious: RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS,
    TvCommandKey.mediaNext: RemoteKeyCode.KEYCODE_MEDIA_NEXT,
  };

  /// Commands the protocol has no key code for at all: color keys
  /// (cable-box concept, not part of this keycode set) and voice
  /// (explicitly out of scope - see docs/research/android-google-tv.md).
  static const Set<TvCommandKey> unsupportedByProtocol = {
    TvCommandKey.colorRed,
    TvCommandKey.colorGreen,
    TvCommandKey.colorYellow,
    TvCommandKey.colorBlue,
    TvCommandKey.voiceStart,
    TvCommandKey.previousChannel,
  };
}

/// A small, known-accurate set of app links for the quick-apps row.
///
/// The protocol launches apps via an Android intent-style URI
/// (`remote_app_link_launch_request`), not a package name - see
/// `docs/research/android-google-tv.md`. Only entries verified to be the
/// app's actual public deep-link scheme are listed; an app missing here
/// simply won't appear in the quick-apps row for this provider.
abstract final class AndroidTvAppLinks {
  static const Map<String, String> byAppId = {
    'netflix': 'https://www.netflix.com/',
    'youtube': 'https://www.youtube.com/',
  };
}
