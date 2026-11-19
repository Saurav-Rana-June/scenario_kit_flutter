import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../testing/executor/test_execution_result.dart';
import '../../testing/reporting/html_report_exporter.dart';
import '../../testing/reporting/json_report_exporter.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../testing/runner/screen_execution_summary.dart';
import '../../testing/steps/step_execution_result.dart';
import '../../utils/scenario_panel_host.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_report_viewer.dart';

enum _ReportFilter { all, failed, passed }

/// Dedicated Reports tab inside the ScenarioKit developer bottom sheet.
///
/// Provides a clear, friendly inspection view of completed in-app test runs,
/// test failure details, assertion logs, step-by-step executions, screenshots,
/// and full JSON/HTML export capabilities.
class ScenarioReportsTab extends StatefulWidget {
  /// Creates a [ScenarioReportsTab].
  const ScenarioReportsTab({
    super.key,
    this.reportStore,
    this.theme,
    this.onSwitchToTests,
  });

  /// The report store tracking completed test runs. Defaults to [ScenarioReportStore.instance].
  final ScenarioReportStore? reportStore;

  /// Custom theme for the tab. Defaults to [ScenarioPanelThemeData.light()].
  final ScenarioPanelThemeData? theme;

  /// Callback to switch to the Tests tab (used in empty state).
  final VoidCallback? onSwitchToTests;

  @override
  State<ScenarioReportsTab> createState() => _ScenarioReportsTabState();
}

class _ScenarioReportsTabState extends State<ScenarioReportsTab> {
  late final ScenarioReportStore _store;
  _ReportFilter _selectedFilter = _ReportFilter.all;
  final Set<String> _expandedResultIds = {};
  int _selectedRunIndex = 0;

  @override
  void initState() {
    super.initState();
    _store = widget.reportStore ?? ScenarioReportStore.instance;
    _store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  ScenarioPanelThemeData _resolveTheme() {
    return widget.theme ?? ScenarioPanelThemeData.light();
  }

  ScreenExecutionSummary? get _currentSummary {
    final runs = _store.runs;
    if (runs.isEmpty) return null;
    if (_selectedRunIndex >= runs.length) return runs.first;
    return runs[_selectedRunIndex];
  }

  ScenarioTestReport? get _currentReport {
    final summary = _currentSummary;
    if (summary == null) return null;
    return ScenarioTestReport.fromSummaries(
      title: 'In-App Test Report',
      summaries: [summary],
    );
  }

  void _copyJson(BuildContext context) {
    final report = _currentReport;
    if (report == null) return;
    final json = const JsonReportExporter().export(report);
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('JSON test report copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyHtml(BuildContext context) {
    final report = _currentReport;
    if (report == null) return;
    final html = const HtmlReportExporter().export(report);
    Clipboard.setData(ClipboardData(text: html));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('HTML test report copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewFullReport(BuildContext context, ScenarioPanelThemeData theme) {
    final report = _currentReport;
    if (report == null) return;
    ScenarioReportViewerDialog.show(
      context,
      report: report,
      theme: theme,
    );
  }

  List<TestExecutionResult> _filterResults(List<TestExecutionResult> results) {
    switch (_selectedFilter) {
      case _ReportFilter.all:
        return results;
      case _ReportFilter.failed:
        return results.where((r) => r.isFailed).toList();
      case _ReportFilter.passed:
        return results.where((r) => r.isPassed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = _resolveTheme();
    final summary = _currentSummary;

    if (summary == null || summary.results.isEmpty) {
      return _buildEmptyState(panelTheme);
    }

    final allResults = summary.results;
    final failedCount = allResults.where((r) => r.isFailed).length;
    final passedCount = allResults.where((r) => r.isPassed).length;
    final filteredResults = _filterResults(allResults);

    return Material(
      color: panelTheme.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildRunsHeader(summary, panelTheme),
          const SizedBox(height: 12),
          _buildFilterBar(allResults.length, failedCount, passedCount, panelTheme),
          const SizedBox(height: 12),
          if (filteredResults.isEmpty)
            _buildNoMatchingFilterState(panelTheme)
          else
            for (final result in filteredResults) ...[
              _buildTestReportCard(result, panelTheme),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ScenarioPanelThemeData panelTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panelTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_outlined,
                size: 40,
                color: panelTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No test runs yet',
              style: TextStyle(
                color: panelTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Run tests from the Tests tab to inspect execution results, step traces, and exports here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (widget.onSwitchToTests != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('go_to_tests_tab_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  foregroundColor: panelTheme.onPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.checklist_rounded, size: 16),
                label: const Text('Go to Tests'),
                onPressed: widget.onSwitchToTests,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRunsHeader(
    ScreenExecutionSummary summary,
    ScenarioPanelThemeData panelTheme,
  ) {
    final runs = _store.runs;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (runs.length > 1) ...[
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedRunIndex < runs.length ? _selectedRunIndex : 0,
                    isDense: true,
                    style: TextStyle(
                      color: panelTheme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: List.generate(runs.length, (index) {
                      final r = runs[index];
                      final label = r.screenName != null
                          ? '${r.screenName} (${r.passedCount}/${r.totalTests})'
                          : 'Run #${runs.length - index} (${r.passedCount}/${r.totalTests})';
                      return DropdownMenuItem(
                        value: index,
                        child: Text(label),
                      );
                    }),
                    onChanged: (newIndex) {
                      if (newIndex != null) {
                        setState(() => _selectedRunIndex = newIndex);
                      }
                    },
                  ),
                ),
              ] else ...[
                Icon(
                  summary.isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  size: 18,
                  color: summary.isSuccess
                      ? panelTheme.successColor
                      : panelTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.screenName ?? 'Latest Test Run',
                    style: TextStyle(
                      color: panelTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _buildExportActions(panelTheme),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final successRate = summary.totalTests > 0
                  ? (summary.passedCount / summary.totalTests) * 100
                  : 0.0;
              return Row(
                children: [
                  Text(
                    '${summary.passedCount}/${summary.totalTests} Passed (${successRate.toStringAsFixed(0)}%) \u2022 ${summary.duration.inMilliseconds}ms',
                    style: TextStyle(
                      color: panelTheme.subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: const ValueKey('view_full_report_button'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('View Full Report', style: TextStyle(fontSize: 12)),
                    onPressed: () => _viewFullReport(context, panelTheme),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportActions(ScenarioPanelThemeData panelTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('copy_json_report_button'),
          icon: const Icon(Icons.code_rounded, size: 14),
          label: const Text('Copy JSON', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: panelTheme.textColor,
            side: BorderSide(color: panelTheme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _copyJson(context),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          key: const ValueKey('copy_html_report_button'),
          icon: const Icon(Icons.html_rounded, size: 14),
          label: const Text('Copy HTML', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: panelTheme.textColor,
            side: BorderSide(color: panelTheme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _copyHtml(context),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    int totalCount,
    int failedCount,
    int passedCount,
    ScenarioPanelThemeData panelTheme,
  ) {
    return Row(
      children: [
        _buildFilterChip(
          key: const ValueKey('report_filter_all'),
          label: 'All ($totalCount)',
          isSelected: _selectedFilter == _ReportFilter.all,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.all),
          panelTheme: panelTheme,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          key: const ValueKey('report_filter_failed'),
          label: 'Failed ($failedCount)',
          isSelected: _selectedFilter == _ReportFilter.failed,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.failed),
          panelTheme: panelTheme,
          accentColor: panelTheme.errorColor,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          key: const ValueKey('report_filter_passed'),
          label: 'Passed ($passedCount)',
          isSelected: _selectedFilter == _ReportFilter.passed,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.passed),
          panelTheme: panelTheme,
          accentColor: panelTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ScenarioPanelThemeData panelTheme,
    Color? accentColor,
  }) {
    final activeColor = accentColor ?? panelTheme.primaryColor;
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : panelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : panelTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : panelTheme.textColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoMatchingFilterState(ScenarioPanelThemeData panelTheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No test results match the selected filter.',
          style: TextStyle(color: panelTheme.subtitleColor, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTestReportCard(
    TestExecutionResult result,
    ScenarioPanelThemeData panelTheme,
  ) {
    final isExpanded = _expandedResultIds.contains(result.testId);
    final isFailed = result.isFailed;
    final badgeColor = isFailed ? panelTheme.errorColor : panelTheme.successColor;

    return Container(
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed
              ? panelTheme.errorColor.withValues(alpha: 0.35)
              : panelTheme.borderColor,
          width: isFailed ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedResultIds.remove(result.testId);
                } else {
                  _expandedResultIds.add(result.testId);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isFailed ? 'FAILED' : 'PASSED',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: TextStyle(
                            color: panelTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${result.screen != null ? "${result.screen} \u2022 " : ""}${result.duration.inMilliseconds}ms',
                          style: TextStyle(
                            color: panelTheme.subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: panelTheme.subtitleColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: panelTheme.borderColor.withValues(alpha: 0.7)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (result.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error: ${result.errorMessage}',
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 12,
                                fontFamily: 'monospace',
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final hasScreenshot = result.screenshots.isNotEmpty;
                      final isWide = constraints.maxWidth >= 520;

                      final stepsWidget = _buildStepsColumn(result, panelTheme);
                      final screenshotWidget = hasScreenshot
                          ? _buildScreenshotColumn(
                              result.screenshots.first,
                              panelTheme,
                            )
                          : const SizedBox.shrink();

                      if (isWide && hasScreenshot) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: stepsWidget),
                            const SizedBox(width: 16),
                            SizedBox(width: 140, child: screenshotWidget),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          stepsWidget,
                          if (hasScreenshot) ...[
                            const SizedBox(height: 12),
                            screenshotWidget,
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsColumn(
    TestExecutionResult result,
    ScenarioPanelThemeData panelTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEPS',
          style: TextStyle(
            color: panelTheme.subtitleColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        if (result.stepResults.isEmpty)
          Text(
            'No step details recorded.',
            style: TextStyle(
              color: panelTheme.subtitleColor,
              fontSize: 12,
            ),
          )
        else
          for (final step in result.stepResults) ...[
            _buildStepRow(step, panelTheme),
            const SizedBox(height: 4),
          ],
      ],
    );
  }

  Widget _buildStepRow(
    StepExecutionResult step,
    ScenarioPanelThemeData panelTheme,
  ) {
    final Color dotColor;
    if (step.isPassed) {
      dotColor = panelTheme.successColor;
    } else if (step.isFailed) {
      dotColor = panelTheme.errorColor;
    } else {
      dotColor = panelTheme.subtitleColor.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: panelTheme.chipColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: panelTheme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(
                color: panelTheme.textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotColumn(
    ScenarioScreenshot screenshot,
    ScenarioPanelThemeData panelTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCREENSHOT',
          style: TextStyle(
            color: panelTheme.subtitleColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            showDialog<void>(
              context: ScenarioPanelHost.modalContext(context),
              useRootNavigator: true,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    InteractiveViewer(
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          screenshot.bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: 200,
                            color: panelTheme.chipColor,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: panelTheme.subtitleColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                        ),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: panelTheme.borderColor),
              color: panelTheme.surfaceColor,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    screenshot.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: panelTheme.chipColor,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: panelTheme.subtitleColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_full_rounded, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Enlarge',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
