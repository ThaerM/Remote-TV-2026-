import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_domain.dart';
import '../android_tv_constants.dart';
import 'android_tv_discovery.dart';

/// [AndroidTvDiscovery] via the iOS system Bonjour stack
/// (`ios/Runner/AndroidTvBonjourDiscovery.swift`: `NWBrowser` to browse,
/// `NetService` to resolve host/port/IPv4).
///
/// iOS doesn't let third-party apps use raw multicast sockets on UDP 5353
/// without Apple's restricted `com.apple.developer.networking.multicast`
/// entitlement, and on a real iPhone `MDnsClient.start()` fails in
/// `joinMulticast` with an `OSError`. Bonjour through the system APIs needs
/// only `NSLocalNetworkUsageDescription` + `NSBonjourServices`
/// (`_androidtvremote2._tcp`), both already in `Info.plist`.
///
/// The native side bounds its own browse window to `timeoutMs`; this side
/// adds [_channelGrace] on top as a safety net, so even a native side that
/// never replies can't hang `discover()`.
class NativeBonjourAndroidTvDiscovery implements AndroidTvDiscovery {
  NativeBonjourAndroidTvDiscovery({
    this._channel = const MethodChannel(channelName),
    this._channelGrace = const Duration(seconds: 2),
  }) : _logger = AppLogger('TV.Discovery.Bonjour.AndroidTV');

  static const channelName = 'remote_tv_2026/android_tv_bonjour';

  final MethodChannel _channel;
  final Duration _channelGrace;
  final AppLogger _logger;

  @override
  Future<AndroidTvDiscoveryScan> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][ANDROID_TV] started backend=native_bonjour');
    final results = <String, AndroidTvDiscoveryResult>{};
    TvDiscoveryIssue? issue;

    try {
      final reply = await _channel
          .invokeMapMethod<String, Object?>('browse', {
            'serviceType': AndroidTvConstants.mdnsServiceType,
            'timeoutMs': timeout.inMilliseconds,
          })
          .timeout(timeout + _channelGrace);
      issue = _consume(reply ?? const {}, results);
    } on TimeoutException {
      issue = TvDiscoveryIssue.timedOut;
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=BROWSE reason=scan_timeout',
      );
    } on PlatformException catch (error) {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] start_failed type=PlatformException '
        'code=${error.code} error=${error.message}',
      );
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=START reason=start_failed',
      );
    } on MissingPluginException {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] start_failed type=MissingPluginException '
        'error=native_bonjour_bridge_not_registered',
      );
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=START reason=start_failed',
      );
    } catch (error) {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] scan_failed type=${error.runtimeType} error=$error',
      );
    }

    final devices = results.values.toList(growable: false);
    _logger.info(
      '[TV][DISCOVERY][ANDROID_TV] completed count=${devices.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return AndroidTvDiscoveryScan(devices, issue: issue);
  }

  TvDiscoveryIssue? _consume(
    Map<String, Object?> reply,
    Map<String, AndroidTvDiscoveryResult> results,
  ) {
    final failure = reply['failure'] as String?;
    if (failure != null) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=BROWSE reason=$failure '
        'detail=${reply['detail'] ?? 'none'}',
      );
    }
    final issue = switch (failure) {
      null => null,
      'permission_denied_or_restricted' => TvDiscoveryIssue.localNetworkDenied,
      _ => TvDiscoveryIssue.failed,
    };

    final browsed = (reply['browsed'] as num?)?.toInt() ?? 0;
    if (browsed == 0 && failure == null) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=PTR reason=ptr_empty',
      );
    }

    for (final name in (reply['unresolved'] as List?) ?? const []) {
      _logger.info('[TV][DISCOVERY][ANDROID_TV] ptr instance=$name');
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=SRV reason=srv_failed instance=$name',
      );
    }

    for (final entry in (reply['services'] as List?) ?? const []) {
      final service = (entry as Map).cast<String, Object?>();
      final name = service['name'] as String? ?? 'Android TV';
      _logger.info('[TV][DISCOVERY][ANDROID_TV] ptr instance=$name');

      final rawHost = service['host'] as String?;
      final port = (service['port'] as num?)?.toInt() ?? -1;
      if (rawHost == null || rawHost.isEmpty || port <= 0) {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=SRV reason=srv_failed instance=$name',
        );
        continue;
      }
      final targetHost = stripTrailingDot(rawHost);
      _logger.info(
        '[TV][DISCOVERY][ANDROID_TV] srv host=$targetHost port=$port',
      );

      final ipv4 = service['ipv4'] as String?;
      if (ipv4 != null) {
        _logger.info(
          '[TV][DISCOVERY][ANDROID_TV] resolved host=$targetHost ip=$ipv4',
        );
      } else {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=IP reason=ip_failed host=$targetHost',
        );
      }

      if (results.containsKey(targetHost)) continue;
      // Same identity/fallback rules as MdnsAndroidTvDiscovery: keyed by the
      // stable advertised hostname; connect via IPv4 when known, otherwise
      // via the `.local` hostname (resolved by the system resolver).
      results[targetHost] = AndroidTvDiscoveryResult(
        id: targetHost,
        name: name,
        host: ipv4 ?? targetHost,
        port: port,
      );
      _logger.info('[TV][DISCOVERY][ANDROID_TV] found device=$name');
    }
    return issue;
  }
}
