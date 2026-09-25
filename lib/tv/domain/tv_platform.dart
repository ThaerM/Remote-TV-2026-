/// The ecosystem a [TvDevice] belongs to.
///
/// Each platform is implemented by a dedicated [TvProvider]. Adding a new
/// platform means adding a new enum value and a new provider - never adding
/// branching logic to shared UI or domain code.
enum TvPlatform {
  /// Development/demo devices with no physical television.
  fake,
  androidTv,
  googleCast,
  samsungTizen,
  lgWebOs,
  roku,
  fireTv,
  dlna;

  String get displayName => switch (this) {
    TvPlatform.fake => 'Demo',
    TvPlatform.androidTv => 'Android TV / Google TV',
    TvPlatform.googleCast => 'Google Cast',
    TvPlatform.samsungTizen => 'Samsung Tizen',
    TvPlatform.lgWebOs => 'LG webOS',
    TvPlatform.roku => 'Roku',
    TvPlatform.fireTv => 'Fire TV',
    TvPlatform.dlna => 'DLNA / UPnP',
  };

  /// True for platforms that are media-cast targets only - no
  /// remote-control key input (see `DlnaProvider`'s and
  /// `GoogleCastProvider`'s own docs). Used to pick which endpoint of a
  /// grouped [PhysicalTvDevice] is the "remote" one - never for branching
  /// on platform in feature UI, which stays capability-driven.
  bool get isCastOnly =>
      this == TvPlatform.googleCast || this == TvPlatform.dlna;
}
