import '../../../domain/tv_domain.dart';

/// A raw Android TV Remote service answer, before being turned into a
/// [TvDevice].
class AndroidTvDiscoveryResult {
  const AndroidTvDiscoveryResult({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });

  final String id;
  final String name;
  final String host;
  final int port;
}

/// Finds Android TV / Google TV devices advertising `_androidtvremote2._tcp`
/// on the local network.
///
/// Contract every implementation must honor: `discover()` never throws,
/// never hangs past its timeout, releases every socket/browser it opened,
/// and always logs `[TV][DISCOVERY][ANDROID_TV] started` followed by
/// `[TV][DISCOVERY][ANDROID_TV] completed count=N durationMs=...` - a scan
/// that fails must say why (`resolve_failed stage=... reason=...`) rather
/// than silently returning nothing.
///
/// Two implementations exist because one raw-socket approach does not work
/// everywhere: `MdnsAndroidTvDiscovery` (Android and other non-iOS
/// platforms) speaks mDNS over its own UDP 5353 socket, while
/// `NativeBonjourAndroidTvDiscovery` (iOS) asks the system Bonjour stack,
/// because iOS restricts raw multicast sockets in third-party apps.
abstract interface class AndroidTvDiscovery {
  Future<List<AndroidTvDiscoveryResult>> discover({Duration timeout});
}

TvDevice discoveryResultToDevice(AndroidTvDiscoveryResult result) {
  return TvDevice(
    id: 'android_tv:${result.id}',
    name: result.name,
    platform: TvPlatform.androidTv,
    host: result.host,
  );
}

String stripTrailingDot(String value) =>
    value.endsWith('.') ? value.substring(0, value.length - 1) : value;
