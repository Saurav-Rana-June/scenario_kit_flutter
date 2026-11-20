import 'package:flutter/material.dart';

import '../../core/scenario.dart';
import '../../testing/definitions/scenario_test.dart';
import '../../testing/definitions/test_status.dart' show StepStatus, TestStatus;
import '../../testing/executor/test_execution_progress.dart';
import '../../testing/executor/test_execution_result.dart';
import '../../testing/runner/screen_execution_summary.dart';
import 'scenario_kit_ui.dart';

SkScenarioItem mapScenarioToSkItem(Scenario scenario) {
  return SkScenarioItem(
    id: scenario.id,
    name: scenario.name,
    group: scenario.group?.trim().isNotEmpty == true ? scenario.group!.trim() : 'Ungrouped',
    description: scenario.description?.trim() ?? '',
    metaCount: scenario.metadata.length,
    isDefault: scenario.isDefault,
  );
}

SkStatus mapTestStatus(TestStatus status, {bool running = false}) {
  if (running) return SkStatus.running;
  switch (status) {
    case TestStatus.passed:
      return SkStatus.passed;
    case TestStatus.failed:
      return SkStatus.failed;
    case TestStatus.skipped:
      return SkStatus.skipped;
    case TestStatus.pending:
    case TestStatus.running:
      return SkStatus.idle;
  }
}

SkStepState mapStepStatus(StepStatus status) {
  switch (status) {
    case StepStatus.passed:
      return SkStepState.passed;
    case StepStatus.failed:
      return SkStepState.failed;
    case StepStatus.skipped:
      return SkStepState.skipped;
    case StepStatus.pending:
    case StepStatus.running:
      return SkStepState.idle;
  }
}

List<SkStep> buildSkSteps(
  ScenarioTest test,
  TestExecutionResult? result,
) {
  if (result != null && result.stepResults.isNotEmpty) {
    return result.stepResults
        .map(
          (s) => SkStep(
            s.description,
            state: mapStepStatus(s.status),
            durationMs: s.duration.inMilliseconds,
          ),
        )
        .toList();
  }
  return test.steps.map((s) => SkStep(s.description)).toList();
}

SkTestItem mapScenarioTestToSkItem(
  ScenarioTest test, {
  TestExecutionResult? result,
  String? runningTestId,
  TestExecutionProgress? progress,
}) {
  final isRunning = progress?.isRunning == true &&
      (progress?.currentTest?.id == test.id ||
          (runningTestId != null && runningTestId == test.id));
  final status = result != null
      ? mapTestStatus(result.status, running: isRunning)
      : (isRunning ? SkStatus.running : SkStatus.idle);

  Widget? screenshot;
  final shots = result?.screenshots;
  if (shots != null && shots.isNotEmpty) {
    screenshot = Image.memory(shots.first.bytes, fit: BoxFit.contain);
  }

  return SkTestItem(
    id: test.id,
    name: test.name,
    screen: test.screen?.trim().isNotEmpty == true ? test.screen!.trim() : 'Unknown',
    group: test.group?.trim().isNotEmpty == true ? test.group!.trim() : 'Ungrouped',
    description: test.description?.trim() ?? '',
    steps: buildSkSteps(test, result),
    status: status,
    durationMs: result?.duration.inMilliseconds,
    error: result?.errorMessage,
    screenshot: screenshot,
  );
}

SkRunProgress? mapExecutionProgress(TestExecutionProgress progress) {
  if (!progress.isRunning) return null;
  final current = progress.currentTest?.name ?? '…';
  return SkRunProgress(
    currentName: current,
    completed: progress.completedCount,
    total: progress.totalTests,
    passed: progress.passedCount,
    failed: progress.failedCount,
    skipped: progress.skippedCount,
    elapsed: progress.elapsed,
  );
}

SkReportData? mapSummaryToSkReport(ScreenExecutionSummary? summary) {
  if (summary == null || summary.results.isEmpty) return null;
  final items = summary.results
      .map((r) => mapResultToSkTestItem(r))
      .toList(growable: false);
  final failed = summary.failedCount;
  String? hint;
  if (failed > 1) {
    hint =
        'Likely shared cause: tests assert on the wrong screen. Check that each test switches to its own scenario first.';
  }
  return SkReportData(
    results: items,
    duration: summary.duration,
    hint: hint,
  );
}

SkTestItem mapResultToSkTestItem(TestExecutionResult result) {
  Widget? screenshot;
  if (result.screenshots.isNotEmpty) {
    screenshot = Image.memory(result.screenshots.first.bytes, fit: BoxFit.contain);
  }
  final steps = result.stepResults
      .map(
        (s) => SkStep(
          s.description,
          state: mapStepStatus(s.status),
          durationMs: s.duration.inMilliseconds,
        ),
      )
      .toList();
  return SkTestItem(
    id: result.testId,
    name: result.name,
    screen: result.screen?.trim().isNotEmpty == true ? result.screen!.trim() : 'Unknown',
    group: result.group?.trim().isNotEmpty == true ? result.group!.trim() : 'Ungrouped',
    description: '',
    steps: steps,
    status: mapTestStatus(result.status),
    durationMs: result.duration.inMilliseconds,
    error: result.errorMessage,
    screenshot: screenshot,
  );
}