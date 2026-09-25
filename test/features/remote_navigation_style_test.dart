import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/design/app_spacing.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/widgets/dpad_control.dart';
import 'package:remote_tv_2026/features/remote/presentation/widgets/touchpad_surface.dart';
import 'package:remote_tv_2026/features/settings/application/settings_controller.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
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

Widget _wrap({required RemoteNavigationStyle style}) {
  return ProviderScope(
    overrides: [
      tvSessionControllerProvider.overrideWith(
        (ref) => _FakeSessionController(ref, _connectedWithDpad),
      ),
      settingsControllerProvider.overrideWith(
        (ref) => _FakeSettingsController(SettingsState(navigationStyle: style)),
      ),
    ],
    child: const MaterialApp(home: RemoteScreen()),
  );
}

void main() {
  group('Remote navigation style (D-pad vs touchpad)', () {
    testWidgets('shows DpadControl when the preference is dpad', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(style: RemoteNavigationStyle.dpad));
      await tester.pump();

      expect(find.byType(DpadControl), findsOneWidget);
      expect(find.byType(TouchpadSurface), findsNothing);
    });

    testWidgets('shows TouchpadSurface when the preference is touchpad', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(style: RemoteNavigationStyle.touchpad));
      await tester.pump();

      expect(find.byType(TouchpadSurface), findsOneWidget);
      expect(find.byType(DpadControl), findsNothing);
    });

    testWidgets('tapping the switch button flips the preference', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(style: RemoteNavigationStyle.dpad));
      await tester.pump();

      expect(find.byType(DpadControl), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Switch to Touchpad'));
      // Not pumpAndSettle: ConnectionStatusIndicator's connection-state
      // pulse repeats indefinitely by design, so it would never settle.
      await tester.pump();
      await tester.pump(AppMotion.panel);

      expect(find.byType(TouchpadSurface), findsOneWidget);

      semantics.dispose();
    });
  });
}
