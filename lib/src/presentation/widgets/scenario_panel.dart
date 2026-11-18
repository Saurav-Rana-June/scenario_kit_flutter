import 'package:flutter/material.dart';

import '../../core/scenario.dart';
import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_test_dashboard.dart';

/// Developer panel widget for searching, organizing, inspecting, and switching
/// between registered scenarios.
class ScenarioPanel extends StatefulWidget {
  /// Creates a [ScenarioPanel].
  const ScenarioPanel({
    super.key,
    this.controller,
    this.testRegistry,
    this.theme,
    this.onClose,
    this.showHeader = true,
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

  @override
  State<ScenarioPanel> createState() => _ScenarioPanelState();
}

enum _PanelTab { scenarios, tests }

class _ScenarioPanelState extends State<ScenarioPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroupFilter; // null means 'All'
  _PanelTab _activeTab = _PanelTab.scenarios;

  @override
  void initState() {
    super.initState();
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
    if (widget.theme != null) return widget.theme!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? ScenarioPanelThemeData.dark()
        : ScenarioPanelThemeData.light();
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? ScenarioScope.of(context);
    final panelTheme = _resolveTheme(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scenarios = controller.registry.scenarios;
        final filtered = _filterScenarios(scenarios);
        final groups = controller.registry.groups;

        if (_activeTab == _PanelTab.tests) {
          return Material(
            color: panelTheme.backgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader) ...[
                  _buildDragHandle(panelTheme),
                  _buildHeader(
                      context, controller, panelTheme, scenarios.length),
                ],
                Flexible(
                  child: ScenarioTestDashboard(
                    registry: widget.testRegistry,
                    theme: panelTheme,
                    onClose: widget.onClose,
                  ),
                ),
              ],
            ),
          );
        }

        return Material(
          color: panelTheme.backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showHeader) ...[
                _buildDragHandle(panelTheme),
                _buildHeader(context, controller, panelTheme, scenarios.length),
              ],
              _buildSearchBar(panelTheme),
              if (groups.isNotEmpty) _buildGroupFilters(groups, panelTheme),
              Divider(
                height: 1,
                thickness: 1,
                color: panelTheme.borderColor.withValues(alpha: 0.6),
              ),
              Flexible(
                child: filtered.isEmpty
                    ? _buildEmptyResults(panelTheme)
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final scenario = filtered[index];
                          final isSelected = controller.isSelected(scenario);
                          return _buildScenarioCard(
                            context,
                            scenario,
                            isSelected,
                            controller,
                            panelTheme,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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
    int totalCount,
  ) {
    final testRegistry = widget.testRegistry ?? ScenarioTestRegistry.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 10),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: panelTheme.borderColor.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  panelTheme.primaryColor,
                  panelTheme.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: panelTheme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ScenarioKit',
            style: TextStyle(
              color: panelTheme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: panelTheme.chipColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: panelTheme.borderColor.withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              '$totalCount',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (testRegistry.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: panelTheme.chipColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: panelTheme.borderColor.withValues(alpha: 0.7),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    key: const ValueKey('panel_tab_scenarios'),
                    onTap: () =>
                        setState(() => _activeTab = _PanelTab.scenarios),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _activeTab == _PanelTab.scenarios
                            ? panelTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _activeTab == _PanelTab.scenarios
                            ? [
                                BoxShadow(
                                  color: panelTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_rounded,
                            size: 11,
                            color: _activeTab == _PanelTab.scenarios
                                ? panelTheme.onPrimaryColor
                                : panelTheme.subtitleColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Scenarios',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == _PanelTab.scenarios
                                  ? panelTheme.onPrimaryColor
                                  : panelTheme.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    key: const ValueKey('panel_tab_tests'),
                    onTap: () => setState(() => _activeTab = _PanelTab.tests),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _activeTab == _PanelTab.tests
                            ? panelTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _activeTab == _PanelTab.tests
                            ? [
                                BoxShadow(
                                  color: panelTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 12,
                            color: _activeTab == _PanelTab.tests
                                ? panelTheme.onPrimaryColor
                                : panelTheme.subtitleColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Tests (${testRegistry.totalTestCount})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == _PanelTab.tests
                                  ? panelTheme.onPrimaryColor
                                  : panelTheme.subtitleColor,
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
          const Spacer(),
          IconButton(
            tooltip: 'Reset to default scenario',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: panelTheme.chipColor.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(6),
            ),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: panelTheme.subtitleColor,
            ),
            onPressed: controller.resetToDefault,
          ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Close panel',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              style: IconButton.styleFrom(
                backgroundColor: panelTheme.chipColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(6),
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
          hintText: 'Search scenarios by name, ID, or tag...',
          hintStyle: TextStyle(
            color: panelTheme.subtitleColor.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: panelTheme.primaryColor.withValues(alpha: 0.8),
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
              : null,
          isDense: true,
          filled: true,
          fillColor: panelTheme.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: panelTheme.borderColor.withValues(alpha: 0.8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: panelTheme.borderColor.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: _selectedGroupFilter == null,
            onTap: () {
              setState(() {
                _selectedGroupFilter = null;
              });
            },
            panelTheme: panelTheme,
          ),
          for (final group in groups) ...[
            const SizedBox(width: 6),
            _buildFilterChip(
              label: group,
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? panelTheme.primaryColor : panelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? panelTheme.primaryColor : panelTheme.borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: panelTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color:
                isSelected ? panelTheme.onPrimaryColor : panelTheme.textColor,
          ),
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

  Widget _buildScenarioCard(
    BuildContext context,
    Scenario scenario,
    bool isSelected,
    ScenarioController controller,
    ScenarioPanelThemeData panelTheme,
  ) {
    return InkWell(
      onTap: () => controller.select(scenario),
      borderRadius: panelTheme.borderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? panelTheme.activeItemColor
              : panelTheme.effectiveCardColor,
          borderRadius: panelTheme.borderRadius,
          border: Border.all(
            color:
                isSelected ? panelTheme.primaryColor : panelTheme.borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: panelTheme.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    scenario.name,
                    style: TextStyle(
                      color: panelTheme.textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (scenario.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.chipColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: panelTheme.borderColor,
                      ),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: panelTheme.subtitleColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: panelTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: panelTheme.chipColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: panelTheme.borderColor.withValues(alpha: 0.5),
                    ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: panelTheme.chipColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: panelTheme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 11,
                          color: panelTheme.subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scenario.group!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: panelTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (scenario.metadata.isNotEmpty)
                  InkWell(
                    onTap: () => _showMetadataDialog(
                      context,
                      scenario,
                      panelTheme,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: panelTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: panelTheme.primaryColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'meta (${scenario.metadata.length})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: panelTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (scenario.description != null &&
                scenario.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                scenario.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: panelTheme.subtitleColor,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
