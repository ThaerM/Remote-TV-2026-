import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:remote_tv_2026/core/network/multicast_lock.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_constants.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/discovery/mdns_android_tv_discovery.dart';

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

  group('MdnsAndroidTvDiscovery', () {
    test(
      'a PTR stream that never completes still returns after the deadline',
      () async {
        final querier = FakeMdnsQuerier()..neverCompleting.add(ptrKey);
        final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

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
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

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
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

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
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, isEmpty);
      expect(querier.stopped, isTrue);
    });

    test('duplicate PTR/SRV answers for the same instance produce exactly one device', () async {
      final querier = FakeMdnsQuerier()
        ..responses[ptrKey] = [ptrRecord(), ptrRecord()]
        ..responses[srvKey] = [srvRecord(), srvRecord()]
        ..responses[ipKey] = [ipRecord()];
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, hasLength(1));
    });

    test('stop() runs even when start() throws', () async {
      final querier = FakeMdnsQuerier()
        ..startError = const SocketException('no network');
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

      final results = await discovery.discover();

      expect(results, isEmpty);
      expect(querier.stopped, isTrue);
    });

    test('logs a completed count line even when nothing is found', () async {
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      final querier = FakeMdnsQuerier();
      final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

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
        records.any(
          (r) => r.message.startsWith('[TV][DISCOVERY][ANDROID_TV] started'),
        ),
        isTrue,
      );
    });

    group('start() failures seen on a real iPhone', () {
      late List<LogRecord> records;

      setUp(() {
        records = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(records.add);
        addTearDown(sub.cancel);
      });

      bool logged(String fragment) =>
          records.any((r) => r.message.contains(fragment));

      Future<void> expectSafeFailure(
        Object error, {
        required String reason,
      }) async {
        final querier = FakeMdnsQuerier()..startError = error;
        final discovery = MdnsAndroidTvDiscovery(querierFactory: () => querier);

        final results = await discovery.discover();

        expect(results, isEmpty);
        expect(querier.stopped, isTrue);
        expect(logged('start_failed type=${error.runtimeType}'), isTrue);
        expect(logged('resolve_failed stage=START reason=$reason'), isTrue);
        expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
      }

      test(
        'an OSError from joinMulticast (errno 48) no longer escapes discover()',
        () => expectSafeFailure(
          const OSError('Address already in use', 48),
          reason: 'socket_bind_failed',
        ),
      );

      test('a SocketException is handled the same way', () {
        return expectSafeFailure(
          const SocketException(
            'bind failed',
            osError: OSError('Address already in use', 98),
          ),
          reason: 'socket_bind_failed',
        );
      });

      test('a privacy/sandbox refusal is classified as restricted', () {
        return expectSafeFailure(
          const OSError('No route to host', 65),
          reason: 'permission_denied_or_restricted',
        );
      });

      test('an arbitrary non-IO error is still caught', () {
        return expectSafeFailure(
          StateError('unexpected'),
          reason: 'start_failed',
        );
      });

      test('a querier factory that throws still completes the scan', () async {
        final discovery = MdnsAndroidTvDiscovery(
          querierFactory: () => throw StateError('no client'),
        );

        final results = await discovery.discover();

        expect(results, isEmpty);
        expect(logged('scan_failed type=StateError'), isTrue);
        expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
      });
    });

    group('multicast lock', () {
      test('is held for the scan and released afterwards', () async {
        final lock = _RecordingLock();
        final querier = FakeMdnsQuerier();
        final discovery = MdnsAndroidTvDiscovery(
          querierFactory: () => querier,
          multicastLock: lock,
        );

        await discovery.discover(timeout: const Duration(milliseconds: 200));

        expect(lock.events, ['acquire', 'release']);
      });

      test('is released even when start() fails', () async {
        final lock = _RecordingLock();
        final querier = FakeMdnsQuerier()
          ..startError = const OSError('Address already in use', 48);
        final discovery = MdnsAndroidTvDiscovery(
          querierFactory: () => querier,
          multicastLock: lock,
        );

        await discovery.discover();

        expect(lock.events, ['acquire', 'release']);
      });
    });

    group('SystemMdnsQuerier', () {
      test('closes the socket it bound when start() fails part-way', () async {
        final closed = Completer<void>();
        final querier = SystemMdnsQuerier(
          clientFactory: (socketFactory) => _FailingAfterBindClient(
            socketFactory,
            onBound: (socket) => socket.listen(null, onDone: closed.complete),
          ),
        );

        await expectLater(querier.start(), throwsA(isA<OSError>()));
        await closed.future.timeout(const Duration(seconds: 2));
        querier.stop();
      });
    });
  });
}

/// Mimics `MDnsClient.start()` binding its socket through the injected
/// factory and then failing in `joinMulticast` - the real iPhone failure.
/// Binds a real loopback UDP socket on an ephemeral port (not multicast).
class _FailingAfterBindClient implements MDnsClient {
  _FailingAfterBindClient(this._socketFactory, {required this.onBound});

  final RawDatagramSocketFactory _socketFactory;
  final void Function(RawDatagramSocket socket) onBound;

  @override
  Future<void> start({
    InternetAddress? listenAddress,
    NetworkInterfacesFactory? interfacesFactory,
    int mDnsPort = 5353,
    InternetAddress? mDnsAddress,
    Function? onError,
  }) async {
    final socket = await _socketFactory(
      InternetAddress.loopbackIPv4,
      0,
      reuseAddress: true,
      reusePort: false,
      ttl: 255,
    );
    onBound(socket);
    throw const OSError('Address already in use', 48);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingLock implements MulticastLock {
  final events = <String>[];

  @override
  Future<void> acquire() async => events.add('acquire');

  @override
  Future<void> release() async => events.add('release');
}
