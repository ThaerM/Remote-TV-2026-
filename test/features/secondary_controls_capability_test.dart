import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/remote/presentation/widgets/secondary_controls_sheet.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

Widget _sheet(TvCapabilities caps, List<TvCommand> sent) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: SecondaryControlsSheet(capabilities: caps, onCommand: sent.add),
    ),
  ),
);

void main() {
  testWidgets(
    'media controls no longer live in the sheet - they moved to the main '
    'Remote screen',
    (tester) async {
      await tester.pumpWidget(
        _sheet(const TvCapabilities(mediaControls: true), []),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('Media'), findsNothing);
    },
  );

  testWidgets('the sheet has a "More Controls" title and a close button', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(const TvCapabilities(), []));

    expect(find.text('More Controls'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('keyboard, voice and guide live in the sheet as bottom actions', (
    tester,
  ) async {
    final sent = <TvCommand>[];
    var keyboardOpened = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SecondaryControlsSheet(
              capabilities: const TvCapabilities(
                dpad: true,
                keyboard: true,
                voice: true,
              ),
              onCommand: sent.add,
              onOpenKeyboard: () => keyboardOpened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
    await tester.pump();
    expect(keyboardOpened, isTrue);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(sent.single.key, TvCommandKey.voiceStart);
  });

  testWidgets('Guide is hidden without dpad, or when the device lacks it', (
    tester,
  ) async {
    final sent = <TvCommand>[];
    await tester.pumpWidget(_sheet(const TvCapabilities(keyboard: true), sent));
    expect(find.text('Guide'), findsNothing);

    await tester.pumpWidget(
      _sheet(
        const TvCapabilities(
          dpad: true,
          keyboard: true,
          unsupportedKeys: {TvCommandKey.guide},
        ),
        sent,
      ),
    );
    expect(find.text('Guide'), findsNothing);
  });

  testWidgets('numeric keypad and color keys are unaffected by the media '
      'controls move', (tester) async {
    final sent = <TvCommand>[];
    await tester.pumpWidget(
      _sheet(const TvCapabilities(numericKeypad: true, colorKeys: true), sent),
    );

    expect(find.text('Number pad'), findsOneWidget);
    expect(find.text('Color keys'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent.single.key, TvCommandKey.digit5);
  });
}
