import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/multicast_lock.dart';
import '../../../domain/tv_domain.dart';
import 'service_discovery.dart';

/// The minimal mDNS querying surface [MdnsServiceDiscovery] needs from
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

typedef _StartResult = ({_StartOutcome outcome, TvDiscoveryIssue? issue});

/// [ServiceDiscovery] over raw mDNS (`package:multicast_dns`), used on
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
class MdnsServiceDiscovery implements ServiceDiscovery {
  MdnsServiceDiscovery({
    required this._serviceType,
    required this._logTag,
    this._collectTxt = false,
    MdnsQuerier Function()? querierFactory,
    MulticastLock? multicastLock,
  }) : _querierFactory = querierFactory ?? SystemMdnsQuerier.new,
       _multicastLock = multicastLock ?? PlatformMulticastLock(),
       _logger = AppLogger('TV.Discovery.mDNS.$_logTag');

  /// e.g. `_androidtvremote2._tcp` (no trailing `.local`).
  final String _serviceType;

  /// Upper-case tag used in `[TV][DISCOVERY][<TAG>]` log lines.
  final String _logTag;

  /// Also look up each instance's TXT record (in parallel with its A
  /// record, within the same budget). Off unless a provider needs it.
  final bool _collectTxt;

  final MdnsQuerier Function() _querierFactory;
  final MulticastLock _multicastLock;
  final AppLogger _logger;

  static const _srvStageTimeout = Duration(seconds: 2);
  static const _ipStageTimeout = Duration(seconds: 2);

  /// Scans for up to [timeout] total (all stages combined), de-duplicating
  /// by the stable SRV-advertised hostname - never the resolved IP, which
  /// DHCP can reassign between scans.
  @override
  Future<ServiceDiscoveryScan> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][$_logTag] started backend=mdns');

    final deadline = DateTime.now().add(timeout);
    final results = <String, ServiceDiscoveryResult>{};
    TvDiscoveryIssue? issue;
    MdnsQuerier? querier;
    await _multicastLock.acquire();

    try {
      querier = _querierFactory();
      final start = await _startWithDeadline(querier, deadline);
      final outcome = start.outcome;
      issue = start.issue;
      if (outcome == _StartOutcome.started) {
        final ptrRecords = await _collectPtrRecords(querier, deadline);
        if (ptrRecords.isEmpty) {
          _logger.warning(
            '[TV][DISCOVERY][$_logTag] resolve_failed stage=PTR reason=ptr_empty',
          );
        }
        final resolved = await Future.wait(
          ptrRecords.map((ptr) => _resolveInstance(querier!, ptr, deadline)),
        );
        for (final result in resolved) {
          if (result != null) {
            results[result.id] = result;
            _logger.info(
              '[TV][DISCOVERY][$_logTag] found device=${result.name}',
            );
          }
        }
      } else if (outcome == _StartOutcome.timedOut) {
        _logger.warning(
          '[TV][DISCOVERY][$_logTag] resolve_failed stage=START reason=scan_timeout',
        );
      }
    } catch (error) {
      issue = TvDiscoveryIssue.failed;
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] scan_failed type=${error.runtimeType} '
        'error=${_describe(error)}',
      );
    } finally {
      if (querier != null) _safeStop(querier);
      await _multicastLock.release();
    }

    final devices = results.values.toList(growable: false);
    _logger.info(
      '[TV][DISCOVERY][$_logTag] completed count=${devices.length} '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
    return ServiceDiscoveryScan(devices, issue: issue);
  }

  void _safeStop(MdnsQuerier querier) {
    try {
      querier.stop();
    } catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] stop_failed type=${error.runtimeType}',
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
  Future<_StartResult> _startWithDeadline(
    MdnsQuerier querier,
    DateTime deadline,
  ) async {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) {
      return (
        outcome: _StartOutcome.timedOut,
        issue: TvDiscoveryIssue.timedOut,
      );
    }

    final completer = Completer<_StartResult>();
    Future<void> startFuture;
    try {
      startFuture = querier.start();
    } catch (error) {
      return (outcome: _StartOutcome.failed, issue: _logStartFailure(error));
    }
    unawaited(
      startFuture.then(
        (_) {
          if (!completer.isCompleted) {
            completer.complete((outcome: _StartOutcome.started, issue: null));
          }
        },
        onError: (Object error) {
          final issue = _logStartFailure(error);
          if (!completer.isCompleted) {
            completer.complete((outcome: _StartOutcome.failed, issue: issue));
          }
        },
      ),
    );
    final timer = Timer(remaining, () {
      if (!completer.isCompleted) {
        _logger.warning(
          '[TV][DISCOVERY][$_logTag] deadline_fired stage=client_start',
        );
        completer.complete((
          outcome: _StartOutcome.timedOut,
          issue: TvDiscoveryIssue.timedOut,
        ));
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
    }
  }

  TvDiscoveryIssue _logStartFailure(Object error) {
    final osError = _osErrorOf(error);
    final reason = classifyMdnsStartError(error);
    _logger.warning(
      '[TV][DISCOVERY][$_logTag] start_failed type=${error.runtimeType} '
      'errno=${osError?.errorCode ?? 'none'} error=${_describe(error)}',
    );
    _logger.warning(
      '[TV][DISCOVERY][$_logTag] resolve_failed stage=START '
      'reason=$reason',
    );
    return switch (reason) {
      'permission_denied_or_restricted' => TvDiscoveryIssue.multicastRestricted,
      'network_unavailable' => TvDiscoveryIssue.networkUnavailable,
      _ => TvDiscoveryIssue.failed,
    };
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
        _logger.info('[TV][DISCOVERY][$_logTag] deadline_fired stage=ptr');
        completer.complete();
      }
    });

    final sub = querier
        .lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('$_serviceType.local'),
          timeout: remaining,
        )
        .listen(
          (ptr) {
            _logger.info(
              '[TV][DISCOVERY][$_logTag] ptr instance=${_friendlyNameFrom(ptr.domainName)}',
            );
            ptrRecords.add(ptr);
          },
          onError: (Object error) {
            _logger.warning(
              '[TV][DISCOVERY][$_logTag] resolve_failed stage=PTR '
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

  Future<ServiceDiscoveryResult?> _resolveInstance(
    MdnsQuerier querier,
    PtrResourceRecord ptr,
    DateTime deadline,
  ) async {
    final friendlyName = _friendlyNameFrom(ptr.domainName);
    final srv = await _collectFirst<SrvResourceRecord>(
      querier,
      ResourceRecordQuery.service(ptr.domainName),
      _boundedRemaining(deadline, _srvStageTimeout),
      stage: 'srv',
    );
    if (srv == null) {
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=SRV reason=srv_failed instance=$friendlyName',
      );
      return null;
    }
    final targetHost = stripTrailingDot(srv.target);
    _logger.info(
      '[TV][DISCOVERY][$_logTag] srv host=$targetHost port=${srv.port}',
    );

    final ipBudget = _boundedRemaining(deadline, _ipStageTimeout);
    final txtFuture = _collectTxt
        ? _collectFirst<TxtResourceRecord>(
            querier,
            ResourceRecordQuery.text(ptr.domainName),
            ipBudget,
            stage: 'txt',
          )
        : Future<TxtResourceRecord?>.value();
    final ipRecord = await _collectFirst<IPAddressResourceRecord>(
      querier,
      ResourceRecordQuery.addressIPv4(srv.target),
      ipBudget,
      stage: 'ip',
    );
    final txtRecord = await txtFuture;
    final resolvedIp = ipRecord?.address.address;
    if (resolvedIp != null) {
      _logger.info(
        '[TV][DISCOVERY][$_logTag] resolved host=$targetHost ip=$resolvedIp',
      );
    } else {
      _logger.warning(
        '[TV][DISCOVERY][$_logTag] resolve_failed stage=IP reason=ip_failed host=$targetHost',
      );
    }

    // dart:io's socket APIs resolve `.local` hostnames via the system
    // resolver, so a device with a valid SRV record but no A/AAAA answer is
    // still reachable - prefer the resolved IP, but don't drop the device
    // just because that one extra lookup didn't complete in time.
    return ServiceDiscoveryResult(
      // Keyed by the stable SRV hostname, not the resolved IP - a DHCP
      // lease change must not change this device's identity between scans.
      id: targetHost,
      name: friendlyName,
      host: resolvedIp ?? targetHost,
      port: srv.port,
      txt: txtRecord == null
          ? const {}
          : parseTxtEntries(txtRecord.text.split('\n')),
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
          '[TV][DISCOVERY][$_logTag] deadline_fired stage=$stage',
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
    final serviceSuffix = '.$_serviceType.local';
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
/// what a sandbox/privacy policy refusing multicast looks like; ENETDOWN /
/// ENETUNREACH (50/51 on Darwin, 100/101 on Linux) mean there's no usable
/// network at all.
@visibleForTesting
String classifyMdnsStartError(Object error) {
  switch (_osErrorOf(error)?.errorCode) {
    case 48 || 98:
      return 'socket_bind_failed';
    case 1 || 13 || 65 || 113:
      return 'permission_denied_or_restricted';
    case 50 || 51 || 100 || 101:
      return 'network_unavailable';
    default:
      return 'start_failed';
  }
}
