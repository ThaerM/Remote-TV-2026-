import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_constants.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/android_tv_provider.dart';
import 'package:remote_tv_2026/tv/providers/shared/service_discovery/service_discovery.dart';
import 'package:remote_tv_2026/tv/providers/shared/service_discovery/mdns_service_discovery.dart';
import 'package:remote_tv_2026/tv/providers/shared/service_discovery/native_bonjour_service_discovery.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/mdns_service_discovery_test.dart' show FakeMdnsQuerier;

class _ScanDiscovery implements ServiceDiscovery {
  _ScanDiscovery(this.scan);
  final ServiceDiscoveryScan scan;

  @override
  Future<ServiceDiscoveryScan> discover({Duration? timeout}) async => scan;
}

AndroidTvProvider _provider({
  ServiceDiscovery? discovery,
  Future<bool> Function(String host, int port)? probePort,
}) {
  return AndroidTvProvider(
    store: AndroidTvPairedDeviceStore(secureStore: InMemoryCredentialStore()),
    discovery: discovery,
    probePort: probePort,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AndroidTvProvider.discover', () {
    test('maps results to devices and carries the scan issue', () async {
      final provider = _provider(
        discovery: _ScanDiscovery(
          const ServiceDiscoveryScan([
            ServiceDiscoveryResult(
              id: 'Android_x.local',
              name: 'Family room TV',
              host: '192.168.1.42',
              port: 6466,
            ),
          ], issue: TvDiscoveryIssue.timedOut),
        ),
      );

      final outcome = await provider.discover();

      expect(outcome.devices.single.id, 'android_tv:Android_x.local');
      expect(outcome.devices.single.host, '192.168.1.42');
      expect(outcome.issues, {TvDiscoveryIssue.timedOut});
      provider.dispose();
    });
  });

  group('AndroidTvProvider.probeHost', () {
    test('finds a TV listening on the remote-control port', () async {
      final probed = <int>[];
      final provider = _provider(
        probePort: (host, port) async {
          probed.add(port);
          return port == 6466;
        },
      );

      final device = await provider.probeHost('192.168.1.42');

      expect(device?.platform, TvPlatform.androidTv);
      expect(device?.host, '192.168.1.42');
      expect(device?.id, 'android_tv:192.168.1.42');
      expect(probed, [6466]);
      provider.dispose();
    });

    test('falls back to the pairing port', () async {
      final provider = _provider(probePort: (_, port) async => port == 6467);

      expect(await provider.probeHost('10.0.0.9'), isNotNull);
      provider.dispose();
    });

    test('returns null when neither port answers', () async {
      final provider = _provider(probePort: (_, _) async => false);

      expect(await provider.probeHost('10.0.0.9'), isNull);
      provider.dispose();
    });
  });

  group('mDNS start failures map to discovery issues', () {
    Future<TvDiscoveryIssue?> issueFor(Object error) async {
      final querier = FakeMdnsQuerier()..startError = error;
      final scan = await MdnsServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
        querierFactory: () => querier,
      ).discover();
      return scan.issue;
    }

    test('errno 65 (iOS refusing multicast) -> multicastRestricted', () async {
      expect(
        await issueFor(const OSError('No route to host', 65)),
        TvDiscoveryIssue.multicastRestricted,
      );
    });

    test('ENETUNREACH -> networkUnavailable', () async {
      expect(
        await issueFor(
          const SocketException('x', osError: OSError('unreachable', 51)),
        ),
        TvDiscoveryIssue.networkUnavailable,
      );
    });

    test('EADDRINUSE -> failed', () async {
      expect(
        await issueFor(const OSError('Address already in use', 48)),
        TvDiscoveryIssue.failed,
      );
    });

    test('a healthy empty scan reports no issue', () async {
      final scan = await MdnsServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
        querierFactory: FakeMdnsQuerier.new,
      ).discover(timeout: const Duration(milliseconds: 200));
      expect(scan.issue, isNull);
    });
  });

  group('native Bonjour failures map to discovery issues', () {
    const channel = MethodChannel(NativeBonjourServiceDiscovery.channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('policy denied -> localNetworkDenied', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'services': <Object>[],
          'browsed': 0,
          'failure': 'permission_denied_or_restricted',
        },
      );

      final scan = await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover();

      expect(scan.issue, TvDiscoveryIssue.localNetworkDenied);
    });

    test('missing bridge -> failed', () async {
      final scan = await NativeBonjourServiceDiscovery(
        serviceType: AndroidTvConstants.mdnsServiceType,
        logTag: 'ANDROID_TV',
      ).discover();
      expect(scan.issue, TvDiscoveryIssue.failed);
    });
  });
}
