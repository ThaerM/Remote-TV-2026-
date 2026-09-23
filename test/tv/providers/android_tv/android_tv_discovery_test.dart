import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_constants.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/discovery/android_tv_discovery.dart';

/// A fully scripted, in-memory [MdnsQuerier] - no real sockets, so these
/// tests run identically in CI as they do locally. Each lookup is keyed by
/// (record type, fully-qualified name); a query with no configured response
/// resolves to an empty (immediately-closed) stream, and a query listed in
/// [neverCompleting] returns a stream that never emits and never closes -
/// reproducing the real hang this suite guards against.
class FakeMdnsQuerier implements MdnsQuerier {
  bool started = false;
  bool stopped = false;
  Object? startError;
  Duration startDelay = Duration.zero;

  final Map<String, List<ResourceRecord>> responses = {};
  final Map<String, Duration> delays = {};
  final Set<String> neverCompleting = {};

  @override
  Future<void> start() async {
    if (startDelay > Duration.zero) {
      await Future<void>.delayed(startDelay);
    }
    if (startError != null) {
      throw startError!;
    }
    started = true;
  }

  @override
  void stop() {
    stopped = true;
  }

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final key = _key(
      recordType: query.resourceRecordType,
      fqdn: query.fullyQualifiedName,
    );
    final controller = StreamController<T>();

    if (neverCompleting.contains(key)) {
      return controller.stream;
    }

    final delay = delays[key];
    final records = responses[key] ?? const <ResourceRecord>[];

    scheduleMicrotask(() async {
      if (delay != null) {
        await Future<void>.delayed(delay);
      }
      for (final record in records) {
        if (!controller.isClosed) controller.add(record as T);
      }
      if (!controller.isClosed) await controller.close();
    });

    return controller.stream;
  }

  static String keyFor({required int recordType, required String fqdn}) =>
      _key(recordType: recordType, fqdn: fqdn);

  static String _key({required int recordType, required String fqdn}) =>
      '$recordType|${fqdn.toLowerCase()}';
}

void main() {
  const ptrFqdn = '${AndroidTvConstants.mdnsServiceType}.local';
  const instanceName =
      'Family room TV.${AndroidTvConstants.mdnsServiceType}.local';
  const srvTarget = 'Android_9ca7000de06743959d7010b65da4d5c7.local.';
  const strippedSrvTarget = 'Android_9ca7000de06743959d7010b65da4d5c7.local';

  final ptrKey = FakeMdnsQuerier.keyFor(
    recordType: ResourceRecordType.serverPointer,
    fqdn: ptrFqdn,
  );
  final srvKey = FakeMdnsQuerier.keyFor(
    recordType: ResourceRecordType.service,
    fqdn: instanceName,
  );
  final ipKey = FakeMdnsQuerier.keyFor(
    recordType: ResourceRecordType.addressIPv4,
    fqdn: srvTarget,
  );

  PtrResourceRecord ptrRecord() =>
      const PtrResourceRecord(ptrFqdn, 0, domainName: instanceName);

  SrvResourceRecord srvRecord() => const SrvResourceRecord(
    instanceName,
    0,
    target: srvTarget,
    port: AndroidTvConstants.remoteControlPort,
    priority: 0,
    weight: 0,
  );

  IPAddressResourceRecord ipRecord() => IPAddressResourceRecord(
    srvTarget,
    0,
    address: InternetAddress('192.168.1.42'),
  );

  group('AndroidTvDiscovery', () {
    test(
      'a PTR stream that never completes still returns after the deadline',
      () async {
        final querier = FakeMdnsQuerier()..neverCompleting.add(ptrKey);
        final discovery = AndroidTvDiscovery(querierFactory: () => querier);

        final stopwatch = Stopwatch()..start();
        final results = await discovery.discover(
          timeout: const Duration(milliseconds: 300),
        );
        stopwatch.stop();

        expect(results, isEmpty);
        expect(querier.started, isTrue);
        expect(querier.stopped, isTrue);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      },
    );

    test('PTR found + SRV found returns one device', () async {
      final querier = FakeMdnsQuerier()
        ..responses[ptrKey] = [ptrRecord()]
        ..responses[srvKey] = [srvRecord()]
        ..responses[ipKey] = [ipRecord()];
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, hasLength(1));
      expect(results.single.name, 'Family room TV');
      expect(results.single.host, '192.168.1.42');
      expect(results.single.port, AndroidTvConstants.remoteControlPort);
      expect(querier.stopped, isTrue);
    });

    test('SRV found but IP resolution delayed beyond its budget falls back to the SRV hostname', () async {
      final querier = FakeMdnsQuerier()
        ..responses[ptrKey] = [ptrRecord()]
        ..responses[srvKey] = [srvRecord()]
        ..delays[ipKey] = const Duration(seconds: 5);
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final stopwatch = Stopwatch()..start();
      final results = await discovery.discover(
        timeout: const Duration(milliseconds: 400),
      );
      stopwatch.stop();

      expect(results, hasLength(1));
      expect(results.single.host, strippedSrvTarget);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('SRV resolution failure for an instance completes the scan cleanly without it', () async {
      final querier = FakeMdnsQuerier()..responses[ptrKey] = [ptrRecord()];
      // No SRV response configured - lookup resolves to an empty stream.
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, isEmpty);
      expect(querier.stopped, isTrue);
    });

    test('duplicate PTR/SRV answers for the same instance produce exactly one device', () async {
      final querier = FakeMdnsQuerier()
        ..responses[ptrKey] = [ptrRecord(), ptrRecord()]
        ..responses[srvKey] = [srvRecord(), srvRecord()]
        ..responses[ipKey] = [ipRecord()];
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, hasLength(1));
    });

    test('stop() runs even when start() throws', () async {
      final querier = FakeMdnsQuerier()
        ..startError = const SocketException('no network');
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, isEmpty);
      expect(querier.stopped, isTrue);
    });

    test('logs a completed count line even when nothing is found', () async {
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      final querier = FakeMdnsQuerier();
      final discovery = AndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, isEmpty);
      expect(
        records.any(
          (r) => r.message.contains(
            '[TV][DISCOVERY][ANDROID_TV] completed count=0',
          ),
        ),
        isTrue,
      );
      expect(
        records.any((r) => r.message == '[TV][DISCOVERY][ANDROID_TV] started'),
        isTrue,
      );
    });
  });
}
