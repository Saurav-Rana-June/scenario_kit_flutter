import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../testing/reporting/html_report_exporter.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../testing/runner/screen_execution_summary.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_kit_mappers.dart';
import 'scenario_kit_ui.dart';
import 'scenario_report_viewer.dart';

/// Dedicated Reports tab inside the ScenarioKit developer bottom sheet.
class ScenarioReportsTab extends StatefulWidget {
  const ScenarioReportsTab({
    super.key,
    this.reportStore,
    this.theme,
    this.onSwitchToTests,
  });

  final ScenarioReportStore? reportStore;
  final ScenarioPanelThemeData? theme;
  final VoidCallback? onSwitchToTests;

  @override
  State<ScenarioReportsTab> createState() => _ScenarioReportsTabState();
}

class _ScenarioReportsTabState extends State<ScenarioReportsTab> {
  late final ScenarioReportStore _store;

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

  ScenarioTestReport? _reportFor(ScreenExecutionSummary summary) {
    return ScenarioTestReport.fromSummaries(
      title: 'In-App Test Report',
      summaries: [summary],
    );
  }

  void _copyHtml(BuildContext context) {
    final summary = _store.latestSummary;
    if (summary == null) return;
    final report = _reportFor(summary);
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

  void _exportPdf(BuildContext context, ScenarioPanelThemeData theme) {
    final summary = _store.latestSummary;
    if (summary == null) return;
    final report = _reportFor(summary);
    if (report == null) return;
    ScenarioReportViewerDialog.show(
      context,
      report: report,
      theme: theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = _resolveTheme();
    final summary = _store.latestSummary;
    final skReport = mapSummaryToSkReport(summary);

    return SkTheme(
      data: panelTheme,
      child: SkReportsTab(
      report: skReport,
      emptyMessage:
          'Run tests from the Tests tab to inspect execution results, step traces, and exports here.',
      onSwitchToTests: widget.onSwitchToTests,
      onExport: (format) {
        switch (format) {
          case SkExportFormat.html:
            _copyHtml(context);
            break;
          case SkExportFormat.pdf:
            _exportPdf(context, panelTheme);
            break;
        }
      },
    ),
    );
  }
}