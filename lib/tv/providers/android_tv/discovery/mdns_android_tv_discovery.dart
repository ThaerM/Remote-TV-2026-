import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/multicast_lock.dart';
import '../android_tv_constants.dart';
import 'android_tv_discovery.dart';

/// The minimal mDNS querying surface [MdnsAndroidTvDiscovery] needs from
/// `package:multicast_dns`'s [MDnsClient], so tests can inject a fake
/// instead of driving real multicast sockets (never available in CI, and
/// [MDnsClient] itself isn't mockable - it's a concrete class).
abstract class MdnsQuerier {
  Future<void> start();
  void stop();
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout,
  });
}

/// The real [MdnsQuerier], backed by [MDnsClient].
///
/// Binds through its own [RawDatagramSocketFactory] purely to keep hold of
/// every socket [MDnsClient.start] creates: if `start()` fails after
/// binding (e.g. `joinMulticast` throwing an `OSError` for one interface),
/// `MDnsClient` never marks itself started, so its own `stop()` is a no-op
/// and the bound UDP 5353 socket would otherwise leak. Bind arguments are
/// passed through unchanged, so network behavior is identical.
class SystemMdnsQuerier implements MdnsQuerier {
  SystemMdnsQuerier({
    @visibleForTesting
    MDnsClient Function(RawDatagramSocketFactory socketFactory)? clientFactory,
  }) {
    _client = (clientFactory ?? _defaultClient)(_bindTracked);
  }

  static MDnsClient _defaultClient(RawDatagramSocketFactory socketFactory) =>
      MDnsClient(rawDatagramSocketFactory: socketFactory);

  late final MDnsClient _client;
  final List<RawDatagramSocket> _sockets = [];
  bool _started = false;

  Future<RawDatagramSocket> _bindTracked(
    dynamic host,
    int port, {
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  }) async {
    final socket = await RawDatagramSocket.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
      ttl: ttl,
    );
    _sockets.add(socket);
    return socket;
  }

  @override
  Future<void> start() async {
    try {
      await _client.start();
      _started = true;
    } catch (_) {
      _closeTrackedSockets();
      rethrow;
    }
  }

  @override
  void stop() {
    if (_started) {
      _started = false;
      _client.stop();
      _sockets.clear();
    } else {
      _closeTrackedSockets();
    }
  }

  void _closeTrackedSockets() {
    for (final socket in _sockets) {
      try {
        socket.close();
      } catch (_) {
        // Already closed - nothing left to release.
      }
    }
    _sockets.clear();
  }

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5),
  }) => _client.lookup<T>(query, timeout: timeout);
}

enum _StartOutcome { started, timedOut, failed }

/// [AndroidTvDiscovery] over raw mDNS (`package:multicast_dns`), used on
/// Android and every other non-iOS platform.
///
/// Every network stage (client start, PTR lookup, and per-instance SRV/IP
/// resolution) races against a single absolute [DateTime] deadline, so a
/// socket bind or lookup stream that never completes can't hang
/// `discover()`. Every error `MDnsClient.start()` can raise is caught -
/// not just [SocketException]: `joinMulticast` throws a bare [OSError],
/// which previously escaped `discover()` entirely (no `completed` line, and
/// `TvProviderRegistry.discoverAll` silently turned it into "no TVs"). A
/// fresh [MdnsQuerier] is created per scan so one scan's wedged socket can
/// never block the next.
class MdnsAndroidTvDiscovery implements AndroidTvDiscovery {
  MdnsAndroidTvDiscovery({
    MdnsQuerier Function()? querierFactory,
    MulticastLock? multicastLock,
  }) : _querierFactory = querierFactory ?? SystemMdnsQuerier.new,
       _multicastLock = multicastLock ?? PlatformMulticastLock(),
       _logger = AppLogger('TV.Discovery.mDNS.AndroidTV');

  final MdnsQuerier Function() _querierFactory;
  final MulticastLock _multicastLock;
  final AppLogger _logger;

  static const _srvStageTimeout = Duration(seconds: 2);
  static const _ipStageTimeout = Duration(seconds: 2);

  /// Scans for up to [timeout] total (all stages combined), de-duplicating
  /// by the stable SRV-advertised hostname - never the resolved IP, which
  /// DHCP can reassign between scans.
  @override
  Future<List<AndroidTvDiscoveryResult>> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][ANDROID_TV] started backend=mdns');

    final deadline = DateTime.now().add(timeout);
    final results = <String, AndroidTvDiscoveryResult>{};
    MdnsQuerier? querier;
    await _multicastLock.acquire();

    try {
      querier = _querierFactory();
      _logger.info(
        '[TV][DISCOVERY][ANDROID_TV] checkpoint=before_client_start',
      );
      final outcome = await _startWithDeadline(querier, deadline);
      _logger.info(
        '[TV][DISCOVERY][ANDROID_TV] checkpoint=after_client_start outcome=${outcome.name}',
      );
      if (outcome == _StartOutcome.started) {
        _logger.info(
          '[TV][DISCOVERY][ANDROID_TV] checkpoint=before_ptr_collect',
        );
        final ptrRecords = await _collectPtrRecords(querier, deadline);
        _logger.info(
          '[TV][DISCOVERY][ANDROID_TV] checkpoint=after_ptr_collect count=${ptrRecords.length}',
        );
        if (ptrRecords.isEmpty) {
          _logger.warning(
            '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=PTR reason=ptr_empty',
          );
        }
        final resolved = await Future.wait(
          ptrRecords.map((ptr) => _resolveInstance(querier!, ptr, deadline)),
        );
        for (final result in resolved) {
          if (result != null) {
            results[result.id] = result;
            _logger.info(
              '[TV][DISCOVERY][ANDROID_TV] found device=${result.name}',
            );
          }
        }
      } else if (outcome == _StartOutcome.timedOut) {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=START reason=scan_timeout',
        );
      }
    } catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] scan_failed type=${error.runtimeType} '
        'error=${_describe(error)}',
      );
    } finally {
      _logger.info('[TV][DISCOVERY][ANDROID_TV] checkpoint=finally_stop_start');
      if (querier != null) _safeStop(querier);
      await _multicastLock.release();
      _logger.info('[TV][DISCOVERY][ANDROID_TV] checkpoint=finally_stop_done');
    }

    final devices = results.values.toList(growable: false);
    _logger.info(
      '[TV][DISCOVERY][ANDROID_TV] completed count=${devices.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return devices;
  }

  void _safeStop(MdnsQuerier querier) {
    try {
      querier.stop();
    } catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] stop_failed type=${error.runtimeType}',
      );
    }
  }

  Duration _remaining(DateTime deadline) => deadline.difference(DateTime.now());

  Duration _boundedRemaining(DateTime deadline, Duration cap) {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining < cap ? remaining : cap;
  }

  /// Races `querier.start()` against the deadline and turns any failure -
  /// whatever its type - into [_StartOutcome.failed] after logging it.
  /// `MDnsClient.start()` can also hang indefinitely on a real device and
  /// can't be cancelled, so a timed-out start is abandoned in the
  /// background.
  Future<_StartOutcome> _startWithDeadline(
    MdnsQuerier querier,
    DateTime deadline,
  ) async {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) return _StartOutcome.timedOut;

    final completer = Completer<_StartOutcome>();
    Future<void> startFuture;
    try {
      startFuture = querier.start();
    } catch (error) {
      _logStartFailure(error);
      return _StartOutcome.failed;
    }
    unawaited(
      startFuture.then(
        (_) {
          _logger.info(
            '[TV][DISCOVERY][ANDROID_TV] checkpoint=start_future_completed',
          );
          if (!completer.isCompleted) completer.complete(_StartOutcome.started);
        },
        onError: (Object error) {
          _logStartFailure(error);
          if (!completer.isCompleted) completer.complete(_StartOutcome.failed);
        },
      ),
    );
    _logger.info('[TV][DISCOVERY][ANDROID_TV] checkpoint=start_future_created');
    final timer = Timer(remaining, () {
      if (!completer.isCompleted) {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] checkpoint=start_deadline_fired stage=client_start',
        );
        completer.complete(_StartOutcome.timedOut);
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
    }
  }

  void _logStartFailure(Object error) {
    final osError = _osErrorOf(error);
    _logger.warning(
      '[TV][DISCOVERY][ANDROID_TV] start_failed type=${error.runtimeType} '
      'errno=${osError?.errorCode ?? 'none'} error=${_describe(error)}',
    );
    _logger.warning(
      '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=START '
      'reason=${classifyMdnsStartError(error)}',
    );
  }

  Future<List<PtrResourceRecord>> _collectPtrRecords(
    MdnsQuerier querier,
    DateTime deadline,
  ) async {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) return const [];

    final ptrRecords = <PtrResourceRecord>[];
    final completer = Completer<void>();
    final timer = Timer(remaining, () {
      if (!completer.isCompleted) {
        _logger.info(
          '[TV][DISCOVERY][ANDROID_TV] checkpoint=start_deadline_fired stage=ptr',
        );
        completer.complete();
      }
    });

    final sub = querier
        .lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer(
            '${AndroidTvConstants.mdnsServiceType}.local',
          ),
          timeout: remaining,
        )
        .listen(
          (ptr) {
            _logger.info(
              '[TV][DISCOVERY][ANDROID_TV] ptr instance=${_friendlyNameFrom(ptr.domainName)}',
            );
            ptrRecords.add(ptr);
          },
          onError: (Object error) {
            _logger.warning(
              '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=PTR '
              'type=${error.runtimeType}',
            );
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: false,
        );

    try {
      await completer.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }

    return ptrRecords;
  }

  Future<AndroidTvDiscoveryResult?> _resolveInstance(
    MdnsQuerier querier,
    PtrResourceRecord ptr,
    DateTime deadline,
  ) async {
    final friendlyName = _friendlyNameFrom(ptr.domainName);
    _logger.info(
      '[TV][DISCOVERY][ANDROID_TV] checkpoint=before_srv_lookup instance=$friendlyName',
    );
    final srv = await _collectFirst<SrvResourceRecord>(
      querier,
      ResourceRecordQuery.service(ptr.domainName),
      _boundedRemaining(deadline, _srvStageTimeout),
      stage: 'srv',
    );
    if (srv == null) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=SRV reason=srv_failed instance=$friendlyName',
      );
      return null;
    }
    final targetHost = stripTrailingDot(srv.target);
    _logger.info(
      '[TV][DISCOVERY][ANDROID_TV] srv host=$targetHost port=${srv.port}',
    );

    final ipRecord = await _collectFirst<IPAddressResourceRecord>(
      querier,
      ResourceRecordQuery.addressIPv4(srv.target),
      _boundedRemaining(deadline, _ipStageTimeout),
      stage: 'ip',
    );
    final resolvedIp = ipRecord?.address.address;
    if (resolvedIp != null) {
      _logger.info(
        '[TV][DISCOVERY][ANDROID_TV] resolved host=$targetHost ip=$resolvedIp',
      );
    } else {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=IP reason=ip_failed host=$targetHost',
      );
    }

    // dart:io's socket APIs resolve `.local` hostnames via the system
    // resolver, so a device with a valid SRV record but no A/AAAA answer is
    // still reachable - prefer the resolved IP, but don't drop the device
    // just because that one extra lookup didn't complete in time.
    return AndroidTvDiscoveryResult(
      // Keyed by the stable SRV hostname, not the resolved IP - a DHCP
      // lease change must not change this device's identity between scans.
      id: targetHost,
      name: friendlyName,
      host: resolvedIp ?? targetHost,
      port: srv.port,
    );
  }

  Future<T?> _collectFirst<T extends ResourceRecord>(
    MdnsQuerier querier,
    ResourceRecordQuery query,
    Duration timeout, {
    required String stage,
  }) async {
    if (timeout <= Duration.zero) return null;

    final completer = Completer<T?>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] checkpoint=start_deadline_fired stage=$stage',
        );
        completer.complete(null);
      }
    });

    final sub = querier
        .lookup<T>(query, timeout: timeout)
        .listen(
          (record) {
            if (!completer.isCompleted) completer.complete(record);
          },
          onError: (Object error) {
            if (!completer.isCompleted) completer.complete(null);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete(null);
          },
          cancelOnError: false,
        );

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  String _friendlyNameFrom(String domainName) {
    final serviceSuffix = '.${AndroidTvConstants.mdnsServiceType}.local';
    final instance = domainName.endsWith(serviceSuffix)
        ? domainName.substring(0, domainName.length - serviceSuffix.length)
        : domainName;
    return instance.isEmpty ? 'Android TV' : instance;
  }
}

OSError? _osErrorOf(Object error) => switch (error) {
  OSError() => error,
  SocketException(:final osError) => osError,
  _ => null,
};

String _describe(Object error) =>
    _osErrorOf(error)?.message ??
    (error is SocketException ? error.message : error.toString());

/// Maps a `MDnsClient.start()` failure onto the discovery error model.
/// errno values: EADDRINUSE is 48 on Darwin and 98 on Linux/Android;
/// EPERM (1), EACCES (13) and EHOSTUNREACH (65 on Darwin, 113 on Linux) are
/// what a sandbox/privacy policy refusing multicast looks like.
@visibleForTesting
String classifyMdnsStartError(Object error) {
  switch (_osErrorOf(error)?.errorCode) {
    case 48 || 98:
      return 'socket_bind_failed';
    case 1 || 13 || 65 || 113:
      return 'permission_denied_or_restricted';
    default:
      return 'start_failed';
  }
}
