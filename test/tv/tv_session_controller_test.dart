import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import 'stub_tv_provider.dart';

/// Multi-provider behavior of [TvSessionController]: the glue between
/// discovery, switching devices, and capability-driven UI state.
void main() {
  const googleTvRemote = TvDevice(
    id: 'android_tv:family-room',
    name: 'Family room TV',
    platform: TvPlatform.androidTv,
    host: '192.168.1.42',
  );
  const googleTvCast = TvDevice(
    id: 'cast:abc123',
    name: 'Family room TV',
    platform: TvPlatform.googleCast,
    host: '192.168.1.42',
  );
  const roku = TvDevice(
    id: 'roku:X1',
    name: 'Bedroom Roku',
    platform: TvPlatform.roku,
    host: '192.168.1.50',
  );

  late StubTvProvider androidTv;
  late StubTvProvider cast;
  late StubTvProvider rokuProvider;
  late ProviderContainer container;

  setUp(() {
    androidTv = StubTvProvider(
      platform: TvPlatform.androidTv,
      outcome: const TvDiscoveryOutcome(devices: [googleTvRemote]),
      capabilities: const TvCapabilities(dpad: true, keyboard: true),
    );
    cast = StubTvProvider(
      platform: TvPlatform.googleCast,
      outcome: const TvDiscoveryOutcome(devices: [googleTvCast]),
      capabilities: const TvCapabilities(casting: true, mediaControls: true),
    );
    rokuProvider = StubTvProvider(
      platform: TvPlatform.roku,
      capabilities: const TvCapabilities(dpad: true, launchApps: true),
    );
    container = ProviderContainer(
      overrides: [
        tvProviderRegistryProvider.overrideWithValue(
          TvProviderRegistry([androidTv, cast, rokuProvider]),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  TvSessionController controller() =>
      container.read(tvSessionControllerProvider.notifier);
  TvSessionState state() => container.read(tvSessionControllerProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a Google TV found as a remote and as a Cast target stays two '
      'distinct, labelled entries', () async {
    await controller().discover();

    expect(state().discoveredDevices.map((d) => d.platform), [
      TvPlatform.androidTv,
      TvPlatform.googleCast,
    ]);
    expect(state().discoveredDevices.map((d) => d.id).toSet(), hasLength(2));
  });

  test('switching to a device on another provider disconnects the '
      'previous one and replaces its capabilities', () async {
    await controller().connect(googleTvRemote);
    await settle();
    expect(state().capabilities.dpad, isTrue);
    expect(state().capabilities.casting, isFalse);

    await controller().connect(googleTvCast);
    await settle();

    expect(androidTv.disconnectCalls, 1);
    expect(state().selectedDevice, googleTvCast);
    expect(state().capabilities.casting, isTrue);
    expect(state().capabilities.dpad, isFalse);
  });

  test('capabilities are cleared while the new device is connecting', () async {
    await controller().connect(googleTvRemote);
    await settle();
    rokuProvider.connectError = const DeviceNotReachableException('off');

    await controller().connect(roku);

    expect(state().capabilities, TvCapabilities.none);
    expect(state().lastError, 'Could not connect to Bedroom Roku.');
  });

  test(
    'a TV added by IP is not listed twice once discovery finds it',
    () async {
      androidTv.probeResult = const TvDevice(
        id: 'android_tv:192.168.1.42',
        name: 'Android TV (192.168.1.42)',
        platform: TvPlatform.androidTv,
        host: '192.168.1.42',
      );
      await controller().addDeviceByAddress('192.168.1.42');
      expect(state().discoveredDevices, hasLength(1));

      await controller().discover();

      final remotes = state().discoveredDevices
          .where((d) => d.platform == TvPlatform.androidTv)
          .toList();
      expect(remotes, [googleTvRemote]);
    },
  );

  test('a TV added by IP that discovery cannot see is kept', () async {
    rokuProvider.probeResult = roku;
    await controller().addDeviceByAddress('192.168.1.50');

    await controller().discover();

    expect(state().discoveredDevices, contains(roku));
  });

  test('a non-TV error from a command is reported, not thrown', () async {
    await controller().connect(roku);
    await settle();
    rokuProvider.commandError = StateError('socket closed');

    await controller().sendCommand(const TvCommand.key(TvCommandKey.home));

    expect(state().lastError, isNotNull);
  });

  test('disconnect keeps the scan results', () async {
    await controller().discover();
    await controller().connect(googleTvRemote);
    await settle();

    await controller().disconnect();

    expect(state().isConnected, isFalse);
    expect(state().selectedDevice, isNull);
    expect(state().discoveredDevices, hasLength(2));
    expect(androidTv.disconnectCalls, 1);
  });

  test('leaving an unfinished pairing disconnects it', () async {
    androidTv.pairingRequest = const TvPinPairingRequest(expectedLength: 6);
    await controller().connect(googleTvRemote);
    expect(state().pairingRequest, isA<TvPinPairingRequest>());

    await controller().cancelPairing();

    expect(androidTv.disconnectCalls, 1);
    expect(state().selectedDevice, isNull);
  });

  test('cancelPairing after connecting is a no-op', () async {
    await controller().connect(roku);
    await settle();

    await controller().cancelPairing();

    expect(rokuProvider.disconnectCalls, 0);
    expect(state().isConnected, isTrue);
  });

  test('a second scan while one is running does not start another', () async {
    final first = controller().discover();
    final second = controller().discover();
    await Future.wait([first, second]);

    expect(state().discoveredDevices, hasLength(2));
    expect(state().isDiscovering, isFalse);
  });

  test('an invalid pairing code is rejected before reaching the TV', () async {
    androidTv.pairingRequest = const TvPinPairingRequest(
      expectedLength: 6,
      alphabet: TvPinAlphabet.hex,
    );
    await controller().connect(googleTvRemote);

    for (final bad in ['G12345', 'A4F29', 'A4F29C1', 'A4F-9C']) {
      await controller().submitPairingCode(bad);
      expect(
        state().lastError,
        'Enter the 6-character pairing code shown on your TV.',
        reason: bad,
      );
    }
    expect(androidTv.submittedCodes, isEmpty);

    await controller().submitPairingCode('a4f29c');
    expect(androidTv.submittedCodes, ['A4F29C']);
    expect(state().lastError, isNull);
  });
}
