import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/remote/presentation/widgets/connection_status_indicator.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

Widget _wrap(TvConnectionState state) {
  return MaterialApp(
    home: Scaffold(body: ConnectionStatusIndicator(state: state)),
  );
}

void main() {
  group('ConnectionStatusIndicator', () {
    testWidgets('shows "Connected" for the connected state', (tester) async {
      await tester.pumpWidget(_wrap(TvConnectionState.connected));
      await tester.pump();

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('shows "Reconnecting…" for the reconnecting state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(TvConnectionState.reconnecting));
      await tester.pump();

      expect(find.text('Reconnecting…'), findsOneWidget);
    });

    testWidgets('shows "Offline" for the disconnected state', (tester) async {
      await tester.pumpWidget(_wrap(TvConnectionState.disconnected));
      await tester.pump();

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('compact mode omits the text label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              state: TvConnectionState.connected,
              compact: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Connected'), findsNothing);
    });
  });
}
