import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/scenario.dart';
import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/html_report_exporter.dart';
import '../../testing/reporting/json_report_exporter.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../utils/scenario_panel_host.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_kit_mappers.dart';
import 'scenario_kit_ui.dart';
import 'scenario_report_viewer.dart';
import 'scenario_reports_tab.dart';
import 'scenario_test_dashboard.dart';

/// Developer panel widget for searching, organizing, inspecting, and switching
/// between registered scenarios, executing in-app tests, and reviewing test reports.
class ScenarioPanel extends StatefulWidget {
  /// Creates a [ScenarioPanel].
  const ScenarioPanel({
    super.key,
    this.controller,
    this.testRegistry,
    this.reportStore,
    this.theme,
    this.onClose,
    this.showHeader = true,
    this.testExecutionContext,
    this.screenName,
    this.onNavigateToScreen,
  });

  final ScenarioController? controller;
  final ScenarioTestRegistry? testRegistry;
  final ScenarioReportStore? reportStore;
  final ScenarioPanelThemeData? theme;
  final VoidCallback? onClose;
  final bool showHeader;
  final BuildContext? testExecutionContext;
  final String? screenName;
  final void Function(String screenName)? onNavigateToScreen;

  @override
  State<ScenarioPanel> createState() => _ScenarioPanelState();
}

class _ScenarioPanelState extends State<ScenarioPanel> {
  SkTab _activeTab = SkTab.scenarios;
  late final ScenarioReportStore _reportStore;

  @override
  void initState() {
    super.initState();
    _reportStore = widget.reportStore ?? ScenarioReportStore.instance;
    _reportStore.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _reportStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  ScenarioPanelThemeData _resolveTheme(BuildContext context) {
    return widget.theme ?? ScenarioPanelThemeData.light();
  }

  void _showMetadataDialog(
    BuildContext context,
    Scenario scenario,
    ScenarioPanelThemeData panelTheme,
  ) {
    showDialog<void>(
      context: ScenarioPanelHost.modalContext(context),
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: panelTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: panelTheme.borderRadius,
            side: BorderSide(color: panelTheme.borderColor),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: panelTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.data_object_rounded,
                  size: 18,
                  color: panelTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${scenario.name} Metadata',
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: scenario.metadata.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: panelTheme.chipColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: panelTheme.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          color: panelTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: panelTheme.textColor,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor:
                    panelTheme.primaryColor.withValues(alpha: 0.15),
                foregroundColor: panelTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleExportReport(
    BuildContext context,
    ScenarioPanelThemeData panelTheme,
  ) {
    final summary = _reportStore.latestSummary;
    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No test runs to export yet. Run tests first.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final report = ScenarioTestReport.fromSummaries(
      title: 'In-App Test Report',
      summaries: [summary],
    );

    showModalBottomSheet<void>(
      context: ScenarioPanelHost.modalContext(context),
      useRootNavigator: true,
      backgroundColor: panelTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: panelTheme.subtitleColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Copy JSON Report'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final json = const JsonReportExporter().export(report);
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON Report copied')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.html_rounded),
                  title: const Text('Copy HTML Report'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final html = const HtmlReportExporter().export(report);
                    Clipboard.setData(ClipboardData(text: html));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HTML Report copied')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('View Full Report Dialog'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    ScenarioReportViewerDialog.show(
                      context,
                      report: report,
                      theme: panelTheme,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? ScenarioScope.of(context);
    final panelTheme = _resolveTheme(context);
    final testRegistry = widget.testRegistry ?? ScenarioTestRegistry.instance;

    final reportBadge = _reportStore.totalFailures > 0
        ? '${_reportStore.totalFailures}'
        : '${_reportStore.runs.length}';

    return SkTheme(
      data: panelTheme,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, _reportStore]),
        builder: (context, _) {
          final scenarios = controller.registry.scenarios;
          final skScenarios =
              scenarios.map(mapScenarioToSkItem).toList(growable: false);

          Widget body;
          switch (_activeTab) {
            case SkTab.scenarios:
              body = SkScenariosTab(
                scenarios: skScenarios,
                activeId: controller.selectedId,
                onApply: (id) => controller.selectById(id),
                onApplyAndPreview: (id) {
                  controller.selectById(id);
                  widget.onClose?.call();
                },
                onShowMeta: (id) {
                  final scenario = controller.registry.getById(id);
                  if (scenario != null) {
                    _showMetadataDialog(context, scenario, panelTheme);
                  }
                },
              );
              break;
            case SkTab.tests:
              body = ScenarioTestDashboard(
                registry: widget.testRegistry,
                theme: panelTheme,
                onClose: widget.onClose,
                executionContext: widget.testExecutionContext,
                currentScreenName: widget.screenName ??
                    ScenarioScope.maybeActiveScreenNameOf(context),
                onNavigateToScreen: widget.onNavigateToScreen ??
                    ScenarioScope.maybeNavigateToScreenOf(context),
                onViewReport: () => setState(() => _activeTab = SkTab.reports),
              );
              break;
            case SkTab.reports:
              body = ScenarioReportsTab(
                reportStore: _reportStore,
                theme: panelTheme,
                onSwitchToTests: () => setState(() => _activeTab = SkTab.tests),
              );
              break;
          }

          if (!widget.showHeader) {
            return body;
          }

          return SkSheet(
            activeTab: _activeTab,
            onTabChanged: (t) => setState(() => _activeTab = t),
            scenarioCount: scenarios.length,
            testCount: testRegistry.totalTestCount,
            reportBadge: reportBadge,
            reportHasFailures: _reportStore.totalFailures > 0,
            onExport: () => _handleExportReport(context, panelTheme),
            onReset: controller.resetToDefault,
            onClose: widget.onClose,
            child: body,
          );
        },
      ),
    );
  }
}