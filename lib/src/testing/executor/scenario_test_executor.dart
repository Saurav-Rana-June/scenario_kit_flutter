import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../presentation/scenario_scope.dart';
import '../definitions/scenario_test.dart';
import '../definitions/scenario_test_step.dart';
import '../steps/scenario_step_context.dart';
import '../steps/step_execution_result.dart';
import 'in_app_step_context.dart';
import 'test_execution_progress.dart';
import 'test_execution_result.dart';

/// Signature for screenshot capture callbacks.
typedef ScreenshotCaptureCallback = Future<ScenarioScreenshot?> Function(
  String name, {
  String? stepId,
  String? stepDescription,
});

/// Orchestrates and executes [ScenarioTest] instances against a rendered widget tree.
class ScenarioTestExecutor extends ChangeNotifier {
  /// Creates a [ScenarioTestExecutor].
  ScenarioTestExecutor({
    this.onCaptureScreenshot,
    this.contextFactory,
  });

  /// Optional callback invoked when a test or step triggers a screenshot.
  final ScreenshotCaptureCallback? onCaptureScreenshot;

  /// Optional factory allowing custom context instantiation (e.g. for mock testing).
  final ScenarioStepContext Function(BuildContext context, String testId)?
      contextFactory;

  final ValueNotifier<TestExecutionProgress> _progressNotifier =
      ValueNotifier<TestExecutionProgress>(TestExecutionProgress.idle());

  /// ValueListenable emitting live test execution progress updates.
  ValueNotifier<TestExecutionProgress> get progressNotifier =>
      _progressNotifier;

  /// Current progress snapshot.
  TestExecutionProgress get progress => _progressNotifier.value;

  bool _isCancelled = false;

  /// Whether a cancellation request has been triggered.
  bool get isCancelled => _isCancelled;

  bool _isRunning = false;

  /// Whether tests are actively being executed.
  bool get isRunning => _isRunning;

  /// Signals the executor to abort remaining tests.
  void cancel() {
    _isCancelled = true;
    notifyListeners();
  }

  /// Executes an ordered list of [tests] against the widget tree anchored at [context].
  Future<List<TestExecutionResult>> executeTests(
    Iterable<ScenarioTest> tests, {
    required BuildContext context,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
    ScreenshotCaptureCallback? screenshotCapture,
  }) async {
    final capture = screenshotCapture ?? onCaptureScreenshot;
    if (_isRunning) {
      throw StateError(
          'ScenarioTestExecutor is already running another execution run.');
    }

    _isRunning = true;
    _isCancelled = false;
    final testList = tests.toList();
    final results = <TestExecutionResult>[];
    final overallStopwatch = Stopwatch()..start();

    int passed = 0;
    int failed = 0;
    int skipped = 0;

    _updateProgress(
      totalTests: testList.length,
      currentTestIndex: 0,
      passedCount: 0,
      failedCount: 0,
      skippedCount: 0,
      elapsed: Duration.zero,
      isRunning: true,
    );

    try {
      for (int i = 0; i < testList.length; i++) {
        if (_isCancelled) {
          final remaining = testList.sublist(i);
          for (final t in remaining) {
            results.add(TestExecutionResult.skipped(
              testId: t.id,
              name: t.name,
              screen: t.screen,
              group: t.group,
              skipReason: 'Execution cancelled by user',
            ));
            skipped++;
          }
          break;
        }

        final currentTest = testList[i];
        _updateProgress(
          totalTests: testList.length,
          currentTestIndex: i,
          currentTest: currentTest,
          totalStepsInCurrentTest: currentTest.steps.length,
          passedCount: passed,
          failedCount: failed,
          skippedCount: skipped,
          elapsed: overallStopwatch.elapsed,
          isRunning: true,
        );

        final result = await _executeSingleTest(
          currentTest,
          context: context,
          stepDelay: stepDelay,
          screenshotCapture: capture,
        );

        results.add(result);

        if (result.isPassed) {
          passed++;
        } else if (result.isFailed) {
          failed++;
        } else if (result.isSkipped) {
          skipped++;
        }

        _updateProgress(
          totalTests: testList.length,
          currentTestIndex: i + 1,
          passedCount: passed,
          failedCount: failed,
          skippedCount: skipped,
          elapsed: overallStopwatch.elapsed,
          isRunning: true,
        );

        if (stopOnFirstFailure && result.isFailed) {
          final remaining = testList.sublist(i + 1);
          for (final t in remaining) {
            results.add(TestExecutionResult.skipped(
              testId: t.id,
              name: t.name,
              screen: t.screen,
              group: t.group,
              skipReason: 'Skipped due to stopOnFirstFailure policy',
            ));
            skipped++;
          }
          break;
        }
      }
    } finally {
      overallStopwatch.stop();
      _isRunning = false;
      _updateProgress(
        totalTests: testList.length,
        currentTestIndex: testList.length,
        passedCount: passed,
        failedCount: failed,
        skippedCount: skipped,
        elapsed: overallStopwatch.elapsed,
        isRunning: false,
      );
      notifyListeners();
    }

    return List.unmodifiable(results);
  }

  /// Executes an individual [ScenarioTest].
  Future<TestExecutionResult> executeTest(
    ScenarioTest test, {
    required BuildContext context,
    Duration stepDelay = Duration.zero,
    ScreenshotCaptureCallback? screenshotCapture,
  }) async {
    final list = await executeTests(
      [test],
      context: context,
      stepDelay: stepDelay,
      screenshotCapture: screenshotCapture,
    );
    return list.first;
  }

  Future<TestExecutionResult> _executeSingleTest(
    ScenarioTest test, {
    required BuildContext context,
    required Duration stepDelay,
    ScreenshotCaptureCallback? screenshotCapture,
  }) async {
    final capture = screenshotCapture ?? onCaptureScreenshot;
    if (!test.isEnabled) {
      return TestExecutionResult.skipped(
        testId: test.id,
        name: test.name,
        screen: test.screen,
        group: test.group,
        skipReason: 'Test is disabled',
      );
    }

    final stopwatch = Stopwatch()..start();
    final stepResults = <StepExecutionResult>[];
    final screenshots = <ScenarioScreenshot>[];
    final stepContext = contextFactory != null
        ? contextFactory!(context, test.id)
        : InAppStepContext(rootContext: context, testId: test.id);

    await _applyRequiredScenario(test, context, stepContext);

    // Initial screenshot checkpoint
    if (test.screenshotPolicy.captureBeforeTest && capture != null) {
      final initial = await capture(
        '${test.id}_before_test',
        stepDescription: 'Before test execution',
      );
      if (initial != null) screenshots.add(initial);
    }

    bool testFailed = false;
    String? failureMessage;
    StackTrace? failureStackTrace;

    // Execute setup
    if (test.setup != null) {
      try {
        stepContext.log('Executing test setup hook');
        if (context.mounted) {
          await test.setup!(context);
        }
      } catch (e, st) {
        stopwatch.stop();
        return TestExecutionResult.failed(
          testId: test.id,
          name: test.name,
          screen: test.screen,
          group: test.group,
          duration: stopwatch.elapsed,
          errorMessage: 'Setup hook failed: $e',
          stackTrace: st,
          screenshots: screenshots,
        );
      }
    }

    try {
      for (int s = 0; s < test.steps.length; s++) {
        if (_isCancelled) {
          stepResults.add(StepExecutionResult.skipped(
            stepId: test.steps[s].id,
            description: test.steps[s].description,
          ));
          continue;
        }

        final step = test.steps[s];
        _updateProgress(
          currentStepIndex: s,
          currentStep: step,
          totalStepsInCurrentTest: test.steps.length,
          isRunning: true,
        );

        final stepStopwatch = Stopwatch()..start();
        final effectiveTimeout = step.timeout ?? test.timeout;
        final assertionStart = stepContext.recordedAssertions.length;

        try {
          await step.execute(stepContext).timeout(effectiveTimeout);
          stepStopwatch.stop();

          // Check if step-level or policy screenshot requested
          ScenarioScreenshot? stepScreenshot;
          if ((step.captureScreenshot ||
                  test.screenshotPolicy.captureAfterSteps) &&
              capture != null) {
            stepScreenshot = await capture(
              '${test.id}_step_${step.id}',
              stepId: step.id,
              stepDescription: step.description,
            );
            if (stepScreenshot != null) screenshots.add(stepScreenshot);
          }

          final stepAssertions = stepContext.recordedAssertions
              .sublist(assertionStart, stepContext.recordedAssertions.length);
          stepResults.add(StepExecutionResult.passed(
            stepId: step.id,
            description: step.description,
            duration: stepStopwatch.elapsed,
            assertions: stepAssertions,
            screenshotBytes: stepScreenshot?.bytes,
          ));

          if (stepDelay > Duration.zero) {
            await Future<void>.delayed(stepDelay);
          }
        } catch (e, st) {
          stepStopwatch.stop();
          testFailed = true;
          failureMessage = e.toString();
          failureStackTrace = st;

          final stepAssertions = stepContext.recordedAssertions
              .sublist(assertionStart, stepContext.recordedAssertions.length);

          ScenarioScreenshot? failScreenshot;
          if (test.screenshotPolicy.captureOnFailure && capture != null) {
            failScreenshot = await capture(
              '${test.id}_failure_${step.id}',
              stepId: step.id,
              stepDescription: step.description,
            );
            if (failScreenshot != null) screenshots.add(failScreenshot);
          }

          stepResults.add(StepExecutionResult.failed(
            stepId: step.id,
            description: step.description,
            duration: stepStopwatch.elapsed,
            errorMessage: failureMessage,
            stackTrace: failureStackTrace,
            assertions: stepAssertions,
            screenshotBytes: failScreenshot?.bytes,
          ));

          break; // Stop remaining steps in this test on failure
        }
      }
    } finally {
      // Execute teardown in finally block to ensure it always runs
      if (test.teardown != null) {
        try {
          stepContext.log('Executing test teardown hook');
          if (context.mounted) {
            await test.teardown!(context);
          }
        } catch (e) {
          stepContext.log('Error during teardown: $e');
        }
      }
      stopwatch.stop();
    }

    // Success checkpoint screenshot
    if (!testFailed &&
        test.screenshotPolicy.captureOnSuccess &&
        capture != null) {
      final successScreenshot = await capture(
        '${test.id}_success',
        stepDescription: 'After successful execution',
      );
      if (successScreenshot != null) screenshots.add(successScreenshot);
    }

    final logs = stepContext.recordedLogs;
    final assertions = stepContext.recordedAssertions;

    if (testFailed) {
      return TestExecutionResult.failed(
        testId: test.id,
        name: test.name,
        screen: test.screen,
        group: test.group,
        duration: stopwatch.elapsed,
        errorMessage: failureMessage ?? 'Test failed',
        stackTrace: failureStackTrace,
        stepResults: stepResults,
        screenshots: screenshots,
        logs: logs,
        assertions: assertions,
      );
    }

    return TestExecutionResult.passed(
      testId: test.id,
      name: test.name,
      screen: test.screen,
      group: test.group,
      duration: stopwatch.elapsed,
      stepResults: stepResults,
      screenshots: screenshots,
      logs: logs,
      assertions: assertions,
    );
  }

  Future<void> _applyRequiredScenario(
    ScenarioTest test,
    BuildContext context,
    ScenarioStepContext stepContext,
  ) async {
    final scenarioId = test.requiredScenarioId;
    if (scenarioId == null || scenarioId.trim().isEmpty) return;

    final controller = stepContext.resolveScenarioController() ??
        ScenarioScope.maybeOf(context);
    if (controller == null) {
      throw StateError(
        'Test "${test.id}" requires scenario "$scenarioId" but no '
        'ScenarioController was found in the widget tree.',
      );
    }
    stepContext.log('Selecting required scenario "$scenarioId"');
    controller.selectById(scenarioId);
    await stepContext.pump(const Duration(milliseconds: 300));
    await stepContext.pump();
  }

  void _updateProgress({
    int? totalTests,
    int? currentTestIndex,
    ScenarioTest? currentTest,
    int? currentStepIndex,
    int? totalStepsInCurrentTest,
    ScenarioTestStep? currentStep,
    int? passedCount,
    int? failedCount,
    int? skippedCount,
    Duration? elapsed,
    bool? isRunning,
  }) {
    _progressNotifier.value = _progressNotifier.value.copyWith(
      totalTests: totalTests,
      currentTestIndex: currentTestIndex,
      currentTest: currentTest,
      currentStepIndex: currentStepIndex,
      totalStepsInCurrentTest: totalStepsInCurrentTest,
      currentStep: currentStep,
      passedCount: passedCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
      elapsed: elapsed,
      isRunning: isRunning,
    );
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }
}
