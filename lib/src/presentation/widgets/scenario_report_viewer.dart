import 'package:flutter/material.dart';

import '../../testing/assertions/assertion_result.dart';
import '../../testing/executor/test_execution_result.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../testing/steps/step_execution_result.dart';
import '../theme/scenario_panel_theme.dart';

/// Modal dialog displaying a rich, in-app visualization of a [ScenarioTestReport].
class ScenarioReportViewerDialog extends StatelessWidget {
  /// Creates a [ScenarioReportViewerDialog].
  const ScenarioReportViewerDialog({
    required this.report,
    this.theme,
    super.key,
  });

  /// The test report to display.
  final ScenarioTestReport report;

  /// Custom theme for the dialog.
  final ScenarioPanelThemeData? theme;

  /// Displays the report viewer modal dialog.
  static Future<void> show(
    BuildContext context, {
    required ScenarioTestReport report,
    ScenarioPanelThemeData? theme,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ScenarioReportViewerDialog(
        report: report,
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = theme ?? ScenarioPanelThemeData.light();

    return Dialog(
      backgroundColor: panelTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: panelTheme.borderRadius,
        side: BorderSide(
          color: panelTheme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: ClipRRect(
          borderRadius: panelTheme.borderRadius,
          child: Column(
            children: [
              _buildHeader(context, panelTheme),
              Divider(
                height: 1,
                color: panelTheme.borderColor.withValues(alpha: 0.7),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildKpiGrid(panelTheme),
                      const SizedBox(height: 16),
                      if (report.environment.isNotEmpty) ...[
                        _buildEnvironmentCard(panelTheme),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            size: 18,
                            color: panelTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Details (${report.totalTests})',
                            style: TextStyle(
                              color: panelTheme.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...report.allResults
                          .map((r) => _buildTestCard(context, r, panelTheme)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ScenarioPanelThemeData panelTheme) {
    final isSuccess = report.isSuccess;
    final bannerGradient = isSuccess
        ? const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: bannerGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.passedCount}/${report.totalTests} Passed (${report.successRate.toStringAsFixed(1)}%) \u2022 ${(report.duration.inMilliseconds / 1000).toStringAsFixed(2)}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(ScenarioPanelThemeData panelTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              'TOTAL',
              '${report.totalTests}',
              null,
              itemWidth,
              panelTheme,
              Icons.format_list_bulleted_rounded,
            ),
            _buildKpiCard(
              'PASSED',
              '${report.passedCount}',
              panelTheme.successColor,
              itemWidth,
              panelTheme,
              Icons.check_circle_outline_rounded,
            ),
            _buildKpiCard(
              'FAILED',
              '${report.failedCount}',
              panelTheme.errorColor,
              itemWidth,
              panelTheme,
              Icons.highlight_off_rounded,
            ),
            _buildKpiCard(
              'SKIPPED',
              '${report.skippedCount}',
              panelTheme.warningColor,
              itemWidth,
              panelTheme,
              Icons.do_not_disturb_on_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    String label,
    String value,
    Color? color,
    double width,
    ScenarioPanelThemeData panelTheme,
    IconData icon,
  ) {
    final accentColor = color ?? panelTheme.primaryColor;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: panelTheme.borderColor.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: panelTheme.subtitleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                icon,
                size: 15,
                color: accentColor.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? panelTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: panelTheme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 15,
                color: panelTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'ENVIRONMENT',
                style: TextStyle(
                  color: panelTheme.subtitleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.environment.entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: panelTheme.chipColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: panelTheme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    TestExecutionResult test,
    ScenarioPanelThemeData panelTheme,
  ) {
    final statusColor = test.isPassed
        ? panelTheme.successColor
        : (test.isFailed ? panelTheme.errorColor : panelTheme.warningColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: panelTheme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: test.isFailed,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            test.status.name.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),
        title: Text(
          test.name,
          style: TextStyle(
            color: panelTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Text(
          '${test.screen ?? "Standalone"} \u2022 ${test.duration.inMilliseconds}ms',
          style: TextStyle(
            color: panelTheme.subtitleColor,
            fontSize: 11,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (test.isFailed && test.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: panelTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: panelTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: panelTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'Error: ${test.errorMessage}',
                      style: TextStyle(
                        color: panelTheme.errorColor,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (test.stepResults.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'STEPS',
                  style: TextStyle(
                    color: panelTheme.subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...test.stepResults.map((s) => _buildStepRow(s, panelTheme)),
            const SizedBox(height: 12),
          ],
          if (test.assertions.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'ASSERTIONS',
                  style: TextStyle(
                    color: panelTheme.subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...test.assertions.map((a) => _buildAssertionRow(a, panelTheme)),
            const SizedBox(height: 12),
          ],
          if (test.screenshots.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'SCREENSHOTS',
                  style: TextStyle(
                    color: panelTheme.subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: test.screenshots
                  .map((s) => _buildScreenshotThumbnail(context, s, panelTheme))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow(
      StepExecutionResult step, ScenarioPanelThemeData panelTheme) {
    final statusColor = step.isPassed
        ? panelTheme.successColor
        : (step.isFailed ? panelTheme.errorColor : panelTheme.warningColor);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: panelTheme.chipColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            step.isPassed
                ? Icons.check_circle_rounded
                : (step.isFailed
                    ? Icons.cancel_rounded
                    : Icons.remove_circle_outline_rounded),
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(
                color: panelTheme.textColor,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${step.duration.inMilliseconds}ms',
            style: TextStyle(
              color: panelTheme.subtitleColor,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssertionRow(
      AssertionResult assertion, ScenarioPanelThemeData panelTheme) {
    final color =
        assertion.isSuccess ? panelTheme.successColor : panelTheme.errorColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assertion.isSuccess ? '\u2714' : '\u2718',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assertion.description,
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (assertion.isFailure && assertion.failureMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      assertion.failureMessage!,
                      style: TextStyle(
                        color: panelTheme.errorColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotThumbnail(
    BuildContext context,
    ScenarioScreenshot screenshot,
    ScenarioPanelThemeData panelTheme,
  ) {
    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
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
        width: 88,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: panelTheme.borderColor.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          screenshot.bytes,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// In-panel tab view displaying the executive test execution report matching the
/// ScenarioKit executive studio design.
class ScenarioReportView extends StatefulWidget {
  const ScenarioReportView({
    super.key,
    this.report,
    required this.theme,
    this.onGoToTests,
  });

  final ScenarioTestReport? report;
  final ScenarioPanelThemeData theme;
  final VoidCallback? onGoToTests;

  @override
  State<ScenarioReportView> createState() => _ScenarioReportViewState();
}

class _ScenarioReportViewState extends State<ScenarioReportView> {
  String _statusFilter = 'All'; // 'All', 'Failed', 'Passed'
  final Map<String, bool> _expandedTests = {};

  @override
  Widget build(BuildContext context) {
    final panelTheme = widget.theme;
    final report = widget.report;

    if (report == null || report.totalTests == 0) {
      return Container(
        color: panelTheme.backgroundColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: panelTheme.chipColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_outlined,
                size: 36,
                color: panelTheme.subtitleColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Test Report Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: panelTheme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Run automated functional tests in the Tests tab to inspect live KPI breakdowns, execution diagnostics, and failure analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: panelTheme.subtitleColor,
              ),
            ),
            if (widget.onGoToTests != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.onGoToTests,
                icon: const Icon(Icons.checklist_rounded, size: 16),
                label: const Text('Go to Tests Tab'),
                style: FilledButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final total = report.totalTests;
    final passed = report.passedCount;
    final failed = report.failedCount;
    final skipped = report.skippedCount;
    final passRate = total > 0 ? passed / total : 1.0;

    final filteredResults = report.allResults.where((r) {
      if (_statusFilter == 'Failed') return r.isFailed;
      if (_statusFilter == 'Passed') return r.isPassed;
      return true;
    }).toList();

    return Container(
      color: panelTheme.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          // Summary Header Box
          _buildSummaryBox(
              panelTheme, total, passed, failed, skipped, passRate, report),
          const SizedBox(height: 16),
          // Shared Cause Diagnostic Alert Banner
          if (failed > 0) ...[
            _buildSharedCauseAlert(panelTheme),
            const SizedBox(height: 18),
          ],
          // Test Details Section Header & Status Filters
          Row(
            children: [
              Text(
                'Test details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: panelTheme.textColor,
                ),
              ),
              const Spacer(),
              _buildFilterPills(panelTheme, total, passed, failed),
            ],
          ),
          const SizedBox(height: 12),
          // Test Result Cards
          ...filteredResults
              .map((r) => _buildReportTestCard(context, r, panelTheme)),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
    ScenarioPanelThemeData panelTheme,
    int total,
    int passed,
    int failed,
    int skipped,
    double passRate,
    ScenarioTestReport report,
  ) {
    final title = failed > 0 ? '$failed tests failed' : 'All tests passed!';
    final durationSec =
        (report.duration.inMilliseconds / 1000.0).toStringAsFixed(2);
    final screens =
        report.summaries.map((s) => s.screenName ?? 'App').toSet().join(', ');
    final subtitle = 'Run finished in ${durationSec}s across $screens';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: panelTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F14142B),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Donut Radial Chart
          _buildDonutChart(passed, total, passRate, panelTheme),
          const SizedBox(width: 20),
          // Metric Cards & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: panelTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: panelTheme.subtitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildKpiCard('Total', '$total', panelTheme.surfaceColor,
                        panelTheme.textColor, panelTheme.borderColor),
                    const SizedBox(width: 8),
                    _buildKpiCard('Passed', '$passed', const Color(0xFFEDF9F3),
                        const Color(0xFF0B6B43), const Color(0xFFBFE5D2)),
                    const SizedBox(width: 8),
                    _buildKpiCard('Failed', '$failed', const Color(0xFFFDECEA),
                        const Color(0xFFB42318), const Color(0xFFF3B4AE)),
                    const SizedBox(width: 8),
                    _buildKpiCard(
                        'Skipped',
                        '$skipped',
                        const Color(0xFFFEF6E4),
                        const Color(0xFF8A4B08),
                        const Color(0xFFF1D9A8)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Export buttons column
          Column(
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: const Text('Exporting report as HTML...'),
                      backgroundColor: panelTheme.primaryColor,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: const BorderSide(color: Color(0xFFDCDCEA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  foregroundColor: panelTheme.textColor,
                ),
                child: const Text('Export HTML',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: const Text('Exporting report as PDF...'),
                      backgroundColor: panelTheme.primaryColor,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Export PDF',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(int passed, int total, double passRate,
      ScenarioPanelThemeData panelTheme) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _DonutChartPainter(
          passed: passed,
          total: total,
          passColor: const Color(0xFF0B6B43),
          failColor: const Color(0xFFB42318),
        ),
        child: Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$passed/$total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: panelTheme.textColor,
                  ),
                ),
                Text(
                  '${(passRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: panelTheme.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String label, String value, Color bg, Color text, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: text.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedCauseAlert(ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6E4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1D9A8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF8A4B08), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Likely shared cause. Most failures are "widget not found" errors, and the failure screenshot shows the Dashboard while the test targets the Login screen. Check that each test switches to its own scenario before asserting.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF5E3606),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(
      ScenarioPanelThemeData panelTheme, int total, int passed, int failed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusFilterPill('All', 'All ($total)', panelTheme),
        const SizedBox(width: 6),
        _buildStatusFilterPill('Failed', 'Failed ($failed)', panelTheme),
        const SizedBox(width: 6),
        _buildStatusFilterPill('Passed', 'Passed ($passed)', panelTheme),
      ],
    );
  }

  Widget _buildStatusFilterPill(
      String filterKey, String label, ScenarioPanelThemeData panelTheme) {
    final isSelected = _statusFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _statusFilter = filterKey),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14142B) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF14142B)
                  : const Color(0xFFDCDCEA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : panelTheme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildReportTestCard(BuildContext context, TestExecutionResult result,
      ScenarioPanelThemeData panelTheme) {
    final isExpanded = _expandedTests[result.testId] ?? false;
    final isPass = result.isPassed;
    final durationMs = '${result.duration.inMilliseconds}ms';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPass ? const Color(0xFFE6E6F0) : const Color(0xFFF3B4AE),
        ),
        boxShadow: isExpanded
            ? const [
                BoxShadow(
                  color: Color(0x1414142B),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedTests[result.testId] = !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPass
                          ? const Color(0xFFEDF9F3)
                          : const Color(0xFFFDECEA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPass
                            ? const Color(0xFFBFE5D2)
                            : const Color(0xFFF3B4AE),
                      ),
                    ),
                    child: Text(
                      isPass ? 'PASSED' : 'FAILED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPass
                            ? const Color(0xFF0B6B43)
                            : const Color(0xFFB42318),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: panelTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${result.screen ?? "App"} · $durationMs',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: panelTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: panelTheme.subtitleColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isPass && result.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF3B4AE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error  ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8F1D13),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              result.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                color: Color(0xFF8F1D13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Steps list
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STEPS',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: panelTheme.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (result.stepResults.isEmpty)
                              Text(
                                'No steps recorded.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: panelTheme.subtitleColor),
                              )
                            else
                              ...result.stepResults
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final idx = entry.key;
                                final st = entry.value;
                                final isStepFail = st.isFailed;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7FB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isStepFail
                                              ? const Color(0xFFB42318)
                                              : (isPass || idx > 0
                                                  ? const Color(0xFFB9B9CC)
                                                  : const Color(0xFF0B6B43)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          st.description,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontFamily: 'monospace',
                                            color: panelTheme.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      if (result.screenshots.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        // Screenshot Column
                        SizedBox(
                          width: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCREENSHOT',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: panelTheme.subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _openScreenshotLightbox(
                                    context, result.screenshots.first),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7FB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFDCDCEA)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.zoom_in_rounded,
                                          size: 16, color: Color(0xFF3730A3)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Enlarge',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3730A3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openScreenshotLightbox(
      BuildContext context, ScenarioScreenshot screenshot) {
    showDialog<void>(
      context: context,
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
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.passed,
    required this.total,
    required this.passColor,
    required this.failColor,
  });

  final int passed;
  final int total;
  final Color passColor;
  final Color failColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final paintFail = Paint()
      ..color = failColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintPass = Paint()
      ..color = passColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw full fail circle
    canvas.drawCircle(center, radius - strokeWidth / 2, paintFail);

    // Draw pass slice if any
    if (total > 0 && passed > 0) {
      final sweepAngle = (passed / total) * 2 * 3.141592653589793;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -3.141592653589793 / 2,
        sweepAngle,
        false,
        paintPass,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.passed != passed || oldDelegate.total != total;
  }
}
