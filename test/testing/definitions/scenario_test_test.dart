import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTest Model', () {
    test('creates test with explicit parameters and derives slug when omitted',
        () {
      final test1 = ScenarioTest(
        name: 'Login with valid email & password!',
        description: 'Tests happy path login',
        screen: 'LoginScreen',
        group: 'Auth',
        tags: const ['smoke', 'p0'],
        timeout: const Duration(seconds: 15),
        screenshotPolicy: const ScreenshotPolicy.all(),
        isEnabled: true,
        metadata: const {'api_version': 2},
      );

      expect(test1.id, 'login_with_valid_email_password');
      expect(test1.name, 'Login with valid email & password!');
      expect(test1.description, 'Tests happy path login');
      expect(test1.screen, 'LoginScreen');
      expect(test1.group, 'Auth');
      expect(test1.tags, ['smoke', 'p0']);
      expect(test1.timeout, const Duration(seconds: 15));
      expect(test1.screenshotPolicy.captureOnSuccess, isTrue);
      expect(test1.isEnabled, isTrue);
      expect(test1.metadata, {'api_version': 2});
    });

    test(
        'throws InvalidScenarioException on empty name or non-positive timeout',
        () {
      expect(
        () => ScenarioTest(name: '   '),
        throwsA(isA<InvalidScenarioException>()),
      );

      expect(
        () => ScenarioTest(name: 'Valid Name', timeout: Duration.zero),
        throwsA(isA<InvalidScenarioException>()),
      );
    });

    test('supports copyWith and value equality', () {
      final t1 = ScenarioTest(
        id: 'test_1',
        name: 'Test 1',
        screen: 'ScreenA',
        group: 'GroupA',
      );

      final t2 = ScenarioTest(
        id: 'test_1',
        name: 'Test 1',
        screen: 'ScreenA',
        group: 'GroupA',
      );

      final t3 = t1.copyWith(name: 'Test 1 Updated');

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1, isNot(equals(t3)));
      expect(t3.name, 'Test 1 Updated');
      expect(t3.id, 'test_1');
    });
  });

  group('ScreenshotPolicy', () {
    test('preset configurations have expected flags', () {
      const defaultPolicy = ScreenshotPolicy();
      expect(defaultPolicy.captureOnFailure, isTrue);
      expect(defaultPolicy.captureOnSuccess, isFalse);
      expect(defaultPolicy.hasAnyCapture, isTrue);

      const allPolicy = ScreenshotPolicy.all();
      expect(allPolicy.captureBeforeTest, isTrue);
      expect(allPolicy.captureAfterSteps, isTrue);
      expect(allPolicy.captureOnSuccess, isTrue);
      expect(allPolicy.captureOnFailure, isTrue);

      const disabled = ScreenshotPolicy.disabled();
      expect(disabled.hasAnyCapture, isFalse);
    });
  });

  group('StepFinder', () {
    test('creates various finder types correctly', () {
      final keyFinder = StepFinder.byKeyString('submit_btn');
      expect(keyFinder.type, StepFinderType.byKey);
      expect(keyFinder.key, const ValueKey<String>('submit_btn'));

      final textFinder = StepFinder.byText('Login');
      expect(textFinder.type, StepFinderType.byText);
      expect(textFinder.text, 'Login');

      final typeFinder = StepFinder.byWidgetType(ElevatedButton);
      expect(typeFinder.type, StepFinderType.byType);
      expect(typeFinder.widgetType, ElevatedButton);
    });

    testWidgets('matchesElement matches matching widgets in element tree',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Hello ScenarioKit', key: Key('greeting_text')),
                IconButton(
                  icon: const Icon(Icons.star),
                  tooltip: 'Favorite',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final keyFinder = StepFinder.byKey(const Key('greeting_text'));
      final textFinder = StepFinder.byText('ScenarioKit');
      final tooltipFinder = StepFinder.byTooltip('Favorite');
      final iconFinder = StepFinder.byIcon(Icons.star);

      final textElement =
          tester.element(find.byKey(const Key('greeting_text')));
      final iconElement = tester.element(find.byIcon(Icons.star));

      expect(keyFinder.matchesElement(textElement), isTrue);
      expect(textFinder.matchesElement(textElement), isTrue);
      expect(tooltipFinder.matchesElement(iconElement), isFalse);
      expect(iconFinder.matchesElement(iconElement), isTrue);
    });
  });

  group('TestStatus & StepStatus', () {
    test('status getters evaluate correctly', () {
      expect(TestStatus.pending.isCompleted, isFalse);
      expect(TestStatus.running.isCompleted, isFalse);
      expect(TestStatus.passed.isCompleted, isTrue);
      expect(TestStatus.passed.isPassed, isTrue);
      expect(TestStatus.failed.isCompleted, isTrue);
      expect(TestStatus.failed.isFailed, isTrue);
      expect(TestStatus.skipped.isCompleted, isTrue);

      expect(StepStatus.passed.isCompleted, isTrue);
      expect(StepStatus.running.isCompleted, isFalse);
    });
  });
}
