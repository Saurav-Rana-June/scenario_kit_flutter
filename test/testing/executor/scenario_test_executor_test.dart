import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestExecutor & InAppStepContext Widget Integration', () {
    Widget buildTestApp({
      required TextEditingController controller,
      required VoidCallback onSubmit,
      required String title,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text(title, key: const ValueKey('title_text')),
              TextField(
                key: const ValueKey('email_input'),
                controller: controller,
              ),
              ElevatedButton(
                key: const ValueKey('submit_btn'),
                onPressed: onSubmit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('executes functional test successfully on live widget tree',
        (tester) async {
      final controller = TextEditingController();
      var submitted = false;

      await tester.pumpWidget(buildTestApp(
        controller: controller,
        onSubmit: () => submitted = true,
        title: 'Login Page',
      ));

      final testCase = ScenarioTest(
        name: 'Login Form Submission',
        steps: [
          ScenarioTestStep.assertExists(StepFinder.byKeyString('title_text')),
          ScenarioTestStep.assertText(
              StepFinder.byKeyString('title_text'), 'Login Page'),
          ScenarioTestStep.enterText(
              StepFinder.byKeyString('email_input'), 'test@flutter.dev'),
          ScenarioTestStep.tap(StepFinder.byKeyString('submit_btn')),
        ],
      );

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final result = await executor.executeTest(testCase, context: element);

      expect(result.isPassed, isTrue);
      expect(result.stepResults.length, 4);
      expect(controller.text, 'test@flutter.dev');
      expect(submitted, isTrue);
    });

    testWidgets('halts further steps and marks test failed when step fails',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      var stepAfterFailExecuted = false;

      final testCase = ScenarioTest(
        name: 'Failing Test',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('non_existent_key')),
          ScenarioTestStep.custom(
            id: 'unreachable_step',
            description: 'Should not run',
            action: (_) async => stepAfterFailExecuted = true,
          ),
        ],
      );

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final result = await executor.executeTest(testCase, context: element);

      expect(result.isFailed, isTrue);
      expect(result.stepResults.length, 1);
      expect(result.stepResults.first.isFailed, isTrue);
      expect(stepAfterFailExecuted, isFalse);
    });

    testWidgets('executes setup and teardown hooks reliably', (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      var setupRun = false;
      var teardownRun = false;

      final testCase = ScenarioTest(
        name: 'Lifecycle Test',
        setup: (_) async => setupRun = true,
        teardown: (_) async => teardownRun = true,
        steps: [
          // This step fails, but teardown must still execute
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('missing_element')),
        ],
      );

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final result = await executor.executeTest(testCase, context: element);

      expect(result.isFailed, isTrue);
      expect(setupRun, isTrue);
      expect(teardownRun, isTrue);
    });

    testWidgets('skips disabled tests', (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      final testCase = ScenarioTest(
        name: 'Disabled Test',
        isEnabled: false,
        steps: [
          ScenarioTestStep.tap(StepFinder.byKeyString('submit_btn')),
        ],
      );

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final result = await executor.executeTest(testCase, context: element);

      expect(result.isSkipped, isTrue);
      expect(result.errorMessage, 'Test is disabled');
    });

    testWidgets('stopOnFirstFailure stops remaining tests', (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      final t1 = ScenarioTest(
        id: 't1',
        name: 'Failing Test',
        steps: [
          ScenarioTestStep.assertExists(StepFinder.byKeyString('missing_btn')),
        ],
      );
      final t2 = ScenarioTest(
        id: 't2',
        name: 'Second Test',
        steps: [
          ScenarioTestStep.assertExists(StepFinder.byKeyString('title_text')),
        ],
      );

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final results = await executor.executeTests(
        [t1, t2],
        context: element,
        stopOnFirstFailure: true,
      );

      expect(results.length, 2);
      expect(results[0].isFailed, isTrue);
      expect(results[1].isSkipped, isTrue);
      expect(results[1].errorMessage, contains('stopOnFirstFailure'));
    });

    testWidgets('triggers screenshot callbacks at configured checkpoints',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      final capturedNames = <String>[];
      final fakeBytes = Uint8List.fromList([1, 2, 3]);

      final executor = ScenarioTestExecutor(
        onCaptureScreenshot: (name, {stepId, stepDescription}) async {
          capturedNames.add(name);
          return ScenarioScreenshot(
            name: name,
            bytes: fakeBytes,
            timestamp: DateTime.now(),
            stepId: stepId,
          );
        },
      );

      final testCase = ScenarioTest(
        id: 'screenshot_test',
        name: 'Screenshot Lifecycle',
        screenshotPolicy: const ScreenshotPolicy.all(),
        steps: [
          ScenarioTestStep.assertExists(
            StepFinder.byKeyString('title_text'),
            captureScreenshot: true,
          ),
        ],
      );

      final element = tester.element(find.byType(Scaffold));
      final result = await executor.executeTest(testCase, context: element);

      expect(result.isPassed, isTrue);
      expect(capturedNames, contains('screenshot_test_before_test'));
      expect(capturedNames, contains('screenshot_test_success'));
      expect(result.screenshots.length, greaterThanOrEqualTo(2));
    });

    testWidgets('cancellation aborts remaining steps and tests',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        controller: TextEditingController(),
        onSubmit: () {},
        title: 'Login Page',
      ));

      final executor = ScenarioTestExecutor();
      final element = tester.element(find.byType(Scaffold));

      final t1 = ScenarioTest(
        id: 't1_cancel',
        name: 'Cancelling Test',
        steps: [
          ScenarioTestStep.custom(
            id: 'cancel_trigger',
            description: 'Trigger cancel',
            action: (_) async => executor.cancel(),
          ),
          ScenarioTestStep.assertExists(StepFinder.byKeyString('title_text')),
        ],
      );
      final t2 = ScenarioTest(
        id: 't2_cancelled',
        name: 'Never run',
        steps: [
          ScenarioTestStep.assertExists(StepFinder.byKeyString('title_text')),
        ],
      );

      final results = await executor.executeTests([t1, t2], context: element);

      expect(results.length, 2);
      expect(results[1].isSkipped, isTrue);
      expect(results[1].errorMessage, contains('cancelled'));
    });
  });
}
