import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_constants.dart';
import 'package:remote_tv_2026/tv/providers/shared/service_discovery/native_bonjour_service_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeBonjourServiceDiscovery.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<LogRecord> records;
  late List<MethodCall> calls;

  setUp(() {
    records = <LogRecord>[];
    calls = <MethodCall>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });

  bool logged(String fragment) =>
      records.any((r) => r.message.contains(fragment));

  void reply(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  const familyRoomTv = {
    'name': 'Family room TV',
    'host': 'Android_9ca7000de06743959d7010b65da4d5c7.local.',
    'port': 6466,
    'ipv4': '192.168.1.42',
  };

  group('NativeBonjourServiceDiscovery', () {
    test('asks the native side for the Android TV Remote v2 service', () async {
      reply((_) async => {'services': <Object>[], 'browsed': 0});

      await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover(timeout: const Duration(seconds: 3));

      expect(calls.single.method, 'browse');
      expect(calls.single.arguments, {
        'serviceType': AndroidTvConstants.mdnsServiceType,
        'timeoutMs': 3000,
      });
    });

    test('a resolved service becomes one device, connected via IPv4', () async {
      reply(
        (_) async => {
          'services': [familyRoomTv],
          'browsed': 1,
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, hasLength(1));
      expect(results.single.name, 'Family room TV');
      expect(
        results.single.id,
        'Android_9ca7000de06743959d7010b65da4d5c7.local',
      );
      expect(results.single.host, '192.168.1.42');
      expect(results.single.port, 6466);
      expect(logged('found device=Family room TV'), isTrue);
      expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=1'), isTrue);
    });

    test('TXT key/values from the native side are passed through', () async {
      reply(
        (_) async => {
          'services': [
            {
              ...familyRoomTv,
              'txt': {'FN': 'Family room TV', 'bt': '3C:31:74:2D:25:D9'},
            },
          ],
          'browsed': 1,
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results.single.txt, {
        'fn': 'Family room TV',
        'bt': '3C:31:74:2D:25:D9',
      });
    });

    test('without an IPv4 answer the .local hostname is kept', () async {
      reply(
        (_) async => {
          'services': [
            {...familyRoomTv}..remove('ipv4'),
          ],
          'browsed': 1,
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(
        results.single.host,
        'Android_9ca7000de06743959d7010b65da4d5c7.local',
      );
      expect(logged('resolve_failed stage=IP reason=ip_failed'), isTrue);
    });

    test('duplicate answers for the same host produce one device', () async {
      reply(
        (_) async => {
          'services': [familyRoomTv, familyRoomTv],
          'browsed': 1,
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, hasLength(1));
    });

    test('a denied local network permission is reported, not silent', () async {
      reply(
        (_) async => {
          'services': <Object>[],
          'browsed': 0,
          'failure': 'permission_denied_or_restricted',
          'detail': '-65570: PolicyDenied',
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(
        logged(
          'resolve_failed stage=BROWSE reason=permission_denied_or_restricted',
        ),
        isTrue,
      );
      expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
    });

    test('an empty browse is reported as ptr_empty', () async {
      reply((_) async => {'services': <Object>[], 'browsed': 0});

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(logged('resolve_failed stage=PTR reason=ptr_empty'), isTrue);
    });

    test('services that never resolved are reported as srv_failed', () async {
      reply(
        (_) async => {
          'services': <Object>[],
          'unresolved': ['Family room TV'],
          'browsed': 1,
        },
      );

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(
        logged(
          'resolve_failed stage=SRV reason=srv_failed instance=Family room TV',
        ),
        isTrue,
      );
    });

    test('a PlatformException never escapes discover()', () async {
      reply((_) async => throw PlatformException(code: 'bad_arguments'));

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(
        logged('start_failed type=PlatformException code=bad_arguments'),
        isTrue,
      );
      expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
    });

    test('a missing native bridge never escapes discover()', () async {
      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(logged('start_failed type=MissingPluginException'), isTrue);
      expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
    });

    test(
      'a native side that never replies is bounded by the timeout',
      () async {
        reply((_) => Completer<Object?>().future);

        final stopwatch = Stopwatch()..start();
        final scan = await NativeBonjourServiceDiscovery(
          serviceType: AndroidTvConstants.mdnsServiceType,
          logTag: 'ANDROID_TV',
          channelGrace: const Duration(milliseconds: 100),
        ).discover(timeout: const Duration(milliseconds: 200));
        final results = scan.results;
        expect(scan.issue, TvDiscoveryIssue.timedOut);

        expect(results, isEmpty);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
        expect(
          logged('resolve_failed stage=BROWSE reason=scan_timeout'),
          isTrue,
        );
        expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
      },
    );

    test('a malformed reply is logged and still completes', () async {
      reply((_) async => {'services': 'not a list'});

      final results = (await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover()).results;

      expect(results, isEmpty);
      expect(logged('scan_failed'), isTrue);
      expect(logged('[TV][DISCOVERY][ANDROID_TV] completed count=0'), isTrue);
    });
  });
}
