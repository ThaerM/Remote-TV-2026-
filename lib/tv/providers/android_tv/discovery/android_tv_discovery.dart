import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../domain/tv_domain.dart';
import '../android_tv_constants.dart';

/// The minimal mDNS querying surface [AndroidTvDiscovery] needs from
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

class _SystemMdnsQuerier implements MdnsQuerier {
  final MDnsClient _client = MDnsClient();

  @override
  Future<void> start() => _client.start();

  @override
  void stop() => _client.stop();

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5),
  }) => _client.lookup<T>(query, timeout: timeout);
}

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
/// Every network stage (client start, PTR lookup, and per-instance SRV/IP
/// resolution) races against a single absolute [DateTime] deadline rather
/// than relying on `package:multicast_dns`'s own per-lookup timers or on a
/// raw `await for` completing by itself - on a real device, `MDnsClient`'s
/// socket bind (`start()`) and its lookup streams have no guarantee of
/// ever completing (a truly silent TV, a blocked multicast join, or an
/// iOS Local Network permission race can all leave them pending forever),
/// and a naked `await` on any of them would hang `discover()`
/// indefinitely with no way to cancel the underlying I/O. Racing each
/// stage against a [Timer] tied to the same deadline guarantees
/// `discover()` always returns and always logs a `completed` line, even
/// if the abandoned system call itself never resolves in the background.
/// A fresh [MdnsQuerier] (and thus a fresh `MDnsClient`) is created per
/// scan so one scan's wedged socket can never block the next.
class AndroidTvDiscovery {
  AndroidTvDiscovery({MdnsQuerier Function()? querierFactory})
    : _querierFactory = querierFactory ?? _SystemMdnsQuerier.new,
      _logger = AppLogger('TV.Discovery.mDNS.AndroidTV');

  final MdnsQuerier Function() _querierFactory;
  final AppLogger _logger;

  static const _srvStageTimeout = Duration(seconds: 2);
  static const _ipStageTimeout = Duration(seconds: 2);

  /// Scans for up to [timeout] total (all stages combined), de-duplicating
  /// by the stable SRV-advertised hostname - never the resolved IP, which
  /// DHCP can reassign between scans.
  Future<List<AndroidTvDiscoveryResult>> discover({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info('[TV][DISCOVERY][ANDROID_TV] started');

    final deadline = DateTime.now().add(timeout);
    final querier = _querierFactory();
    final results = <String, AndroidTvDiscoveryResult>{};

    try {
      final started = await _startWithDeadline(querier, deadline);
      if (started) {
        final ptrRecords = await _collectPtrRecords(querier, deadline);
        final resolved = await Future.wait(
          ptrRecords.map((ptr) => _resolveInstance(querier, ptr, deadline)),
        );
        for (final result in resolved) {
          if (result != null) {
            results[result.id] = result;
            _logger.info(
              '[TV][DISCOVERY][ANDROID_TV] found device=${result.name}',
            );
          }
        }
      } else {
        _logger.warning(
          '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=START',
        );
      }
    } on SocketException catch (error) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] network unavailable: ${error.message}',
      );
    } finally {
      _safeStop(querier);
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
      _logger.warning('[TV][DISCOVERY][ANDROID_TV] stop_failed error=$error');
    }
  }

  Duration _remaining(DateTime deadline) => deadline.difference(DateTime.now());

  Duration _boundedRemaining(DateTime deadline, Duration cap) {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining < cap ? remaining : cap;
  }

  /// Races `querier.start()` against the deadline. `MDnsClient.start()` can
  /// hang indefinitely on a real device (see class doc) - there is no way
  /// to cancel it, so a timed-out start is treated as failure and the
  /// abandoned future is left to complete on its own in the background.
  Future<bool> _startWithDeadline(
    MdnsQuerier querier,
    DateTime deadline,
  ) async {
    final remaining = _remaining(deadline);
    if (remaining <= Duration.zero) return false;

    final completer = Completer<bool>();
    unawaited(
      querier.start().then(
        (_) {
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      ),
    );
    final timer = Timer(remaining, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
    }
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
      if (!completer.isCompleted) completer.complete();
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
              '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=PTR error=$error',
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

    final srv = await _collectFirst<SrvResourceRecord>(
      querier,
      ResourceRecordQuery.service(ptr.domainName),
      _boundedRemaining(deadline, _srvStageTimeout),
    );
    if (srv == null) {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=SRV instance=$friendlyName',
      );
      return null;
    }
    final targetHost = _stripTrailingDot(srv.target);
    _logger.info(
      '[TV][DISCOVERY][ANDROID_TV] srv host=$targetHost port=${srv.port}',
    );

    final ipRecord = await _collectFirst<IPAddressResourceRecord>(
      querier,
      ResourceRecordQuery.addressIPv4(srv.target),
      _boundedRemaining(deadline, _ipStageTimeout),
    );
    final resolvedIp = ipRecord?.address.address;
    if (resolvedIp != null) {
      _logger.info(
        '[TV][DISCOVERY][ANDROID_TV] resolved host=$targetHost ip=$resolvedIp',
      );
    } else {
      _logger.warning(
        '[TV][DISCOVERY][ANDROID_TV] resolve_failed stage=IP host=$targetHost',
      );
    }

    // dart:io's socket APIs resolve `.local` hostnames via the system
    // resolver, so a device with a valid SRV record but no A/AAAA answer is
    // still reachable - prefer the resolved IP, but don't drop the device
    // just because that one extra lookup didn't complete in time.
    final host = resolvedIp ?? targetHost;

    return AndroidTvDiscoveryResult(
      // Keyed by the stable SRV hostname, not the resolved IP - a DHCP
      // lease change must not change this device's identity between scans.
      id: targetHost,
      name: friendlyName,
      host: host,
      port: srv.port,
    );
  }

  Future<T?> _collectFirst<T extends ResourceRecord>(
    MdnsQuerier querier,
    ResourceRecordQuery query,
    Duration timeout,
  ) async {
    if (timeout <= Duration.zero) return null;

    final completer = Completer<T?>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
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

  String _stripTrailingDot(String value) =>
      value.endsWith('.') ? value.substring(0, value.length - 1) : value;
}

TvDevice discoveryResultToDevice(AndroidTvDiscoveryResult result) {
  return TvDevice(
    id: 'android_tv:${result.id}',
    name: result.name,
    platform: TvPlatform.androidTv,
    host: result.host,
  );
}
