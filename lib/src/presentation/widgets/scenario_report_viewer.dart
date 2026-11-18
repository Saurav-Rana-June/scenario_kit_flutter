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
