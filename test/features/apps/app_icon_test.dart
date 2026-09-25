import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/apps/presentation/apps_screen.dart';
import 'package:remote_tv_2026/features/apps/presentation/widgets/app_icon.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }
}

const _netflix = TvApplication(
  id: 'netflix',
  name: 'Netflix',
  iconKey: 'netflix',
);
const _mystery = TvApplication(id: 'com.example.mystery', name: 'Mystery App');

Widget _wrapApps(TvSessionState state) {
  return ProviderScope(
    overrides: [
      tvSessionControllerProvider.overrideWith(
        (ref) => _FakeSessionController(ref, state),
      ),
    ],
    child: const MaterialApp(home: AppsScreen()),
  );
}

/// Simulates a real asset that fails to load (a corrupt file, a
/// packaging error) - `Image.asset`'s `errorBuilder` must still render
/// something instead of crashing the tree.
class _AlwaysThrowingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw Exception('asset load failed');

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => throw Exception('asset load failed');
}

void main() {
  group('AppIcon', () {
    testWidgets('7. shows the bundled artwork image for a known app', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIcon(app: _netflix)),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.smart_display_outlined), findsNothing);
    });

    testWidgets('8. shows the generic fallback icon for an unknown app', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIcon(app: _mystery)),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.smart_display_outlined), findsOneWidget);
    });

    testWidgets(
      '10. a known app whose asset fails to load falls back gracefully, '
      'never crashing the UI',
      (tester) async {
        await tester.pumpWidget(
          DefaultAssetBundle(
            bundle: _AlwaysThrowingBundle(),
            child: const MaterialApp(
              home: Scaffold(body: AppIcon(app: _netflix)),
            ),
          ),
        );
        await tester.pump();
        // Image resolution/error reporting completes on a later frame.
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.smart_display_outlined), findsOneWidget);
      },
    );
  });

  group('AppsScreen uses AppArtworkResolver via AppIcon', () {
    testWidgets('9. renders known artwork and an unknown-app fallback side '
        'by side', (tester) async {
      await tester.pumpWidget(
        _wrapApps(
          const TvSessionState(
            selectedDevice: TvDevice(
              id: 'd1',
              name: 'Test TV',
              platform: TvPlatform.fake,
            ),
            connectionState: TvConnectionState.connected,
            capabilities: TvCapabilities(launchApps: true),
            applications: [_netflix, _mystery],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppIcon), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.smart_display_outlined), findsOneWidget);
    });
  });

  group('RemoteScreen Quick Apps uses the same AppIcon/resolver', () {
    testWidgets('renders known artwork in the Quick Apps row', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tvSessionControllerProvider.overrideWith(
              (ref) => _FakeSessionController(
                ref,
                const TvSessionState(
                  selectedDevice: TvDevice(
                    id: 'd1',
                    name: 'Test TV',
                    platform: TvPlatform.fake,
                  ),
                  connectionState: TvConnectionState.connected,
                  capabilities: TvCapabilities(launchApps: true),
                  applications: [_netflix, _mystery],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: RemoteScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(AppIcon), findsNWidgets(2));
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
