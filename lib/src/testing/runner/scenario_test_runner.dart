import 'package:flutter/widgets.dart';

import '../../presentation/scenario_kit_bindings.dart';
import '../definitions/scenario_test.dart';
import '../executor/scenario_test_executor.dart';
import '../executor/test_execution_progress.dart';
import '../executor/test_execution_result.dart';
import '../registry/scenario_test_registry.dart';
import 'execution_mode.dart';
import 'screen_execution_summary.dart';

/// High-level coordinator managing functionality-wise and complete screen-level
/// test execution workflows in ScenarioKit.
class ScenarioTestRunner {
  /// Creates a [ScenarioTestRunner].
  ScenarioTestRunner({
    ScenarioTestRegistry? registry,
    ScenarioTestExecutor? executor,
  })  : registry = registry ?? ScenarioTestRegistry.instance,
        executor = executor ?? ScenarioTestExecutor();

  /// The registry providing registered test suites and test cases.
  final ScenarioTestRegistry registry;

  /// The underlying execution engine running individual tests and steps.
  final ScenarioTestExecutor executor;

  /// ValueListenable emitting live test execution progress updates.
  ValueNotifier<TestExecutionProgress> get progressNotifier =>
      executor.progressNotifier;

  /// Whether an execution run is currently in progress.
  bool get isRunning => executor.isRunning;

  /// Cancels an in-progress execution run.
  void cancel() => executor.cancel();

  ScreenshotCaptureCallback? _screenshotCapture(BuildContext context) {
    final bindings = ScenarioKitBindings.maybeOf(context);
    if (bindings == null) return null;
    return (name, {stepId, stepDescription}) =>
        bindings.screenshotService.capture(
          name: name,
          context: context,
          stepId: stepId,
          stepDescription: stepDescription,
        );
  }

  Future<T> _markTestsRunning<T>(
    BuildContext context,
    Future<T> Function() run,
  ) async {
    final bindings = ScenarioKitBindings.maybeOf(context);
    bindings?.testsRunning.value = true;
    try {
      return await run();
    } finally {
      bindings?.testsRunning.value = false;
    }
  }

  /// **Mode A**: Executes a single functionality test by [testId].
  Future<TestExecutionResult> runFunctionalityTest(
    String testId, {
    required BuildContext context,
    Duration stepDelay = Duration.zero,
  }) async {
    final test = registry.requireTestById(testId);
    return _markTestsRunning(context, () {
      return executor.executeTest(
        test,
        context: context,
        stepDelay: stepDelay,
        screenshotCapture: _screenshotCapture(context),
      );
    });
  }

  /// **Mode A**: Executes an arbitrary selected group of functionality tests by their [testIds].
  ///
  /// Tests are executed sequentially in the exact order specified.
  Future<ScreenExecutionSummary> runSelectedTests(
    List<String> testIds, {
    required BuildContext context,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
  }) async {
    final tests = <ScenarioTest>[];
    for (final id in testIds) {
      tests.add(registry.requireTestById(id));
    }

    final startTime = DateTime.now();
    final results = await _markTestsRunning(context, () {
      return executor.executeTests(
        tests,
        context: context,
        stopOnFirstFailure: stopOnFirstFailure,
        stepDelay: stepDelay,
        screenshotCapture: _screenshotCapture(context),
      );
    });
    final endTime = DateTime.now();

    return ScreenExecutionSummary.fromResults(
      executionMode: ExecutionMode.functionality,
      results: results,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// **Mode B**: Executes all registered tests associated with [screenName] in predictable sequence.
  ///
  /// Optionally filters by [group] if specified.
  Future<ScreenExecutionSummary> runScreenTests(
    String screenName, {
    required BuildContext context,
    String? group,
    bool stopOnFirstFailure = false,
    Duration stepDelay = Duration.zero,
  }) async {
    final allScreenTests = registry.getTestsForScreen(screenName);
    final tests = group == null || group.trim().isEmpty
        ? allScreenTests
        : allScreenTests.where((t) => t.group?.trim() == group.trim()).toList();

    final startTime = DateTime.now();
    final results = await _markTestsRunning(context, () {
      return executor.executeTests(
        tests,
        context: context,
        stopOnFirstFailure: stopOnFirstFailure,
        stepDelay: stepDelay,
        screenshotCapture: _screenshotCapture(context),
      );
    });
    final endTime = DateTime.now();

    return ScreenExecutionSummary.fromResults(
      screenName: screenName,
      executionMode: ExecutionMode.screen,
      results: results,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
