import 'package:flutter/material.dart';

import '../../testing/definitions/scenario_test.dart';
import '../../testing/executor/test_execution_progress.dart';
import '../../testing/executor/test_execution_result.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/runner/execution_mode.dart';
import '../../testing/runner/scenario_test_runner.dart';
import '../../testing/runner/screen_execution_summary.dart';
import '../../utils/scenario_panel_host.dart';
import '../scenario_kit_bindings.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_kit_mappers.dart';
import 'scenario_kit_ui.dart';

/// Interactive developer dashboard for filtering, selecting, executing, and
/// reviewing screen-level and functionality-level test suites in ScenarioKit.
class ScenarioTestDashboard extends StatefulWidget {
  const ScenarioTestDashboard({
    super.key,
    this.registry,
    this.runner,
    this.theme,
    this.onClose,
    this.executionContext,
    this.currentScreenName,
    this.onNavigateToScreen,
    this.onExecutionCompleted,
    this.onViewReport,
  });

  final ScenarioTestRegistry? registry;
  final ScenarioTestRunner? runner;
  final ScenarioPanelThemeData? theme;
  final VoidCallback? onClose;
  final BuildContext? executionContext;
  final String? currentScreenName;
  final void Function(String screenName)? onNavigateToScreen;
  final void Function(ScreenExecutionSummary summary)? onExecutionCompleted;
  final VoidCallback? onViewReport;

  @override
  State<ScenarioTestDashboard> createState() => _ScenarioTestDashboardState();
}

class _ScenarioTestDashboardState extends State<ScenarioTestDashboard> {
  late final ScenarioTestRegistry _registry;
  late final ScenarioTestRunner _runner;
  final Map<String, TestExecutionResult> _latestResults = {};

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? ScenarioTestRegistry.instance;
    _runner = widget.runner ?? ScenarioTestRunner(registry: _registry);
    _registry.addListener(_onRegistryChanged);
  }

  void _onRegistryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _registry.removeListener(_onRegistryChanged);
    super.dispose();
  }

  BuildContext _executionContext(BuildContext context) {
    final host = widget.executionContext;
    if (host != null && host.mounted) {
      return ScenarioKitBindings.resolveExecutionContext(host);
    }
    return ScenarioKitBindings.resolveExecutionContext(context);
  }

  bool _isTestRunBlocked(ScenarioTest test) {
    final active = widget.currentScreenName;
    final target = test.screen?.trim();
    if (active == null || target == null || target.isEmpty) return false;
    return active != target;
  }

  void _recordSummary(ScreenExecutionSummary summary) {
    setState(() {
      for (final r in summary.results) {
        _latestResults[r.testId] = r;
      }
    });
    ScenarioReportStore.instance.recordSummary(summary);
    widget.onExecutionCompleted?.call(summary);
  }

  Future<void> _runIds(BuildContext context, List<String> ids) async {
    if (ids.isEmpty) return;

    if (ids.length == 1) {
      final test = _registry.getTestById(ids.single);
      if (test != null) {
        _handleTapRunSingleTest(context, test);
      }
      return;
    }

    final tests = ids
        .map(_registry.getTestById)
        .whereType<ScenarioTest>()
        .toList();
    if (tests.isEmpty) return;

    for (final test in tests) {
      if (_isTestRunBlocked(test)) {
        final target = test.screen?.trim();
        if (target != null) {
          _showMismatchDialog(context, targetScreen: target);
        }
        return;
      }
    }

    final summary = await _runner.runSelectedTests(
      ids,
      context: _executionContext(context),
    );
    if (!mounted) return;
    _recordSummary(summary);
  }

  void _handleTapRunSingleTest(BuildContext context, ScenarioTest test) {
    final active = widget.currentScreenName;
    final target = test.screen?.trim();

    if (active != null &&
        target != null &&
        target.isNotEmpty &&
        active != target) {
      _showMismatchDialog(context, targetScreen: target);
      return;
    }

    _runSingleTest(context, test);
  }

  void _showMismatchDialog(
    BuildContext context, {
    required String targetScreen,
  }) {
    final panelTheme = widget.theme ?? ScenarioPanelThemeData.light();
    final hasNavigation = widget.onNavigateToScreen != null;

    showDialog<void>(
      context: ScenarioPanelHost.modalContext(context),
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: panelTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: panelTheme.borderColor),
        ),
        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.amber, size: 36),
        title: Text(
          hasNavigation ? 'Switch Screen to Run Test' : 'Navigate to Run Test',
          style: TextStyle(
            color: panelTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          hasNavigation
              ? 'You are currently on "${widget.currentScreenName}". '
                  'This test requires "$targetScreen" to be mounted.'
              : 'You are currently on "${widget.currentScreenName}". '
                  'Navigate to "$targetScreen" before running tests from this suite.',
          style: TextStyle(
            color: panelTheme.subtitleColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: panelTheme.subtitleColor),
            ),
          ),
          if (hasNavigation)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: panelTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text('Go to $targetScreen'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                widget.onClose?.call();
                widget.onNavigateToScreen!(targetScreen);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _runSingleTest(BuildContext context, ScenarioTest test) async {
    if (_isTestRunBlocked(test)) return;
    final result = await _runner.runFunctionalityTest(
      test.id,
      context: _executionContext(context),
    );
    if (!mounted) return;
    final summary = ScreenExecutionSummary.fromResults(
      executionMode: ExecutionMode.functionality,
      results: [result],
      startTime: result.timestamp,
      endTime: result.timestamp.add(result.duration),
      screenName: test.screen,
    );
    _recordSummary(summary);
  }

  @override
  Widget build(BuildContext context) {
  final theme = widget.theme ?? ScenarioPanelThemeData.light();
    return SkTheme(
      data: theme,
      child: ValueListenableBuilder<TestExecutionProgress>(
      valueListenable: _runner.progressNotifier,
      builder: (context, progress, _) {
        final tests = _registry.allTests
            .map(
              (t) => mapScenarioTestToSkItem(
                t,
                result: _latestResults[t.id],
                progress: progress,
              ),
            )
            .toList(growable: false);

        return SkTestsTab(
          tests: tests,
          activeScreen: widget.currentScreenName,
          progress: mapExecutionProgress(progress),
          onRun: (ids) => _runIds(context, ids),
          onCancel: _runner.cancel,
          onViewReport: widget.onViewReport,
        );
      },
    ),
    );
  }
}