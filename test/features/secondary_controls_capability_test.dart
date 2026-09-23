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
  testWidgets('media keys a device lacks are hidden, the rest still work', (
    tester,
  ) async {
    final sent = <TvCommand>[];
    await tester.pumpWidget(
      _sheet(
        const TvCapabilities(
          mediaControls: true,
          unsupportedKeys: {TvCommandKey.mediaPrevious, TvCommandKey.mediaNext},
        ),
        sent,
      ),
    );

    expect(find.text('Prev'), findsNothing);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Rewind'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent.single.key, TvCommandKey.mediaPlay);
  });

  testWidgets('full media support shows all five buttons', (tester) async {
    await tester.pumpWidget(
      _sheet(const TvCapabilities(mediaControls: true), []),
    );

    for (final label in ['Prev', 'Rewind', 'Play', 'Forward', 'Next']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
