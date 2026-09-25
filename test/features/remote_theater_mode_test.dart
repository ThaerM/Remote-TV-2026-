import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/features/settings/application/settings_controller.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }

  final sentCommands = <TvCommand>[];

  @override
  Future<void> sendCommand(TvCommand command) async {
    sentCommands.add(command);
  }
}

class _FakeSettingsController extends SettingsController {
  _FakeSettingsController(SettingsState initial) {
    state = initial;
  }
}

final _connectedWithDpad = TvSessionState(
  selectedDevice: const TvDevice(
    id: 'd1',
    name: 'Test TV',
    platform: TvPlatform.fake,
  ),
  connectionState: TvConnectionState.connected,
  capabilities: const TvCapabilities(dpad: true),
);

void main() {
  group('Theater Mode', () {
    late _FakeSessionController session;

    Widget wrap({required bool theaterModeEnabled}) {
      return ProviderScope(
        overrides: [
          tvSessionControllerProvider.overrideWith((ref) {
            session = _FakeSessionController(ref, _connectedWithDpad);
            return session;
          }),
          settingsControllerProvider.overrideWith(
            (ref) => _FakeSettingsController(
              SettingsState(theaterModeEnabled: theaterModeEnabled),
            ),
          ),
        ],
        child: const MaterialApp(home: RemoteScreen()),
      );
    }

    testWidgets('forces a pure black Scaffold background when enabled', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(theaterModeEnabled: true));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('leaves the background alone when disabled', (tester) async {
      await tester.pumpWidget(wrap(theaterModeEnabled: false));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('the D-pad still dispatches commands with Theater Mode on', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(wrap(theaterModeEnabled: true));
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Select'));
      await tester.pump();

      expect(session.sentCommands, hasLength(1));
      expect(session.sentCommands.single.key, TvCommandKey.select);

      semantics.dispose();
    });

    testWidgets(
      'the header subtitle shows "Theater Mode" instead of the platform '
      'name when enabled',
      (tester) async {
        await tester.pumpWidget(wrap(theaterModeEnabled: true));
        await tester.pump();

        expect(find.textContaining('Theater Mode'), findsOneWidget);
        expect(find.textContaining('· Demo'), findsNothing);
      },
    );

    testWidgets(
      'the header subtitle shows the platform name when Theater Mode is off',
      (tester) async {
        await tester.pumpWidget(wrap(theaterModeEnabled: false));
        await tester.pump();

        expect(find.textContaining('Theater Mode'), findsNothing);
      },
    );
  });
}
