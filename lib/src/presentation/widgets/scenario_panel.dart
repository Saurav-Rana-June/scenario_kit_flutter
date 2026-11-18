import 'package:flutter/material.dart';

import '../../core/scenario.dart';
import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_prototype_view.dart';
import 'scenario_report_viewer.dart';
import 'scenario_test_dashboard.dart';

/// Developer panel widget for searching, organizing, inspecting, and switching
/// between registered scenarios, automated functional tests, interactive prototype flows,
/// and executive test execution reports.
class ScenarioPanel extends StatefulWidget {
  /// Creates a [ScenarioPanel].
  const ScenarioPanel({
    super.key,
    this.controller,
    this.testRegistry,
    this.theme,
    this.onClose,
    this.showHeader = true,
    this.testExecutionContext,
    this.initialTab = ScenarioPanelTab.scenarios,
  });

  /// Explicit controller to bind to. If omitted, resolves from [ScenarioScope.of(context)].
  final ScenarioController? controller;

  /// Optional test registry. If omitted, resolves to ambient [ScenarioTestRegistry.instance].
  final ScenarioTestRegistry? testRegistry;

  /// Custom theme for the panel. Defaults to ambient dark or light theme.
  final ScenarioPanelThemeData? theme;

  /// Optional callback invoked when the user taps the close button.
  final VoidCallback? onClose;

  /// Whether to display the top title header. Defaults to `true`.
  final bool showHeader;

  /// Context under [ScenarioKit] used to run tests against the live app UI.
  final BuildContext? testExecutionContext;

  /// Initial tab to activate when the panel opens.
  final ScenarioPanelTab initialTab;

  @override
  State<ScenarioPanel> createState() => _ScenarioPanelState();
}

/// The 4 main studio sections in ScenarioKit.
enum ScenarioPanelTab { scenarios, tests, prototype, report }

class _ScenarioPanelState extends State<ScenarioPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroupFilter; // null means 'All'
  late ScenarioPanelTab _activeTab;
  String? _prototypeScenarioId;
  ScenarioTestReport? _activeReport;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _searchController.addListener(_onSearchChanged);
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

      return nameMatch || idMatch || descMatch || groupMatch;
    }).toList();
  }

  void _showMetadataDialog(
    BuildContext context,
    Scenario scenario,
    ScenarioPanelThemeData panelTheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                      color: panelTheme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          color: panelTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: panelTheme.textColor,
                            fontFamily: 'monospace',
                            fontSize: 12.5,
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: panelTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? ScenarioScope.of(context);
    final panelTheme = _resolveTheme(context);
    final testRegistry = widget.testRegistry ?? ScenarioTestRegistry.instance;
    final scenarios = controller.registry.scenarios;
    final totalTestCount = testRegistry.totalTestCount;

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
      child: Material(
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
                totalTestCount,
              ),
            ],
            Expanded(
              child: _buildActiveTabBody(
                context,
                controller,
                testRegistry,
                panelTheme,
                scenarios,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabBody(
    BuildContext context,
    ScenarioController controller,
    ScenarioTestRegistry testRegistry,
    ScenarioPanelThemeData panelTheme,
    List<Scenario> scenarios,
  ) {
    switch (_activeTab) {
      case ScenarioPanelTab.scenarios:
        return _buildScenariosView(context, controller, panelTheme, scenarios);

      case ScenarioPanelTab.tests:
        return ScenarioTestDashboard(
          registry: widget.testRegistry,
          theme: panelTheme,
          onClose: widget.onClose,
          executionContext: widget.testExecutionContext,
          onOpenReport: () =>
              setState(() => _activeTab = ScenarioPanelTab.report),
        );

      case ScenarioPanelTab.prototype:
        return ScenarioPrototypeView(
          controller: controller,
          testRegistry: widget.testRegistry,
          theme: panelTheme,
          initialScenarioId: _prototypeScenarioId,
        );

      case ScenarioPanelTab.report:
        return ScenarioReportView(
          report: _activeReport,
          theme: panelTheme,
          onGoToTests: () =>
              setState(() => _activeTab = ScenarioPanelTab.tests),
        );
    }
  }

  Widget _buildDragHandle(ScenarioPanelThemeData panelTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 2),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: panelTheme.subtitleColor.withValues(alpha: 0.3),
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
    int totalTestCount,
  ) {
    final reportBadgeCount = _activeReport != null
        ? (_activeReport!.failedCount > 0
            ? '${_activeReport!.failedCount}'
            : '${_activeReport!.totalTests}')
        : (totalTestCount > 0 ? '$totalTestCount' : '0');
    final hasFailedReports =
        _activeReport != null && _activeReport!.failedCount > 0;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: panelTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: panelTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ScenarioKit',
            style: TextStyle(
              color: panelTheme.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 20),
          // 4-Tab Capsule Switcher
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: panelTheme.chipColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      tabKey: const ValueKey('panel_tab_scenarios'),
                      label: 'Scenarios',
                      badge: '$scenariosCount',
                      isSelected: _activeTab == ScenarioPanelTab.scenarios,
                      onTap: () => setState(
                          () => _activeTab = ScenarioPanelTab.scenarios),
                      panelTheme: panelTheme,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      tabKey: const ValueKey('panel_tab_tests'),
                      label: 'Tests',
                      badge: '$totalTestCount',
                      isSelected: _activeTab == ScenarioPanelTab.tests,
                      onTap: () =>
                          setState(() => _activeTab = ScenarioPanelTab.tests),
                      panelTheme: panelTheme,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      tabKey: const ValueKey('panel_tab_prototype'),
                      label: 'Prototype',
                      badge: 'New',
                      isSelected: _activeTab == ScenarioPanelTab.prototype,
                      onTap: () => setState(
                          () => _activeTab = ScenarioPanelTab.prototype),
                      panelTheme: panelTheme,
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      tabKey: const ValueKey('panel_tab_report'),
                      label: 'Report',
                      badge: reportBadgeCount,
                      isBad: hasFailedReports,
                      isSelected: _activeTab == ScenarioPanelTab.report,
                      onTap: () =>
                          setState(() => _activeTab = ScenarioPanelTab.report),
                      panelTheme: panelTheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reset button
          IconButton(
            tooltip: 'Reset to default scenario',
            style: IconButton.styleFrom(
              fixedSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: panelTheme.borderColor),
              ),
              backgroundColor: Colors.white,
            ),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 18,
              color: panelTheme.textColor,
            ),
            onPressed: controller.resetToDefault,
          ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Close ScenarioKit',
              style: IconButton.styleFrom(
                fixedSize: const Size(40, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: panelTheme.borderColor),
                ),
                backgroundColor: Colors.white,
              ),
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: panelTheme.textColor,
              ),
              onPressed: widget.onClose,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required Key tabKey,
    required String label,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
    required ScenarioPanelThemeData panelTheme,
    bool isBad = false,
  }) {
    final textColor =
        isSelected ? panelTheme.primaryColor : const Color(0xFF3A3A55);
    final badgeBg = isBad
        ? const Color(0xFFFDECEA)
        : (isSelected ? const Color(0xFFE8E9FF) : const Color(0xFFDCDCEA));
    final badgeText = isBad
        ? const Color(0xFFB42318)
        : (isSelected ? const Color(0xFF3730A3) : const Color(0xFF3A3A55));

    return InkWell(
      key: tabKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x2614142B),
                    blurRadius: 3,
                    offset: Offset(0, 1),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosView(
    BuildContext context,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
    List<Scenario> scenarios,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filtered = _filterScenarios(scenarios);
        final groups = controller.registry.groups;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(panelTheme),
            if (groups.isNotEmpty)
              _buildGroupFilters(groups, scenarios.length, panelTheme),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyResults(panelTheme)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final useTwoColumns = constraints.maxWidth >= 600;
                        if (useTwoColumns) {
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            cacheExtent: 1000,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 290,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final scenario = filtered[index];
                              return _buildScenarioCard(
                                context,
                                scenario,
                                controller.isSelected(scenario),
                                controller,
                                panelTheme,
                              );
                            },
                          );
                        } else {
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            cacheExtent: 1000,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final scenario = filtered[index];
                              return _buildScenarioCard(
                                context,
                                scenario,
                                controller.isSelected(scenario),
                                controller,
                                panelTheme,
                              );
                            },
                          );
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(ScenarioPanelThemeData panelTheme) {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCDCEA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF5B5B73),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 15,
                color: panelTheme.textColor,
              ),
              decoration: const InputDecoration(
                hintText: 'Search scenarios by name, ID, group, or tag',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5B5B73),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded,
                  size: 16, color: Color(0xFF5B5B73)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: () => _searchController.clear(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEF6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '/',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF5B5B73),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupFilters(
    List<String> groups,
    int totalCount,
    ScenarioPanelThemeData panelTheme,
  ) {
    final allGroups = ['All', ...groups];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: allGroups.map((g) {
          final isAll = g == 'All';
          final isSelected =
              isAll ? _selectedGroupFilter == null : _selectedGroupFilter == g;
          final count = isAll
              ? totalCount
              : (widget.controller?.registry.scenarios
                      .where((s) => s.group?.trim() == g)
                      .length ??
                  0);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: ValueKey('filter_chip_$g'),
              onTap: () {
                setState(() {
                  _selectedGroupFilter = isAll ? null : g;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? panelTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? panelTheme.primaryColor
                        : const Color(0xFFDCDCEA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : panelTheme.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFEEEEF6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : panelTheme.subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
      onTap: () => controller.selectById(scenario.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? panelTheme.primaryColor : const Color(0xFFE6E6F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A14142B),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scenario.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: panelTheme.textColor,
                        ),
                      ),
                    ),
                    if (scenario.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEF6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Color(0xFF3A3A55),
                          ),
                        ),
                      ),
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: panelTheme.primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  scenario.description ?? 'No description provided.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF4A4A63),
                  ),
                ),
                const SizedBox(height: 10),
                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // ID pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEF6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scenario.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF3A3A55),
                        ),
                      ),
                    ),
                    // Group pill
                    if (scenario.group != null &&
                        scenario.group!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEF6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scenario.group!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3A3A55),
                          ),
                        ),
                      ),
                    // Meta pill
                    if (scenario.metadata.isNotEmpty)
                      InkWell(
                        onTap: () =>
                            _showMetadataDialog(context, scenario, panelTheme),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E9FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'meta (${scenario.metadata.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3730A3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Apply / Applied
                    if (isSelected)
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xFFC9CBFF)),
                        ),
                        child: const Text(
                          'Applied',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () => controller.selectById(scenario.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: panelTheme.primaryColor,
                          foregroundColor: Colors.white,
                          fixedSize: const Size.fromHeight(36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text('Apply scenario',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    // Open in Prototype
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _prototypeScenarioId = scenario.id;
                          _activeTab = ScenarioPanelTab.prototype;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        fixedSize: const Size.fromHeight(36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        side: const BorderSide(color: Color(0xFFDCDCEA)),
                        foregroundColor: const Color(0xFF14142B),
                      ),
                      child: const Text('Open in Prototype',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResults(ScenarioPanelThemeData panelTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: panelTheme.subtitleColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No scenarios match your search',
              style: TextStyle(
                color: panelTheme.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term or clear the filter',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
