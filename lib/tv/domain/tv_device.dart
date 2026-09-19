import 'tv_platform.dart';

/// A TV or TV-like device discovered or saved by the app.
///
/// [id] must be stable across rediscovery (e.g. derived from MAC address or
/// a platform-issued device id) so that "recently used" and "saved TVs" can
/// match a rediscovered device back to its stored pairing.
class TvDevice {
  const TvDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.host,
    this.iconKey,
    this.isDevelopmentFake = false,
  });

  final String id;
  final String name;
  final TvPlatform platform;

  /// IP address or hostname on the local network, when known.
  final String? host;

  /// A hint for which icon/model illustration to show for this device.
  final String? iconKey;

  /// True for devices produced by [TvPlatform.fake]. The UI must clearly
  /// label these as development-only, never presenting them as real TVs.
  final bool isDevelopmentFake;

  TvDevice copyWith({
    String? id,
    String? name,
    TvPlatform? platform,
    String? host,
    String? iconKey,
    bool? isDevelopmentFake,
  }) {
    return TvDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      host: host ?? this.host,
      iconKey: iconKey ?? this.iconKey,
      isDevelopmentFake: isDevelopmentFake ?? this.isDevelopmentFake,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          platform == other.platform &&
          host == other.host &&
          iconKey == other.iconKey &&
          isDevelopmentFake == other.isDevelopmentFake;

  @override
  int get hashCode =>
      Object.hash(id, name, platform, host, iconKey, isDevelopmentFake);

  @override
  String toString() => 'TvDevice($name, platform: $platform, id: $id)';
}
