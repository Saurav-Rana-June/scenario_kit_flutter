import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/scenario.dart';
import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/html_report_exporter.dart';
import '../../testing/reporting/json_report_exporter.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
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

  /// Explicit controller to bind to. If omitted, resolves from [ScenarioScope.of(context)].
  final ScenarioController? controller;

  /// Optional test registry. If omitted, resolves to ambient [ScenarioTestRegistry.instance].
  final ScenarioTestRegistry? testRegistry;

  /// Optional report store. If omitted, resolves to ambient [ScenarioReportStore.instance].
  final ScenarioReportStore? reportStore;

  /// Custom theme for the panel. Defaults to ambient clean light theme.
  final ScenarioPanelThemeData? theme;

  /// Optional callback invoked when the user taps the close button.
  final VoidCallback? onClose;

  /// Whether to display the top title header. Defaults to `true`.
  final bool showHeader;

  /// Context under [ScenarioKit] used to run tests against the live app UI
  /// (not the modal sheet). Pass from [ScenarioFloatingTrigger] when embedded
  /// in a bottom sheet.
  final BuildContext? testExecutionContext;

  /// Active screen name for Test Mode (see [ScenarioKit.screenName]).
  final String? screenName;

  /// Invoked when the user taps **Go to Screen** in Test Mode.
  final void Function(String screenName)? onNavigateToScreen;

  @override
  State<ScenarioPanel> createState() => _ScenarioPanelState();
}

enum _PanelTab { scenarios, tests, reports }

class _ScenarioPanelState extends State<ScenarioPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroupFilter; // null means 'All'
  _PanelTab _activeTab = _PanelTab.scenarios;
  late final ScenarioReportStore _reportStore;

  @override
  void initState() {
    super.initState();
    _reportStore = widget.reportStore ?? ScenarioReportStore.instance;
    _reportStore.addListener(_onStoreChanged);
    _searchController.addListener(_onSearchChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  @override
  void dispose() {
    _reportStore.removeListener(_onStoreChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  ScenarioPanelThemeData _resolveTheme(BuildContext context) {
    return widget.theme ?? ScenarioPanelThemeData.light();
  }

  List<Scenario> _filterScenarios(List<Scenario> all) {
    return all.where((scenario) {
      if (_selectedGroupFilter != null) {
        if (scenario.group?.trim() != _selectedGroupFilter) {
          return false;
        }
      }

      if (_searchQuery.isEmpty) return true;

      final nameMatch = scenario.name.toLowerCase().contains(_searchQuery);
      final idMatch = scenario.id.toLowerCase().contains(_searchQuery);
      final descMatch =
          scenario.description?.toLowerCase().contains(_searchQuery) ?? false;
      final groupMatch =
          scenario.group?.toLowerCase().contains(_searchQuery) ?? false;
      final tagMatch =
          scenario.tags.any((t) => t.toLowerCase().contains(_searchQuery));

      return nameMatch || idMatch || descMatch || groupMatch || tagMatch;
    }).toList();
  }

  void _showMetadataDialog(
    BuildContext context,
    Scenario scenario,
    ScenarioPanelThemeData panelTheme,
  ) {
    showDialog<void>(
      context: context,
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
      context: context,
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

    final lightMaterialTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: panelTheme.primaryColor,
        surface: panelTheme.surfaceColor,
        onSurface: panelTheme.textColor,
      ),
      scaffoldBackgroundColor: panelTheme.backgroundColor,
      useMaterial3: true,
    );

    return Theme(
      data: lightMaterialTheme,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final scenarios = controller.registry.scenarios;
          final testRegistry = widget.testRegistry ?? ScenarioTestRegistry.instance;

          return Material(
            color: panelTheme.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader) ...[
                  _buildDragHandle(panelTheme),
                  _buildHeader(
                    context,
                    controller,
                    panelTheme,
                    scenarios.length,
                    testRegistry.totalTestCount,
                  ),
                ],
                Expanded(
                  child: _buildActiveTabBody(
                    context,
                    controller,
                    scenarios,
                    panelTheme,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTabBody(
    BuildContext context,
    ScenarioController controller,
    List<Scenario> scenarios,
    ScenarioPanelThemeData panelTheme,
  ) {
    switch (_activeTab) {
      case _PanelTab.scenarios:
        final filtered = _filterScenarios(scenarios);
        final groups = controller.registry.groups;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(panelTheme),
            if (groups.isNotEmpty)
              _buildGroupFilters(groups, panelTheme, scenarios),
            Divider(
              height: 1,
              thickness: 1,
              color: panelTheme.borderColor.withValues(alpha: 0.6),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyResults(panelTheme)
                  : _buildScenariosGrid(
                      context,
                      filtered,
                      controller,
                      panelTheme,
                    ),
            ),
          ],
        );

      case _PanelTab.tests:
        return ScenarioTestDashboard(
          registry: widget.testRegistry,
          theme: panelTheme,
          onClose: widget.onClose,
          executionContext: widget.testExecutionContext,
          currentScreenName: widget.screenName ??
              ScenarioScope.maybeActiveScreenNameOf(context),
          onNavigateToScreen: widget.onNavigateToScreen ??
              ScenarioScope.maybeNavigateToScreenOf(context),
          onViewReport: () => setState(() => _activeTab = _PanelTab.reports),
        );

      case _PanelTab.reports:
        return ScenarioReportsTab(
          reportStore: _reportStore,
          theme: panelTheme,
          onSwitchToTests: () => setState(() => _activeTab = _PanelTab.tests),
        );
    }
  }

  Widget _buildDragHandle(ScenarioPanelThemeData panelTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
    int scenariosCount,
    int testsCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 820;

        if (isCompact) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
            decoration: BoxDecoration(
              color: panelTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: panelTheme.borderColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildBrandLogo(panelTheme),
                    const SizedBox(width: 8),
                    _buildBrandTitle(panelTheme),
                    const Spacer(),
                    _buildHeaderActions(context, controller, panelTheme),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSegmentedTabBar(panelTheme, scenariosCount, testsCount),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          decoration: BoxDecoration(
            color: panelTheme.surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: panelTheme.borderColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildBrandLogo(panelTheme),
              const SizedBox(width: 8),
              _buildBrandTitle(panelTheme),
              const SizedBox(width: 14),
              _buildSegmentedTabBar(panelTheme, scenariosCount, testsCount),
              const Spacer(),
              _buildHeaderActions(context, controller, panelTheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandLogo(ScenarioPanelThemeData panelTheme) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: panelTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.tune_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBrandTitle(ScenarioPanelThemeData panelTheme) {
    return Text(
      'ScenarioKit',
      style: TextStyle(
        color: panelTheme.textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('panel_export_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: panelTheme.textColor,
            side: BorderSide(color: panelTheme.borderColor),
            backgroundColor: panelTheme.surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.file_download_outlined, size: 14),
          label: const Text('Export', style: TextStyle(fontSize: 12)),
          onPressed: () => _handleExportReport(context, panelTheme),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Reset to default scenario',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(
            backgroundColor: panelTheme.surfaceColor,
            side: BorderSide(color: panelTheme.borderColor),
            padding: const EdgeInsets.all(6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(
            Icons.restart_alt_rounded,
            size: 16,
            color: panelTheme.subtitleColor,
          ),
          onPressed: controller.resetToDefault,
        ),
        if (widget.onClose != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Close panel',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: panelTheme.surfaceColor,
              side: BorderSide(color: panelTheme.borderColor),
              padding: const EdgeInsets.all(6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: panelTheme.subtitleColor,
            ),
            onPressed: widget.onClose,
          ),
        ],
      ],
    );
  }

  Widget _buildSegmentedTabBar(
    ScenarioPanelThemeData panelTheme,
    int scenariosCount,
    int testsCount,
  ) {
    final reportCount = _reportStore.totalFailures > 0
        ? _reportStore.totalFailures
        : _reportStore.runs.length;

    return Container(
      decoration: BoxDecoration(
        color: panelTheme.chipColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentTab(
            key: const ValueKey('panel_tab_scenarios'),
            label: 'Scenarios',
            count: scenariosCount,
            isSelected: _activeTab == _PanelTab.scenarios,
            panelTheme: panelTheme,
            onTap: () => setState(() => _activeTab = _PanelTab.scenarios),
          ),
          const SizedBox(width: 2),
          _buildSegmentTab(
            key: const ValueKey('panel_tab_tests'),
            label: 'Tests',
            count: testsCount,
            isSelected: _activeTab == _PanelTab.tests,
            panelTheme: panelTheme,
            onTap: () => setState(() => _activeTab = _PanelTab.tests),
          ),
          const SizedBox(width: 2),
          _buildSegmentTab(
            key: const ValueKey('panel_tab_reports'),
            label: 'Reports',
            count: reportCount,
            isSelected: _activeTab == _PanelTab.reports,
            panelTheme: panelTheme,
            isWarningBadge: _reportStore.totalFailures > 0,
            onTap: () => setState(() => _activeTab = _PanelTab.reports),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required Key key,
    required String label,
    required int count,
    required bool isSelected,
    required ScenarioPanelThemeData panelTheme,
    required VoidCallback onTap,
    bool isWarningBadge = false,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? panelTheme.textColor : panelTheme.subtitleColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isWarningBadge
                      ? const Color(0xFFFEE2E2)
                      : (isSelected
                          ? panelTheme.chipColor
                          : Colors.white.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isWarningBadge
                        ? const Color(0xFFDC2626)
                        : (isSelected
                            ? panelTheme.primaryColor
                            : panelTheme.subtitleColor),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ScenarioPanelThemeData panelTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: panelTheme.textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search scenarios by name, ID, group, or tag',
          hintStyle: TextStyle(
            color: panelTheme.subtitleColor.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: panelTheme.subtitleColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: panelTheme.subtitleColor,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.chipColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: panelTheme.borderColor),
                    ),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 11,
                        color: panelTheme.subtitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          filled: true,
          fillColor: panelTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: panelTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: panelTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: panelTheme.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupFilters(
    List<String> groups,
    ScenarioPanelThemeData panelTheme,
    List<Scenario> allScenarios,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            count: allScenarios.length,
            isSelected: _selectedGroupFilter == null,
            onTap: () {
              setState(() {
                _selectedGroupFilter = null;
              });
            },
            panelTheme: panelTheme,
          ),
          for (final group in groups) ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              label: group,
              count: allScenarios.where((s) => s.group == group).length,
              isSelected: _selectedGroupFilter == group,
              onTap: () {
                setState(() {
                  _selectedGroupFilter = group;
                });
              },
              panelTheme: panelTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required ScenarioPanelThemeData panelTheme,
  }) {
    return InkWell(
      key: ValueKey('filter_chip_$label'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? panelTheme.primaryColor : panelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? panelTheme.primaryColor : panelTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : panelTheme.textColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : panelTheme.chipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : panelTheme.subtitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(ScenarioPanelThemeData panelTheme) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panelTheme.chipColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 32,
                color: panelTheme.subtitleColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching scenarios',
              style: TextStyle(
                color: panelTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search keyword or filter.',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosGrid(
    BuildContext context,
    List<Scenario> scenarios,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 200,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              final isSelected = controller.isSelected(scenario);
              return _buildScenarioCard(
                context,
                scenario,
                isSelected,
                controller,
                panelTheme,
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: scenarios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final scenario = scenarios[index];
            final isSelected = controller.isSelected(scenario);
            return _buildScenarioCard(
              context,
              scenario,
              isSelected,
              controller,
              panelTheme,
            );
          },
        );
      },
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    Scenario scenario,
    bool isSelected,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
  ) {
    return InkWell(
      onTap: () => controller.select(scenario),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? panelTheme.primaryColor : panelTheme.borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? panelTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.name,
                    style: TextStyle(
                      color: panelTheme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (scenario.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.chipColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: panelTheme.borderColor),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: panelTheme.subtitleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (scenario.description != null &&
                scenario.description!.trim().isNotEmpty) ...[
              Text(
                scenario.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: panelTheme.subtitleColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: panelTheme.chipColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    scenario.id,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: panelTheme.subtitleColor,
                    ),
                  ),
                ),
                if (scenario.group != null && scenario.group!.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.chipColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scenario.group!,
                      style: TextStyle(
                        fontSize: 11,
                        color: panelTheme.subtitleColor,
                      ),
                    ),
                  ),
                if (scenario.metadata.isNotEmpty)
                  InkWell(
                    onTap: () => _showMetadataDialog(context, scenario, panelTheme),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: panelTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'meta (${scenario.metadata.length})',
                        style: TextStyle(
                          fontSize: 11,
                          color: panelTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isSelected)
                  OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: panelTheme.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Applied',
                      style: TextStyle(
                        fontSize: 11,
                        color: panelTheme.subtitleColor,
                      ),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: () => controller.select(scenario),
                    style: FilledButton.styleFrom(
                      backgroundColor: panelTheme.primaryColor,
                      foregroundColor: panelTheme.onPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply scenario', style: TextStyle(fontSize: 11)),
                  ),
                OutlinedButton(
                  onPressed: () {
                    controller.select(scenario);
                    widget.onClose?.call();
                  },
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
                  child: const Text('Apply and preview', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
