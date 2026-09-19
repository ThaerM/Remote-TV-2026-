import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_domain.dart';
import '../android_tv_constants.dart';

/// A raw mDNS answer for one Android TV Remote-capable device, before
/// being turned into a [TvDevice].
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

/// Discovers Android TV / Google TV devices on the local network via
/// mDNS/Bonjour (`_androidtvremote2._tcp`).
///
/// Runs entirely off the UI thread (Dart's `dart:io` mDNS client is
/// async I/O, not a blocking call) and has an explicit start/stop
/// lifecycle so a scan never outlives its caller. Malformed or
/// incomplete service records (missing SRV/A data) are skipped rather
/// than surfaced as devices with null fields - see
/// `docs/research/android-google-tv.md`.
class AndroidTvDiscovery {
  AndroidTvDiscovery({MDnsClient? client})
    : _client = client ?? MDnsClient(),
      _logger = AppLogger('TV.Discovery.mDNS.AndroidTV');

  final MDnsClient _client;
  final AppLogger _logger;

  /// Scans for up to [timeout], de-duplicating by resolved host so a
  /// device advertised on multiple interfaces is only reported once.
  Future<List<AndroidTvDiscoveryResult>> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _logger.info('[TV][DISCOVERY][ANDROID_TV] started');
    final results = <String, AndroidTvDiscoveryResult>{};

    try {
      await _client.start();
    } on SocketException catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] network unavailable: ${error.message}',
      );
      return const [];
    }

    try {
      await for (final ptr
          in _client
              .lookup<PtrResourceRecord>(
                ResourceRecordQuery.serverPointer(
                  '${AndroidTvConstants.mdnsServiceType}.local',
                ),
              )
              .timeout(timeout, onTimeout: (sink) => sink.close())) {
        await for (final srv
            in _client
                .lookup<SrvResourceRecord>(
                  ResourceRecordQuery.service(ptr.domainName),
                )
                .timeout(
                  const Duration(seconds: 2),
                  onTimeout: (sink) => sink.close(),
                )) {
          final host = await _resolveHost(srv.target);
          if (host == null) continue;

          final friendlyName = _friendlyNameFrom(ptr.domainName);
          final id = '$host:${srv.port}';
          results[id] = AndroidTvDiscoveryResult(
            id: id,
            name: friendlyName,
            host: host,
            port: srv.port,
          );
          _logger.info(
            '[TV][DISCOVERY][ANDROID_TV] found device=$friendlyName',
          );
        }
      }
    } finally {
      _client.stop();
    }

    return results.values.toList(growable: false);
  }

  Future<String?> _resolveHost(String target) async {
    try {
      await for (final ip
          in _client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(target),
              )
              .timeout(
                const Duration(seconds: 2),
                onTimeout: (sink) => sink.close(),
              )) {
        return ip.address.address;
      }
    } catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] could not resolve $target: $error',
      );
    }
    return null;
  }

  String _friendlyNameFrom(String domainName) {
    final serviceSuffix = '.${AndroidTvConstants.mdnsServiceType}.local';
    final instance = domainName.endsWith(serviceSuffix)
        ? domainName.substring(0, domainName.length - serviceSuffix.length)
        : domainName;
    return instance.isEmpty ? 'Android TV' : instance;
  }
}

TvDevice discoveryResultToDevice(AndroidTvDiscoveryResult result) {
  return TvDevice(
    id: 'android_tv:${result.id}',
    name: result.name,
    platform: TvPlatform.androidTv,
    host: result.host,
  );
}
