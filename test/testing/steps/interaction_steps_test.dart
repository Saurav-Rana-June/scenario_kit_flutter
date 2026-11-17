import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

import 'fake_scenario_step_context.dart';

void main() {
  group('Interaction Steps', () {
    late FakeScenarioStepContext context;

    setUp(() {
      context = FakeScenarioStepContext();
    });

    test('TapStep executes tap and pumps', () async {
      final finder = StepFinder.byKeyString('submit_button');
      final step = TapStep(finder: finder);

      await step.execute(context);

      expect(context.calls, contains('tap:${finder.description}'));
      expect(context.calls, contains('pumpAndSettle'));
      expect(context.logs.first, contains('Executing tap'));
    });

    test('LongPressStep executes long press and pumps', () async {
      final finder = StepFinder.byText('Item 1');
      final step = LongPressStep(
        finder: finder,
        pressDuration: const Duration(milliseconds: 600),
      );

      await step.execute(context);

      expect(context.calls, contains('longPress:${finder.description}:600ms'));
      expect(context.calls, contains('pumpAndSettle'));
    });

    test('EnterTextStep inserts text and updates context', () async {
      final finder = StepFinder.byKeyString('email_field');
      final step = EnterTextStep(
        finder: finder,
        text: 'user@example.com',
      );

      await step.execute(context);

      expect(context.calls,
          contains('enterText:${finder.description}:user@example.com'));
      expect(context.calls, contains('pumpAndSettle'));
      expect(context.widgetTexts[finder.description], 'user@example.com');
    });

    test('ClearTextStep clears text in target widget', () async {
      final finder = StepFinder.byKeyString('email_field');
      context.widgetTexts[finder.description] = 'user@example.com';

      final step = ClearTextStep(finder: finder);
      await step.execute(context);

      expect(context.calls, contains('clearText:${finder.description}'));
      expect(context.calls, contains('pumpAndSettle'));
      expect(context.widgetTexts[finder.description], isNull);
    });

    test('ScrollStep executes scroll with specified offset', () async {
      final finder = StepFinder.byWidgetType(ListView);
      final step = ScrollStep(
        finder: finder,
        offset: const Offset(0, -300),
      );

      await step.execute(context);

      expect(
          context.calls, contains('scroll:${finder.description}:0.0,-300.0'));
      expect(context.calls, contains('pumpAndSettle'));
    });

    test('DragStep executes drag with specified offset', () async {
      final finder = StepFinder.byKeyString('slider');
      final step = DragStep(
        finder: finder,
        offset: const Offset(50, 0),
      );

      await step.execute(context);

      expect(context.calls, contains('drag:${finder.description}:50.0,0.0'));
      expect(context.calls, contains('pumpAndSettle'));
    });

    test('WaitStep pauses execution for given duration', () async {
      final step = WaitStep(duration: const Duration(milliseconds: 150));
      await step.execute(context);

      expect(context.calls, contains('wait:150ms'));
      expect(context.logs.first, contains('Waiting for 150ms'));
    });

    test('WaitForWidgetStep polls until widget exists', () async {
      final finder = StepFinder.byText('Welcome');
      context.existingFinders.add(finder.description);

      final step = WaitForWidgetStep(finder: finder);
      await step.execute(context);

      expect(context.calls, contains('waitFor:${finder.description}'));
    });

    test('CustomStep executes developer callback', () async {
      var executed = false;
      final step = CustomStep(
        id: 'custom_check',
        description: 'Verify custom state',
        action: (ctx) async {
          executed = true;
          ctx.log('Inside custom callback');
        },
      );

      await step.execute(context);

      expect(executed, isTrue);
      expect(context.logs, contains('Inside custom callback'));
    });

    test(
        'ScenarioTestStep factory constructors produce expected step instances',
        () {
      final finder = StepFinder.byText('Label');
      expect(ScenarioTestStep.tap(finder), isA<TapStep>());
      expect(ScenarioTestStep.longPress(finder), isA<LongPressStep>());
      expect(ScenarioTestStep.enterText(finder, 'abc'), isA<EnterTextStep>());
      expect(ScenarioTestStep.clearText(finder), isA<ClearTextStep>());
      expect(ScenarioTestStep.scroll(finder, offset: Offset.zero),
          isA<ScrollStep>());
      expect(
          ScenarioTestStep.drag(finder, offset: Offset.zero), isA<DragStep>());
      expect(ScenarioTestStep.wait(Duration.zero), isA<WaitStep>());
      expect(ScenarioTestStep.waitFor(finder), isA<WaitForWidgetStep>());
      expect(
        ScenarioTestStep.custom(
          id: 'c',
          description: 'd',
          action: (_) {},
        ),
        isA<CustomStep>(),
      );
    });
  });
}
