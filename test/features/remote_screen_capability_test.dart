import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }
}

TvSessionState _connectedState({required TvCapabilities capabilities}) {
  return TvSessionState(
    selectedDevice: const TvDevice(
      id: 'test-device',
      name: 'Test TV',
      platform: TvPlatform.fake,
      isDevelopmentFake: true,
    ),
    connectionState: TvConnectionState.connected,
    capabilities: capabilities,
  );
}

Widget _wrap(TvSessionState state) {
  return ProviderScope(
    overrides: [
      tvSessionControllerProvider.overrideWith(
        (ref) => _FakeSessionController(ref, state),
      ),
    ],
    child: const MaterialApp(home: RemoteScreen()),
  );
}

void main() {
  group('RemoteScreen capability-driven UI', () {
    testWidgets('shows "no TV connected" when disconnected', (tester) async {
      await tester.pumpWidget(_wrap(const TvSessionState()));

      expect(find.text('No TV connected'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('hides volume/mute/keyboard/voice when unsupported', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_connectedState(capabilities: const TvCapabilities(dpad: true))),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Volume'), findsNothing);
      expect(find.text('Keyboard'), findsNothing);
      expect(find.text('Voice'), findsNothing);
    });

    testWidgets('shows volume, keyboard and voice when supported', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _connectedState(
            capabilities: const TvCapabilities(
              dpad: true,
              volume: true,
              mute: true,
              keyboard: true,
              voice: true,
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
    });
  });
}
