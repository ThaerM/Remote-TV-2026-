import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/casting/presentation/cast_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../../tv/stub_tv_provider.dart';

/// A connectable provider whose device reports [capabilities], and which
/// records casts when it's a [TvMediaCaster].
class _Provider extends StubTvProvider implements TvMediaCaster {
  _Provider(TvCapabilities capabilities, {this.castError})
    : super(platform: TvPlatform.googleCast, capabilities: capabilities);

  final TvException? castError;
  final _states = StreamController<TvConnectionState>.broadcast();
  final _media = StreamController<TvMediaStatus?>.broadcast();
  final casts = <TvMediaItem>[];

  @override
  Stream<TvConnectionState> get connectionState => _states.stream;

  @override
  Future<TvPairingRequest> connect(TvDevice device) async {
    _states.add(TvConnectionState.connected);
    return TvPairingRequest.none;
  }

  @override
  Stream<TvMediaStatus?> get mediaStatus => _media.stream;

  @override
  Future<void> castMedia(TvMediaItem item) async {
    if (castError != null) throw castError!;
    casts.add(item);
    _media.add(
      TvMediaStatus(
        playerState: TvPlayerState.playing,
        title: item.title,
        duration: const Duration(minutes: 10),
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stopMedia() async => _media.add(null);

  @override
  Future<void> togglePlayback() async {}
}

const _device = TvDevice(
  id: 'cast:abc',
  name: 'Living Room TV',
  platform: TvPlatform.googleCast,
  host: '192.168.1.50',
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Provider? provider,
) async {
  final container = ProviderContainer(
    overrides: [
      tvProviderRegistryProvider.overrideWithValue(
        TvProviderRegistry([?provider]),
      ),
    ],
  );
  addTearDown(container.dispose);
  if (provider != null) {
    await container.read(tvSessionControllerProvider.notifier).connect(_device);
    await tester.pump();
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CastScreen()),
    ),
  );
  await tester.pump();
  return container;
}

class _FakeSessionController extends TvSessionController {
  _FakeSessionController(super.ref, TvSessionState initial) {
    state = initial;
  }

  int connectCalls = 0;

  @override
  Future<void> connect(TvDevice device) async {
    connectCalls++;
  }
}

const _droppedDevice = TvDevice(
  id: 'cast:dropped',
  name: 'Family room TV',
  platform: TvPlatform.googleCast,
);

void main() {
  testWidgets(
    'a device that dropped offers Retry and Find another device, never '
    'an indefinite spinner',
    (tester) async {
      late _FakeSessionController session;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tvSessionControllerProvider.overrideWith((ref) {
              session = _FakeSessionController(
                ref,
                const TvSessionState(
                  selectedDevice: _droppedDevice,
                  connectionState: TvConnectionState.disconnected,
                ),
              );
              return session;
            }),
          ],
          child: const MaterialApp(home: CastScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Connection lost'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      expect(find.text('Find another device'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pump();

      expect(session.connectCalls, 1);
    },
  );

  testWidgets(
    'a device reconnecting shows a non-blocking status, no Retry button '
    '(the session already retries on its own)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tvSessionControllerProvider.overrideWith(
              (ref) => _FakeSessionController(
                ref,
                const TvSessionState(
                  selectedDevice: _droppedDevice,
                  connectionState: TvConnectionState.reconnecting,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CastScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Family room TV'), findsOneWidget);
      expect(find.textContaining('Reconnecting'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
    },
  );

  testWidgets('not connected: explains where Cast devices come from', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.text('No cast device connected'), findsOneWidget);
    expect(find.text('Connect TV'), findsOneWidget);
  });

  testWidgets('a device without casting says so instead of a dead form', (
    tester,
  ) async {
    await _pump(tester, _Provider(const TvCapabilities(dpad: true)));

    expect(
      find.textContaining("isn't available for this connection"),
      findsOneWidget,
    );
    expect(find.text('Cast'), findsOneWidget, reason: 'only the app bar');
  });

  testWidgets('casting a link shows it as now playing', (tester) async {
    final provider = _Provider(const TvCapabilities(casting: true));
    await _pump(tester, provider);

    await tester.enterText(
      find.widgetWithText(TextField, 'Media link'),
      'https://example.com/bbb.mp4',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Title (optional)'),
      'Big Buck Bunny',
    );
    await tester.pump();
    expect(find.text('Detected: Video (MP4)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Cast'));
    await tester.pump();
    await tester.pump();

    expect(provider.casts.single.contentType, 'video/mp4');
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.text('Big Buck Bunny'), findsWidgets);
  });

  testWidgets('an unknown link type asks for the media type', (tester) async {
    final provider = _Provider(const TvCapabilities(casting: true));
    await _pump(tester, provider);

    await tester.enterText(
      find.widgetWithText(TextField, 'Media link'),
      'https://example.com/watch?v=1',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Cast'));
    await tester.pump();

    expect(find.text('Media type'), findsOneWidget);
    expect(
      find.text('Choose what kind of media this link is.'),
      findsOneWidget,
    );
    expect(provider.casts, isEmpty);
  });

  testWidgets('shows a compact device header when connected and casting', (
    tester,
  ) async {
    await _pump(tester, _Provider(const TvCapabilities(casting: true)));

    expect(find.text('Living Room TV'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('volume/mute controls only render when the device reports them', (
    tester,
  ) async {
    final provider = _Provider(
      const TvCapabilities(casting: true, volume: true, mute: true),
    );
    await _pump(tester, provider);
    await tester.enterText(
      find.widgetWithText(TextField, 'Media link'),
      'https://example.com/bbb.mp4',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cast'));
    await tester.pump();
    await tester.pump();

    expect(find.bySemanticsLabel('Volume Up'), findsOneWidget);
    expect(find.bySemanticsLabel('Volume Down'), findsOneWidget);
    expect(find.bySemanticsLabel('Mute'), findsOneWidget);
  });

  testWidgets('no volume/mute row at all when the device reports neither', (
    tester,
  ) async {
    final provider = _Provider(const TvCapabilities(casting: true));
    await _pump(tester, provider);
    await tester.enterText(
      find.widgetWithText(TextField, 'Media link'),
      'https://example.com/bbb.mp4',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cast'));
    await tester.pump();
    await tester.pump();

    expect(find.bySemanticsLabel('Volume Up'), findsNothing);
    expect(find.bySemanticsLabel('Mute'), findsNothing);
  });

  testWidgets('a device error is shown inline', (tester) async {
    await _pump(
      tester,
      _Provider(
        const TvCapabilities(casting: true),
        castError: const TvMediaSessionException(
          'The Cast device could not play this media.',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Media link'),
      'https://example.com/a.mp4',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cast'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('The Cast device could not play this media.'),
      findsOneWidget,
    );
  });
}
