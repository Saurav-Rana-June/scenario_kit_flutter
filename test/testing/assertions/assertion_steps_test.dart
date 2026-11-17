import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

import '../steps/fake_scenario_step_context.dart';

void main() {
  group('Assertion Steps', () {
    late FakeScenarioStepContext context;

    setUp(() {
      context = FakeScenarioStepContext(testId: 'test_auth_01');
    });

    test('AssertExistsStep passes when widget exists and records result',
        () async {
      final finder = StepFinder.byText('Welcome');
      context.existingFinders.add(finder.description);

      final step = AssertExistsStep(finder: finder);
      await step.execute(context);

      expect(context.recordedAssertions.length, 1);
      final recorded = context.recordedAssertions.first;
      expect(recorded.isSuccess, isTrue);
      expect(recorded.testId, 'test_auth_01');
    });

    test('AssertExistsStep throws AssertionException when widget is missing',
        () async {
      final finder = StepFinder.byText('Missing Element');
      final step = AssertExistsStep(finder: finder);

      await expectLater(
        () => step.execute(context),
        throwsA(isA<AssertionException>().having(
          (e) => e.result.isFailure,
          'isFailure',
          isTrue,
        )),
      );

      expect(context.recordedAssertions.length, 1);
      expect(context.recordedAssertions.first.isFailure, isTrue);
      expect(context.recordedAssertions.first.failureMessage,
          contains('Missing Element'));
    });

    test('AssertNotExistsStep passes when widget is absent', () async {
      final finder = StepFinder.byText('Secret Modal');
      final step = AssertNotExistsStep(finder: finder);

      await step.execute(context);

      expect(context.recordedAssertions.length, 1);
      expect(context.recordedAssertions.first.isSuccess, isTrue);
    });

    test('AssertNotExistsStep throws AssertionException when widget exists',
        () async {
      final finder = StepFinder.byText('Error Dialog');
      context.existingFinders.add(finder.description);

      final step = AssertNotExistsStep(finder: finder);

      await expectLater(
        () => step.execute(context),
        throwsA(isA<AssertionException>()),
      );
      expect(context.recordedAssertions.first.isFailure, isTrue);
    });

    test('AssertTextStep passes on exact match', () async {
      final finder = StepFinder.byText('Hello');
      context.widgetTexts[finder.description] = 'Hello';

      final step = AssertTextStep(
        finder: finder,
        expectedText: 'Hello',
        matchType: TextMatchType.exact,
      );

      await step.execute(context);
      expect(context.recordedAssertions.first.isSuccess, isTrue);
      expect(context.recordedAssertions.first.actualValue, 'Hello');
    });

    test('AssertTextStep passes on substring match', () async {
      final finder = StepFinder.byText('Welcome, Alice!');
      context.widgetTexts[finder.description] = 'Welcome, Alice!';

      final step = AssertTextStep(
        finder: finder,
        expectedText: 'Alice',
        matchType: TextMatchType.contains,
      );

      await step.execute(context);
      expect(context.recordedAssertions.first.isSuccess, isTrue);
    });

    test('AssertTextStep passes on regex match', () async {
      final finder = StepFinder.byText('Order #12345');
      context.widgetTexts[finder.description] = 'Order #12345';

      final step = AssertTextStep(
        finder: finder,
        expectedText: r'Order #\d+',
        matchType: TextMatchType.regex,
      );

      await step.execute(context);
      expect(context.recordedAssertions.first.isSuccess, isTrue);
    });

    test('AssertTextStep throws AssertionException when text does not match',
        () async {
      final finder = StepFinder.byText('Status');
      context.widgetTexts[finder.description] = 'Failed';

      final step = AssertTextStep(
        finder: finder,
        expectedText: 'Success',
      );

      await expectLater(
        () => step.execute(context),
        throwsA(isA<AssertionException>().having(
          (e) => e.message,
          'message',
          contains('Text mismatch'),
        )),
      );
      expect(context.recordedAssertions.first.isFailure, isTrue);
    });

    test('AssertVisibleStep passes when widget is visible', () async {
      final finder = StepFinder.byText('Header');
      context.visibleFinders.add(finder.description);

      final step = AssertVisibleStep(finder: finder);
      await step.execute(context);

      expect(context.recordedAssertions.first.isSuccess, isTrue);
    });

    test('AssertVisibleStep throws AssertionException when widget is invisible',
        () async {
      final finder = StepFinder.byText('Offscreen');
      final step = AssertVisibleStep(finder: finder);

      await expectLater(
        () => step.execute(context),
        throwsA(isA<AssertionException>()),
      );
      expect(context.recordedAssertions.first.isFailure, isTrue);
    });

    test('AssertCustomStep evaluates boolean callback', () async {
      final passStep = AssertCustomStep(
        id: 'c1',
        description: 'Check active state',
        assertion: (_) => true,
      );

      await passStep.execute(context);
      expect(context.recordedAssertions.last.isSuccess, isTrue);

      final failStep = AssertCustomStep(
        id: 'c2',
        description: 'Check offline state',
        assertion: (_) => false,
      );

      await expectLater(
        () => failStep.execute(context),
        throwsA(isA<AssertionException>()),
      );
      expect(context.recordedAssertions.last.isFailure, isTrue);
    });

    test('AssertCustomStep catches unexpected exceptions in callback',
        () async {
      final errorStep = AssertCustomStep(
        id: 'c_err',
        description: 'Crashing check',
        assertion: (_) => throw StateError('Database unreachable'),
      );

      await expectLater(
        () => errorStep.execute(context),
        throwsA(isA<AssertionException>().having(
          (e) => e.message,
          'message',
          contains('Database unreachable'),
        )),
      );
    });

    test(
        'ScenarioTestStep assertion factory constructors produce expected instances',
        () {
      final finder = StepFinder.byText('Title');
      expect(ScenarioTestStep.assertExists(finder), isA<AssertExistsStep>());
      expect(
          ScenarioTestStep.assertNotExists(finder), isA<AssertNotExistsStep>());
      expect(ScenarioTestStep.assertText(finder, 'abc'), isA<AssertTextStep>());
      expect(ScenarioTestStep.assertVisible(finder), isA<AssertVisibleStep>());
      expect(
        ScenarioTestStep.assertCustom(
          id: 'ca',
          description: 'd',
          assertion: (_) => true,
        ),
        isA<AssertCustomStep>(),
      );
    });
  });
}
