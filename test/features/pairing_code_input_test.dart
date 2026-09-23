import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/pairing/presentation/widgets/pairing_code_input.dart';

void main() {
  group('PairingCodeInput', () {
    testWidgets('calls onSubmitted once all digits are entered', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PairingCodeInput(
              length: 6,
              controller: controller,
              onSubmitted: (code) => submitted = code,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(submitted, '123456');
    });

    testWidgets('renders one digit box per expected code length', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PairingCodeInput(
              length: 6,
              controller: controller,
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(6));
    });

    testWidgets('shake() does not throw and completes without error', (
      tester,
    ) async {
      final controller = TextEditingController();
      final key = GlobalKey<PairingCodeInputState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PairingCodeInput(
              key: key,
              length: 6,
              controller: controller,
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      key.currentState?.shake();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });
}
