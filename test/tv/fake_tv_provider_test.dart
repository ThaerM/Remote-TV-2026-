import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/fake/fake_tv_provider.dart';

void main() {
  group('FakeTvProvider', () {
    late FakeTvProvider provider;

    setUp(() {
      provider = FakeTvProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('discover returns the demo device catalog', () async {
      final devices = await provider.discover();

      expect(devices, hasLength(3));
      expect(devices.every((d) => d.isDevelopmentFake), isTrue);
    });

    test('connect requests PIN pairing', () async {
      final devices = await provider.discover();
      final request = await provider.connect(devices.first);

      expect(request, isA<TvPinPairingRequest>());
      expect(provider.currentState, TvConnectionState.pairingRequired);
    });

    test('submitPairingCode with correct code connects', () async {
      final devices = await provider.discover();
      await provider.connect(devices.first);

      await provider.submitPairingCode('1234');

      expect(provider.currentState, TvConnectionState.connected);
    });

    test(
      'submitPairingCode with wrong code throws and stays unpaired',
      () async {
        final devices = await provider.discover();
        await provider.connect(devices.first);

        await expectLater(
          provider.submitPairingCode('0000'),
          throwsA(isA<TvConnectionException>()),
        );
        expect(provider.currentState, isNot(TvConnectionState.connected));
      },
    );

    test('sendCommand throws when not connected', () async {
      await expectLater(
        provider.sendCommand(const TvCommand.key(TvCommandKey.power)),
        throwsA(isA<TvNotConnectedException>()),
      );
    });

    test(
      'sendCommand throws for a capability the device does not have',
      () async {
        final devices = await provider.discover();
        // Bedroom Samsung TV has no voice support in the default catalog.
        final samsung = devices.firstWhere((d) => d.name.contains('Samsung'));
        await provider.connect(samsung);
        await provider.submitPairingCode('2580');

        await expectLater(
          provider.sendCommand(const TvCommand.key(TvCommandKey.voiceStart)),
          throwsA(isA<UnsupportedTvCommandException>()),
        );
      },
    );

    test('sendCommand succeeds for a supported capability', () async {
      final devices = await provider.discover();
      final device = devices.firstWhere((d) => d.name.contains('Google'));
      await provider.connect(device);
      await provider.submitPairingCode('1234');

      await expectLater(
        provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp)),
        completes,
      );
    });

    test('disconnect resets state', () async {
      final devices = await provider.discover();
      await provider.connect(devices.first);
      await provider.submitPairingCode('1234');

      await provider.disconnect();

      expect(provider.currentState, TvConnectionState.disconnected);
      expect(await provider.getCapabilities(), TvCapabilities.none);
    });
  });
}
