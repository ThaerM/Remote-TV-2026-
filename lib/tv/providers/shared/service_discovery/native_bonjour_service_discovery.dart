import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_domain.dart';
import 'service_discovery.dart';

/// [ServiceDiscovery] via the iOS system Bonjour stack
/// (`ios/Runner/BonjourDiscoveryBridge.swift`: `NWBrowser` to browse,
/// `NetService` to resolve host/port/IPv4).
///
/// iOS doesn't let third-party apps use raw multicast sockets on UDP 5353
/// without Apple's restricted `com.apple.developer.networking.multicast`
/// entitlement, and on a real iPhone `MDnsClient.start()` fails in
/// `joinMulticast` with an `OSError`. Bonjour through the system APIs needs
/// only `NSLocalNetworkUsageDescription` + `NSBonjourServices`
/// (one entry per browsed service type) in `Info.plist`.
///
/// The native side bounds its own browse window to `timeoutMs`; this side
/// adds [_channelGrace] on top as a safety net, so even a native side that
/// never replies can't hang `discover()`.
class NativeBonjourServiceDiscovery implements ServiceDiscovery {
  NativeBonjourServiceDiscovery({
    required this._serviceType,
    required this._logTag,
    this._channel = const MethodChannel(channelName),
    this._channelGrace = const Duration(seconds: 2),
  }) : _logger = AppLogger('TV.Discovery.Bonjour.$_logTag');

  /// e.g. `_androidtvremote2._tcp`. Must also be listed under
  /// `NSBonjourServices` in `ios/Runner/Info.plist`, or iOS refuses the
  /// browse (reported as `bonjour_service_missing`).
  final String _serviceType;
  final String _logTag;

  static const channelName = 'remote_tv_2026/bonjour';

  final MethodChannel _channel;
  final Duration _channelGrace;
  final AppLogger _logger;

  @override
  Future<ServiceDiscoveryScan> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][$_logTag] started backend=native_bonjour');
    final results = <String, ServiceDiscoveryResult>{};
    TvDiscoveryIssue? issue;

    try {
      final reply = await _channel
          .invokeMapMethod<String, Object?>('browse', {
            'serviceType': _serviceType,
            'timeoutMs': timeout.inMilliseconds,
          })
          .timeout(timeout + _channelGrace);
      issue = _consume(reply ?? const {}, results);
    } on TimeoutException {
      issue = TvDiscoveryIssue.timedOut;
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=BROWSE reason=scan_timeout',
      );
    } on PlatformException catch (error) {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] start_failed type=PlatformException '
        'code=${error.code} error=${error.message}',
      );
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=START reason=start_failed',
      );
    } on MissingPluginException {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] start_failed type=MissingPluginException '
        'error=native_bonjour_bridge_not_registered',
      );
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=START reason=start_failed',
      );
    } catch (error) {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] scan_failed type=${error.runtimeType} error=$error',
      );
    }

    final devices = results.values.toList(growable: false);
    _logger.info(
      '[TV][DISCOVERY][$_logTag] completed count=${devices.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return ServiceDiscoveryScan(devices, issue: issue);
  }

  TvDiscoveryIssue? _consume(
    Map<String, Object?> reply,
    Map<String, ServiceDiscoveryResult> results,
  ) {
    final failure = reply['failure'] as String?;
    if (failure != null) {
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=BROWSE reason=$failure '
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
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=PTR reason=ptr_empty',
      );
    }

    for (final name in (reply['unresolved'] as List?) ?? const []) {
      _logger.info('[TV][DISCOVERY][$_logTag] ptr instance=$name');
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=SRV reason=srv_failed instance=$name',
      );
    }

    for (final entry in (reply['services'] as List?) ?? const []) {
      final service = (entry as Map).cast<String, Object?>();
      final name = service['name'] as String? ?? _serviceType;
      _logger.info('[TV][DISCOVERY][$_logTag] ptr instance=$name');

      final rawHost = service['host'] as String?;
      final port = (service['port'] as num?)?.toInt() ?? -1;
      if (rawHost == null || rawHost.isEmpty || port <= 0) {
        _logger.warning(
          '[TV][DISCOVERY][$_logTag] resolve_failed stage=SRV reason=srv_failed instance=$name',
        );
        continue;
      }
      final targetHost = stripTrailingDot(rawHost);
      _logger.info('[TV][DISCOVERY][$_logTag] srv host=$targetHost port=$port');

      final ipv4 = service['ipv4'] as String?;
      if (ipv4 != null) {
        _logger.info(
          '[TV][DISCOVERY][$_logTag] resolved host=$targetHost ip=$ipv4',
        );
      } else {
        _logger.warning(
          '[TV][DISCOVERY][$_logTag] resolve_failed stage=IP reason=ip_failed host=$targetHost',
        );
      }

      if (results.containsKey(targetHost)) continue;
      // Same identity/fallback rules as MdnsServiceDiscovery: keyed by the
      // stable advertised hostname; connect via IPv4 when known, otherwise
      // via the `.local` hostname (resolved by the system resolver).
      results[targetHost] = ServiceDiscoveryResult(
        id: targetHost,
        name: name,
        host: ipv4 ?? targetHost,
        port: port,
        txt: _txtFrom(service['txt']),
      );
      _logger.info('[TV][DISCOVERY][$_logTag] found device=$name');
    }
    return issue;
  }

  Map<String, String> _txtFrom(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String)
          (entry.key as String).toLowerCase(): entry.value?.toString() ?? '',
    };
  }
}
