import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('WidgetTesterStepContext', () {
    testWidgets('executes interactions and assertions successfully',
        (tester) async {
      int tapCount = 0;
      int longPressCount = 0;
      final controller = TextEditingController(text: 'initial text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ElevatedButton(
                    key: const Key('tap_btn'),
                    onPressed: () => tapCount++,
                    onLongPress: () => longPressCount++,
                    child: const Text('Button Text'),
                  ),
                  TextField(
                    key: const Key('text_input'),
                    controller: controller,
                  ),
                  const SizedBox(height: 100),
                  const Text('Footer Content', key: Key('footer_text')),
                ],
              ),
            ),
          ),
        ),
      );

      final context = WidgetTesterStepContext(
        tester: tester,
        testId: 'test_123',
      );

      expect(context.testId, 'test_123');

      // exists
      expect(
          await context.exists(StepFinder.byKey(const Key('tap_btn'))), isTrue);
      expect(await context.exists(StepFinder.byKey(const Key('missing_key'))),
          isFalse);

      // isVisible
      expect(await context.isVisible(StepFinder.byKey(const Key('tap_btn'))),
          isTrue);

      // getText
      expect(await context.getText(StepFinder.byKey(const Key('tap_btn'))),
          'Button Text');
      expect(await context.getText(StepFinder.byKey(const Key('text_input'))),
          'initial text');

      // getWidget
      final btn = await context
          .getWidget<ElevatedButton>(StepFinder.byWidgetType(ElevatedButton));
      expect(btn, isNotNull);

      // tap
      await context.tap(StepFinder.byKey(const Key('tap_btn')));
      expect(tapCount, 1);

      // longPress
      await context.longPress(StepFinder.byKey(const Key('tap_btn')));
      expect(longPressCount, 1);

      // enterText
      await context.enterText(
          StepFinder.byKey(const Key('text_input')), 'new input');
      expect(controller.text, 'new input');

      // clearText
      await context.clearText(StepFinder.byKey(const Key('text_input')));
      expect(controller.text, '');

      // drag & scroll
      await context.scroll(StepFinder.byWidgetType(SingleChildScrollView),
          offset: const Offset(0, -50));
      await context.drag(StepFinder.byWidgetType(SingleChildScrollView),
          offset: const Offset(0, 50));

      // waitFor & waitForAbsence
      await context.waitFor(StepFinder.byKey(const Key('footer_text')));
      await context
          .waitForAbsence(StepFinder.byKey(const Key('non_existent_key')));

      // logging & assertions
      context.log('Step executed successfully');
      expect(context.logs.length, greaterThanOrEqualTo(1));

      final assertion = AssertionResult.success(
        description: 'Verified button presence',
      );
      context.recordAssertion(assertion);
      expect(context.assertions.length, 1);
    });

    testWidgets('throws StateError when interacting with absent widget',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Empty')),
        ),
      );

      final context = WidgetTesterStepContext(
        tester: tester,
        testId: 'error_test',
      );

      final missing = StepFinder.byKey(const Key('ghost'));

      await expectLater(
        () => context.tap(missing),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => context.enterText(missing, 'fail'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => context.clearText(missing),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => context.longPress(missing),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => context.drag(missing, offset: const Offset(10, 10)),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('throws TimeoutException when waitFor exceeds timeout',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Static Screen')),
        ),
      );

      final context = WidgetTesterStepContext(
        tester: tester,
        testId: 'timeout_test',
      );

      await expectLater(
        () => context.waitFor(
          StepFinder.byKey(const Key('never_appears')),
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
