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
    final panelTheme = theme ?? ScenarioPanelThemeData.dark();

    return Dialog(
      backgroundColor: panelTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: panelTheme.borderRadius,
        side: BorderSide(color: panelTheme.borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(context, panelTheme),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKpiGrid(panelTheme),
                    const SizedBox(height: 20),
                    if (report.environment.isNotEmpty) ...[
                      _buildEnvironmentCard(panelTheme),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'Test Details (${report.totalTests})',
                      style: TextStyle(
                        color: panelTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    );
  }

  Widget _buildHeader(BuildContext context, ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: panelTheme.borderRadius.topLeft,
          topRight: panelTheme.borderRadius.topRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            report.isSuccess ? Icons.check_circle : Icons.error,
            color: report.isSuccess
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${report.passedCount}/${report.totalTests} Passed (${report.successRate.toStringAsFixed(1)}%) \u2022 ${(report.duration.inMilliseconds / 1000).toStringAsFixed(2)}s',
                  style: TextStyle(
                    color: panelTheme.subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: panelTheme.subtitleColor),
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
                'Total', '${report.totalTests}', null, itemWidth, panelTheme),
            _buildKpiCard('Passed', '${report.passedCount}',
                const Color(0xFF22C55E), itemWidth, panelTheme),
            _buildKpiCard('Failed', '${report.failedCount}',
                const Color(0xFFEF4444), itemWidth, panelTheme),
            _buildKpiCard('Skipped', '${report.skippedCount}',
                const Color(0xFFF59E0B), itemWidth, panelTheme),
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
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: panelTheme.subtitleColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? panelTheme.textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: panelTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENVIRONMENT',
            style: TextStyle(
              color: panelTheme.subtitleColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.environment.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: panelTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: panelTheme.borderColor),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    color: panelTheme.subtitleColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
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
        ? const Color(0xFF22C55E)
        : (test.isFailed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

    return Card(
      color: panelTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: panelTheme.borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: test.isFailed,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            test.status.name.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          test.name,
          style: TextStyle(
            color: panelTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${test.screen ?? "Standalone"} \u2022 ${test.duration.inMilliseconds}ms',
          style: TextStyle(color: panelTheme.subtitleColor, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (test.isFailed && test.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                'Error: ${test.errorMessage}',
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (test.stepResults.isNotEmpty) ...[
            Text(
              'STEPS',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...test.stepResults.map((s) => _buildStepRow(s, panelTheme)),
            const SizedBox(height: 12),
          ],
          if (test.assertions.isNotEmpty) ...[
            Text(
              'ASSERTIONS',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...test.assertions.map((a) => _buildAssertionRow(a, panelTheme)),
            const SizedBox(height: 12),
          ],
          if (test.screenshots.isNotEmpty) ...[
            Text(
              'SCREENSHOTS',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
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
        ? const Color(0xFF22C55E)
        : (step.isFailed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            step.isPassed
                ? Icons.check
                : (step.isFailed ? Icons.close : Icons.remove),
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(color: panelTheme.textColor, fontSize: 12),
            ),
          ),
          Text(
            '${step.duration.inMilliseconds}ms',
            style: TextStyle(color: panelTheme.subtitleColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAssertionRow(
      AssertionResult assertion, ScenarioPanelThemeData panelTheme) {
    final color =
        assertion.isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assertion.isSuccess ? '\u2714' : '\u2718',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assertion.description,
                  style: TextStyle(color: panelTheme.textColor, fontSize: 12),
                ),
                if (assertion.isFailure && assertion.failureMessage != null)
                  Text(
                    assertion.failureMessage!,
                    style:
                        const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
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
            child: InteractiveViewer(
              child: Image.memory(
                screenshot.bytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: panelTheme.borderColor),
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
