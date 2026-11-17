import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('ScenarioTestMatchers', () {
    test('isTestPassed matches passed results and describes mismatch', () {
      final passed = TestExecutionResult.passed(
        testId: 't1',
        name: 'Pass Test',
        duration: const Duration(milliseconds: 100),
        stepResults: const [],
        assertions: const [],
        logs: const [],
      );

      final failed = TestExecutionResult.failed(
        testId: 't2',
        name: 'Fail Test',
        errorMessage: 'Something exploded',
        duration: const Duration(milliseconds: 100),
        stepResults: const [],
        assertions: const [],
        logs: const [],
      );

      expect(passed, isTestPassed);
      expect(failed, isNot(isTestPassed));

      final mismatch = StringDescription();
      isTestPassed.describeMismatch(failed, mismatch, {}, false);
      expect(mismatch.toString(), contains('has status failed'));
      expect(mismatch.toString(), contains('Something exploded'));
    });

    test('isTestFailed matches failed results', () {
      final failed = TestExecutionResult.failed(
        testId: 't2',
        name: 'Fail Test',
        errorMessage: 'Boom',
        duration: const Duration(milliseconds: 100),
        stepResults: const [],
        assertions: const [],
        logs: const [],
      );

      expect(failed, isTestFailed);
    });

    test('isTestSkipped matches skipped results', () {
      final skipped = TestExecutionResult.skipped(
        testId: 't3',
        name: 'Skip Test',
        skipReason: 'Disabled',
      );

      expect(skipped, isTestSkipped);
      expect(skipped, isNot(isTestPassed));
    });

    test('isExecutionSuccess matches successful ScreenExecutionSummary', () {
      final summarySuccess = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.screen,
        results: [
          TestExecutionResult.passed(
            testId: 't1',
            name: 'Pass 1',
            duration: const Duration(milliseconds: 50),
            stepResults: const [],
            assertions: const [],
            logs: const [],
          ),
        ],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      final summaryFailure = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.screen,
        results: [
          TestExecutionResult.failed(
            testId: 't2',
            name: 'Fail 1',
            errorMessage: 'Error',
            duration: const Duration(milliseconds: 50),
            stepResults: const [],
            assertions: const [],
            logs: const [],
          ),
        ],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      expect(summarySuccess, isExecutionSuccess);
      expect(summaryFailure, isNot(isExecutionSuccess));
    });

    test('hasPassedSteps and hasFailedSteps match step counts', () {
      final result = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test',
        duration: const Duration(milliseconds: 100),
        stepResults: [
          StepExecutionResult.passed(
            stepId: 's1',
            description: 'Step 1',
            duration: const Duration(milliseconds: 20),
          ),
          StepExecutionResult.passed(
            stepId: 's2',
            description: 'Step 2',
            duration: const Duration(milliseconds: 20),
          ),
          StepExecutionResult.failed(
            stepId: 's3',
            description: 'Step 3',
            errorMessage: 'Step failed',
            duration: const Duration(milliseconds: 20),
          ),
        ],
        assertions: const [],
        logs: const [],
      );

      expect(result, hasPassedSteps(2));
      expect(result, hasFailedSteps(1));
      expect(result, isNot(hasPassedSteps(3)));
    });

    test('hasPassCount and hasFailCount match summary counts', () {
      final summary = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.screen,
        results: [
          TestExecutionResult.passed(
            testId: 't1',
            name: 'P1',
            duration: const Duration(milliseconds: 10),
            stepResults: const [],
            assertions: const [],
            logs: const [],
          ),
          TestExecutionResult.passed(
            testId: 't2',
            name: 'P2',
            duration: const Duration(milliseconds: 10),
            stepResults: const [],
            assertions: const [],
            logs: const [],
          ),
          TestExecutionResult.failed(
            testId: 't3',
            name: 'F1',
            errorMessage: 'fail',
            duration: const Duration(milliseconds: 10),
            stepResults: const [],
            assertions: const [],
            logs: const [],
          ),
        ],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      expect(summary, hasPassCount(2));
      expect(summary, hasFailCount(1));
    });
  });
}
