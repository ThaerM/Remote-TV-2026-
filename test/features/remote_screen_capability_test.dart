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
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('hides volume/mute/channel/media when unsupported', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(_connectedState(capabilities: const TvCapabilities(dpad: true))),
      );

      expect(find.text('HOME'), findsOneWidget);
      expect(find.bySemanticsLabel('Volume Up'), findsNothing);
      expect(find.bySemanticsLabel('Mute'), findsNothing);
      expect(find.bySemanticsLabel('Channel Up'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      // "More Controls" only appears when something actually lives in it.
      expect(find.text('More Controls'), findsNothing);

      semantics.dispose();
    });

    testWidgets(
      'shows volume/mute/channel directly on the main screen - not behind '
      'More controls',
      (tester) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          _wrap(
            _connectedState(
              capabilities: const TvCapabilities(
                dpad: true,
                volume: true,
                mute: true,
                channel: true,
              ),
            ),
          ),
        );

        // Compact icon-only controls - accessible via semantics, not a
        // visible "Volume"/"Channel" label taking up vertical space.
        expect(find.bySemanticsLabel('Volume Up'), findsOneWidget);
        expect(find.bySemanticsLabel('Volume Down'), findsOneWidget);
        expect(find.bySemanticsLabel('Mute'), findsOneWidget);
        expect(find.bySemanticsLabel('Channel Up'), findsOneWidget);
        expect(find.bySemanticsLabel('Channel Down'), findsOneWidget);

        semantics.dispose();
      },
    );

    testWidgets(
      'shows media transport directly on the main screen when supported',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _connectedState(
              capabilities: const TvCapabilities(
                dpad: true,
                mediaControls: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byIcon(Icons.fast_rewind_rounded), findsOneWidget);
        expect(find.byIcon(Icons.fast_forward_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'keyboard and voice move into More controls, not the main row',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _connectedState(
              capabilities: const TvCapabilities(
                dpad: true,
                keyboard: true,
                voice: true,
              ),
            ),
          ),
        );

        expect(find.text('Keyboard'), findsNothing);
        expect(find.text('Voice'), findsNothing);
        expect(find.text('More Controls'), findsOneWidget);

        await tester.tap(find.text('More Controls'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Keyboard'), findsOneWidget);
        expect(find.text('Voice'), findsOneWidget);
      },
    );

    testWidgets('the D-pad and Home/Back/Menu row fit in one compact panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _connectedState(
            capabilities: const TvCapabilities(
              dpad: true,
              volume: true,
              mute: true,
              channel: true,
              mediaControls: true,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
    });
  });
}
