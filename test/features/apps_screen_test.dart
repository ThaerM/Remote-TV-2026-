import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/apps/presentation/apps_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }
}

Widget _wrap(TvSessionState state) {
  return ProviderScope(
    overrides: [
      tvSessionControllerProvider.overrideWith(
        (ref) => _FakeSessionController(ref, state),
      ),
    ],
    child: const MaterialApp(home: AppsScreen()),
  );
}

void main() {
  group('AppsScreen capability-driven visibility', () {
    testWidgets('shows a connect prompt when not connected', (tester) async {
      await tester.pumpWidget(_wrap(const TvSessionState()));

      expect(find.text('Connect to a TV to see its apps.'), findsOneWidget);
    });

    testWidgets(
      'shows an honest message when launchApps is false, never a fake app',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TvSessionState(
              selectedDevice: const TvDevice(
                id: 'd1',
                name: 'Test TV',
                platform: TvPlatform.fake,
              ),
              connectionState: TvConnectionState.connected,
              capabilities: const TvCapabilities(launchApps: false),
              applications: const [
                TvApplication(id: 'netflix', name: 'Netflix'),
              ],
            ),
          ),
        );

        expect(
          find.text('This TV does not support launching apps.'),
          findsOneWidget,
        );
        expect(find.text('Netflix'), findsNothing);
      },
    );

    testWidgets('renders only the apps the provider actually reported', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TvSessionState(
            selectedDevice: const TvDevice(
              id: 'd1',
              name: 'Test TV',
              platform: TvPlatform.fake,
            ),
            connectionState: TvConnectionState.connected,
            capabilities: const TvCapabilities(launchApps: true),
            applications: const [
              TvApplication(id: 'netflix', name: 'Netflix'),
              TvApplication(id: 'youtube', name: 'YouTube'),
            ],
          ),
        ),
      );

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Disney+'), findsNothing);
    });
  });
}
