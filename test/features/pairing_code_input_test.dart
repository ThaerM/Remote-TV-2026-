import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/pairing/presentation/widgets/pairing_code_input.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';

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

    Future<List<String>> pumpHex(
      WidgetTester tester,
      TextEditingController controller,
    ) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PairingCodeInput(
              length: 6,
              alphabet: TvPinAlphabet.hex,
              controller: controller,
              onSubmitted: submitted.add,
            ),
          ),
        ),
      );
      return submitted;
    }

    testWidgets('A4F29C is accepted and submitted', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'A4F29C');
      await tester.pump();

      expect(submitted, ['A4F29C']);
    });

    testWidgets('a4f29c is shown and submitted as A4F29C', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'a4f29c');
      await tester.pump();

      expect(controller.text, 'A4F29C');
      expect(submitted, ['A4F29C']);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('123456 is accepted', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(submitted, ['123456']);
    });

    testWidgets('G12345 is rejected and nothing is submitted', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'G12345');
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(submitted, isEmpty);
    });

    testWidgets('special characters are rejected', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'A4');
      await tester.enterText(find.byType(TextField), 'A4-');
      await tester.enterText(find.byType(TextField), 'A4!F29');
      await tester.pump();

      expect(controller.text, 'A4');
      expect(submitted, isEmpty);
    });

    testWidgets('fewer than 6 characters are not submitted', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'A4F29');
      await tester.pump();

      expect(controller.text, 'A4F29');
      expect(submitted, isEmpty);
    });

    testWidgets('more than 6 characters are rejected, not trimmed', (
      tester,
    ) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), 'A4F29C1');
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(submitted, isEmpty);
    });

    testWidgets('a pasted code with spaces is accepted', (tester) async {
      final controller = TextEditingController();
      final submitted = await pumpHex(tester, controller);

      await tester.enterText(find.byType(TextField), ' a4f 29c ');
      await tester.pump();

      expect(submitted, ['A4F29C']);
    });

    group('Paste code button', () {
      String? clipboard;

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.getData') {
                return clipboard == null
                    ? null
                    : <String, dynamic>{'text': clipboard};
              }
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      testWidgets('a pasted 6-character code is accepted', (tester) async {
        clipboard = 'a4f29c';
        final controller = TextEditingController();
        final submitted = await pumpHex(tester, controller);

        await tester.tap(find.text('Paste code'));
        await tester.pump();

        expect(controller.text, 'A4F29C');
        expect(submitted, ['A4F29C']);
      });

      testWidgets('an invalid pasted code is refused with a message', (
        tester,
      ) async {
        clipboard = 'G12345';
        final controller = TextEditingController();
        final submitted = await pumpHex(tester, controller);

        await tester.tap(find.text('Paste code'));
        await tester.pump();

        expect(controller.text, isEmpty);
        expect(submitted, isEmpty);
        expect(
          find.text("The copied text isn't a 6-character pairing code."),
          findsOneWidget,
        );
      });
    });

    testWidgets('screen readers hear "Pairing code", not "PIN"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHex(tester, TextEditingController());

      expect(find.bySemanticsLabel(RegExp('Pairing code')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('PIN')), findsNothing);
      handle.dispose();
    });

    testWidgets('hex codes use a letters keyboard, not a number pad', (
      tester,
    ) async {
      await pumpHex(tester, TextEditingController());

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, isNot(TextInputType.number));
      expect(field.keyboardType, TextInputType.visiblePassword);
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
