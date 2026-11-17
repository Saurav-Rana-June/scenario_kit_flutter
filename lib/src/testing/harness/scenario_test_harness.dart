import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../definitions/scenario_test.dart';
import '../definitions/scenario_test_suite.dart';
import '../executor/scenario_test_executor.dart';
import '../executor/test_execution_result.dart';
import '../registry/scenario_test_registry.dart';
import '../reporting/scenario_test_report.dart';
import '../runner/execution_mode.dart';
import '../runner/screen_execution_summary.dart';
import 'widget_tester_step_context.dart';

/// Test runner bridge that enables [ScenarioTest] test cases to be executed
/// in automated `testWidgets` and `integration_test` suites via [WidgetTester].
class ScenarioTestHarness {
  const ScenarioTestHarness._();

  /// Executes a single [ScenarioTest] on [tester].
  ///
  /// If [pumpApp] is provided, it is invoked to render or reset the target app
  /// before executing the test case.
  static Future<TestExecutionResult> runTest(
    WidgetTester tester,
    ScenarioTest test, {
    FutureOr<void> Function()? pumpApp,
    ScreenshotCaptureCallback? onCaptureScreenshot,
    Duration stepDelay = Duration.zero,
  }) async {
    if (pumpApp != null) {
      await pumpApp();
    }

    final rootElement = tester.binding.rootElement;
    if (rootElement == null) {
      throw StateError(
        'ScenarioTestHarness cannot execute: no widget tree is mounted. '
        'Provide a "pumpApp" callback or call "await tester.pumpWidget(...)" before executing tests.',
      );
    }

    final executor = ScenarioTestExecutor(
      contextFactory: (context, testId) => WidgetTesterStepContext(
        tester: tester,
        testId: testId,
      ),
      onCaptureScreenshot: onCaptureScreenshot,
    );

    return executor.executeTest(
      test,
      context: rootElement,
      stepDelay: stepDelay,
    );
  }

  /// Executes all tests in a [ScenarioTestSuite] on [tester].
  ///
  /// If [pumpApp] is provided, it is invoked before each test to guarantee
  /// a clean, isolated application state.
  static Future<ScreenExecutionSummary> runSuite(
    WidgetTester tester,
    ScenarioTestSuite suite, {
    FutureOr<void> Function()? pumpApp,
    ScreenshotCaptureCallback? onCaptureScreenshot,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
  }) async {
    final results = <TestExecutionResult>[];
    final startTime = DateTime.now();

    for (final test in suite.tests) {
      final result = await runTest(
        tester,
        test,
        pumpApp: pumpApp,
        onCaptureScreenshot: onCaptureScreenshot,
        stepDelay: stepDelay,
      );
      results.add(result);
      if (stopOnFirstFailure && result.isFailed) {
        break;
      }
    }

    final endTime = DateTime.now();
    return ScreenExecutionSummary.fromResults(
      executionMode: ExecutionMode.screen,
      results: results,
      startTime: startTime,
      endTime: endTime,
      screenName: suite.screenName,
    );
  }

  /// Executes an arbitrary sequence of [tests] on [tester].
  static Future<ScreenExecutionSummary> runSelectedTests(
    WidgetTester tester,
    Iterable<ScenarioTest> tests, {
    FutureOr<void> Function()? pumpApp,
    ScreenshotCaptureCallback? onCaptureScreenshot,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
  }) async {
    final results = <TestExecutionResult>[];
    final startTime = DateTime.now();

    for (final test in tests) {
      final result = await runTest(
        tester,
        test,
        pumpApp: pumpApp,
        onCaptureScreenshot: onCaptureScreenshot,
        stepDelay: stepDelay,
      );
      results.add(result);
      if (stopOnFirstFailure && result.isFailed) {
        break;
      }
    }

    final endTime = DateTime.now();
    return ScreenExecutionSummary.fromResults(
      executionMode: ExecutionMode.functionality,
      results: results,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Executes all test suites registered in [registry] on [tester].
  static Future<List<ScreenExecutionSummary>> runAll(
    WidgetTester tester,
    ScenarioTestRegistry registry, {
    FutureOr<void> Function()? pumpApp,
    ScreenshotCaptureCallback? onCaptureScreenshot,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
  }) async {
    final summaries = <ScreenExecutionSummary>[];
    for (final suite in registry.suites) {
      final summary = await runSuite(
        tester,
        suite,
        pumpApp: pumpApp,
        onCaptureScreenshot: onCaptureScreenshot,
        stopOnFirstFailure: stopOnFirstFailure,
        stepDelay: stepDelay,
      );
      summaries.add(summary);
      if (stopOnFirstFailure && summary.failedCount > 0) {
        break;
      }
    }
    return summaries;
  }

  /// Aggregates one or more [ScreenExecutionSummary] instances into a consolidated
  /// [ScenarioTestReport] suitable for JSON or HTML export.
  static ScenarioTestReport generateReport({
    required List<ScreenExecutionSummary> summaries,
    String title = 'ScenarioKit Functional Test Report',
    Map<String, dynamic> environment = const {},
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ScenarioTestReport.fromSummaries(
      summaries: summaries,
      title: title,
      environment: environment,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
