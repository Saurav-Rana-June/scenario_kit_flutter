import 'package:flutter/material.dart';

import '../../testing/definitions/scenario_test.dart';
import '../../testing/definitions/test_status.dart';
import '../../testing/executor/test_execution_progress.dart';
import '../../testing/executor/test_execution_result.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/scenario_report_store.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../testing/runner/execution_mode.dart';
import '../../testing/runner/scenario_test_runner.dart';
import '../../testing/runner/screen_execution_summary.dart';
import '../scenario_kit_bindings.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_report_viewer.dart';

/// Interactive developer dashboard for filtering, selecting, executing, and
/// reviewing screen-level and functionality-level test suites in ScenarioKit.
class ScenarioTestDashboard extends StatefulWidget {
  /// Creates a [ScenarioTestDashboard].
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

  /// The registry providing registered test suites and tests.
  final ScenarioTestRegistry? registry;

  /// The runner executing tests.
  final ScenarioTestRunner? runner;

  /// Custom theme for the dashboard.
  final ScenarioPanelThemeData? theme;

  /// Optional callback invoked when the user taps close.
  final VoidCallback? onClose;

  /// Host context under [ScenarioKit] for in-app test execution (see [ScenarioPanel]).
  final BuildContext? executionContext;

  /// Screen currently mounted in the host app (from [ScenarioKit.screenName]).
  final String? currentScreenName;

  /// Invoked when the user chooses to navigate to the selected test screen.
  final void Function(String screenName)? onNavigateToScreen;

  /// Optional callback invoked when test execution completes.
  final void Function(ScreenExecutionSummary summary)? onExecutionCompleted;

  /// Optional callback invoked when the user taps View Report.
  final VoidCallback? onViewReport;

  @override
  State<ScenarioTestDashboard> createState() => _ScenarioTestDashboardState();
}

class _ScenarioTestDashboardState extends State<ScenarioTestDashboard> {
  late final ScenarioTestRegistry _registry;
  late final ScenarioTestRunner _runner;
  late final TextEditingController _searchController;

  String? _selectedScreen;
  String? _selectedGroup;
  String? _selectedTag;
  String _searchQuery = '';
  final Set<String> _selectedTestIds = {};
  final Set<String> _expandedTestIds = {};
  final Map<String, TestExecutionResult> _latestResults = {};
  ScreenExecutionSummary? _lastSummary;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? ScenarioTestRegistry.instance;
    _runner = widget.runner ?? ScenarioTestRunner(registry: _registry);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _registry.addListener(_onRegistryChanged);
    _applyActiveScreenFilter();
  }

  void _applyActiveScreenFilter() {
    final active = widget.currentScreenName?.trim();
    if (active == null || active.isEmpty) return;
    if (_registry.getTestsForScreen(active).isNotEmpty) {
      _selectedScreen = active;
    }
  }

  @override
  void didUpdateWidget(covariant ScenarioTestDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentScreenName != widget.currentScreenName) {
      _applyActiveScreenFilter();
    }
  }

  void _onRegistryChanged() {
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
    _registry.removeListener(_onRegistryChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<ScenarioTest> _getFilteredItems() {
    List<ScenarioTest> list = _selectedScreen != null
        ? _registry.getTestsForScreen(_selectedScreen!)
        : _registry.allTests;

    if (_selectedGroup != null) {
      list =
          list.where((t) => t.group?.trim() == _selectedGroup!.trim()).toList();
    }

    if (_selectedTag != null) {
      list = list
          .where((t) => t.tags.map((e) => e.trim()).contains(_selectedTag))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((t) {
        final matchName = t.name.toLowerCase().contains(_searchQuery);
        final matchDesc =
            t.description?.toLowerCase().contains(_searchQuery) ?? false;
        final matchGroup =
            t.group?.toLowerCase().contains(_searchQuery) ?? false;
        final matchScreen =
            t.screen?.toLowerCase().contains(_searchQuery) ?? false;
        final matchTags =
            t.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
        return matchName || matchDesc || matchGroup || matchScreen || matchTags;
      }).toList();
    }

    return list;
  }

  BuildContext _executionContext(BuildContext context) {
    final host = widget.executionContext;
    if (host != null && host.mounted) {
      return ScenarioKitBindings.resolveExecutionContext(host);
    }
    return ScenarioKitBindings.resolveExecutionContext(context);
  }

  bool get _isScreenMismatch {
    final active = widget.currentScreenName;
    final selected = _selectedScreen;
    return selected != null && active != null && selected != active;
  }

  bool _isTestRunBlocked(ScenarioTest test) {
    final active = widget.currentScreenName;
    final target = (test.screen ?? _selectedScreen)?.trim();
    if (active == null || target == null || target.isEmpty) return false;
    return active != target;
  }

  List<String> _getAvailableGroups() {
    final tests = _selectedScreen != null
        ? _registry.getTestsForScreen(_selectedScreen!)
        : _registry.allTests;

    final groups = tests
        .map((t) => t.group?.trim())
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    return groups;
  }

  Future<void> _runSelectedTests(BuildContext context) async {
    if (_isScreenMismatch) return;
    final filtered = _getFilteredItems();
    final toRun = filtered
        .where((t) => _selectedTestIds.contains(t.id))
        .map((t) => t.id)
        .toList();
    if (toRun.isEmpty) return;

    final summary = await _runner.runSelectedTests(
      toRun,
      context: _executionContext(context),
    );
    if (!mounted) return;
    setState(() {
      _lastSummary = summary;
      for (final r in summary.results) {
        _latestResults[r.testId] = r;
      }
    });
    ScenarioReportStore.instance.recordSummary(summary);
    widget.onExecutionCompleted?.call(summary);
  }

  Future<void> _runAllTests(BuildContext context) async {
    if (_isScreenMismatch) return;
    final filtered = _getFilteredItems();
    if (filtered.isEmpty) return;

    if (mounted) setState(() {});

    ScreenExecutionSummary summary;
    if (_selectedScreen != null) {
      summary = await _runner.runScreenTests(
        _selectedScreen!,
        group: _selectedGroup,
        context: _executionContext(context),
      );
    } else {
      summary = await _runner.runSelectedTests(
        filtered.map((t) => t.id).toList(),
        context: _executionContext(context),
      );
    }

    if (!mounted) return;
    setState(() {
      _lastSummary = summary;
      for (final r in summary.results) {
        _latestResults[r.testId] = r;
      }
    });
    ScenarioReportStore.instance.recordSummary(summary);
    widget.onExecutionCompleted?.call(summary);
  }

  void _handleTapRunSingleTest(BuildContext context, ScenarioTest test) {
    final active = widget.currentScreenName;
    final target = test.screen ?? _selectedScreen;

    if (active != null &&
        target != null &&
        target.trim().isNotEmpty &&
        active != target.trim()) {
      _showMismatchDialog(context, targetScreen: target.trim());
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
      context: context,
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
      executionMode: _selectedScreen != null
          ? ExecutionMode.screen
          : ExecutionMode.functionality,
      results: [result],
      startTime: result.timestamp,
      endTime: result.timestamp.add(result.duration),
      screenName: test.screen,
    );
    setState(() {
      _latestResults[test.id] = result;
      _lastSummary = summary;
    });
    ScenarioReportStore.instance.recordSummary(summary);
    widget.onExecutionCompleted?.call(summary);
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = widget.theme ?? ScenarioPanelThemeData.light();
    final filteredTests = _getFilteredItems();
    final screens = _registry.screens;
    final groups = _getAvailableGroups();
    final tags = _registry.allTags;

    return Material(
      color: panelTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(panelTheme),
          _buildScreenFilterChips(screens, panelTheme),
          if (groups.isNotEmpty) _buildGroupFilterChips(groups, panelTheme),
          if (tags.isNotEmpty) _buildTagFilterChips(tags, panelTheme),
          _buildScreenMismatchBanner(panelTheme),
          _buildSearchBar(panelTheme),
          _buildActionControls(context, filteredTests, panelTheme),
          ValueListenableBuilder<TestExecutionProgress>(
            valueListenable: _runner.progressNotifier,
            builder: (ctx, progress, _) {
              if (!progress.isRunning) return const SizedBox.shrink();
              return _buildProgressBanner(progress, panelTheme);
            },
          ),
          Divider(
            height: 1,
            color: panelTheme.borderColor.withValues(alpha: 0.6),
          ),
          Expanded(
            child: filteredTests.isEmpty
                ? _buildEmptyState(panelTheme)
                : _buildTestList(context, filteredTests, panelTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  panelTheme.primaryColor,
                  panelTheme.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: panelTheme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Test Mode',
            style: TextStyle(
              color: panelTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: panelTheme.chipColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: panelTheme.borderColor.withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              '${_registry.totalTestCount}',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (widget.onClose != null)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: panelTheme.subtitleColor,
                size: 18,
              ),
              style: IconButton.styleFrom(
                backgroundColor: panelTheme.chipColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildScreenFilterChips(
      List<String> screens, ScenarioPanelThemeData panelTheme) {
    if (screens.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _buildScreenChip(
            label: 'All Screens',
            count: _registry.totalTestCount,
            isSelected: _selectedScreen == null,
            isActiveScreen: false,
            onTap: () => setState(() {
              _selectedScreen = null;
              _selectedGroup = null;
            }),
            panelTheme: panelTheme,
          ),
          for (final screen in screens) ...[
            const SizedBox(width: 6),
            _buildScreenChip(
              label: screen,
              count: _registry.getTestsForScreen(screen).length,
              isSelected: _selectedScreen == screen,
              isActiveScreen: widget.currentScreenName == screen,
              onTap: () => setState(() {
                _selectedScreen = screen;
                _selectedGroup = null;
              }),
              panelTheme: panelTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenMismatchBanner(ScenarioPanelThemeData panelTheme) {
    final active = widget.currentScreenName;
    final selected = _selectedScreen;
    if (selected == null || active == null || selected == active) {
      return const SizedBox.shrink();
    }

    const warningColor = Colors.amber;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warningColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are currently viewing "$active". Running tests for '
              '"$selected" may fail because its UI is not mounted.',
              style: TextStyle(
                fontSize: 12,
                color: warningColor.withValues(alpha: 0.95),
                height: 1.35,
              ),
            ),
          ),
          if (widget.onNavigateToScreen != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                widget.onClose?.call();
                widget.onNavigateToScreen!(selected);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Go to Screen', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenChip({
    required String label,
    required int count,
    required bool isSelected,
    required bool isActiveScreen,
    required VoidCallback onTap,
    required ScenarioPanelThemeData panelTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActiveScreen) ...[
              Icon(
                Icons.circle,
                size: 8,
                color: isSelected
                    ? panelTheme.onPrimaryColor
                    : panelTheme.successColor,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? panelTheme.onPrimaryColor
                    : panelTheme.textColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isActiveScreen) ...[
              const SizedBox(width: 4),
              Text(
                '(Active)',
                style: TextStyle(
                  color: isSelected
                      ? panelTheme.onPrimaryColor.withValues(alpha: 0.9)
                      : panelTheme.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : panelTheme.chipColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? panelTheme.onPrimaryColor
                      : panelTheme.subtitleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilterChips(
      List<String> tags, ScenarioPanelThemeData panelTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          _buildFilterPill(
            label: 'All Tags',
            isSelected: _selectedTag == null,
            onTap: () => setState(() => _selectedTag = null),
            panelTheme: panelTheme,
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 6),
            _buildFilterPill(
              label: tag,
              isSelected: _selectedTag == tag,
              onTap: () => setState(() => _selectedTag = tag),
              panelTheme: panelTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips(
      List<String> groups, ScenarioPanelThemeData panelTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          _buildFilterPill(
            label: 'All Groups',
            isSelected: _selectedGroup == null,
            onTap: () => setState(() => _selectedGroup = null),
            panelTheme: panelTheme,
          ),
          for (final group in groups) ...[
            const SizedBox(width: 6),
            _buildFilterPill(
              label: group,
              isSelected: _selectedGroup == group,
              onTap: () => setState(() => _selectedGroup = group),
              panelTheme: panelTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ScenarioPanelThemeData panelTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? panelTheme.primaryColor.withValues(alpha: 0.2)
              : panelTheme.chipColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? panelTheme.primaryColor
                : panelTheme.borderColor.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? panelTheme.primaryColor : panelTheme.subtitleColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ScenarioPanelThemeData panelTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: panelTheme.textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search test cases or steps',
                hintStyle: TextStyle(
                  color: panelTheme.subtitleColor.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: panelTheme.primaryColor.withValues(alpha: 0.8),
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: panelTheme.subtitleColor,
                          size: 16,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: panelTheme.surfaceColor,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          ),
          if (_lastSummary != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const ValueKey('view_report_button'),
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('View report', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: panelTheme.primaryColor,
                side: BorderSide(
                  color: panelTheme.primaryColor.withValues(alpha: 0.4),
                ),
                backgroundColor: panelTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (widget.onViewReport != null) {
                  widget.onViewReport!();
                } else {
                  final report = ScenarioTestReport.fromSummaries(
                    title: 'In-App Test Report',
                    summaries: [_lastSummary!],
                  );
                  ScenarioReportViewerDialog.show(
                    context,
                    report: report,
                    theme: panelTheme,
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionControls(
    BuildContext context,
    List<ScenarioTest> filteredTests,
    ScenarioPanelThemeData panelTheme,
  ) {
    if (_isScreenMismatch) {
      final selected = _selectedScreen!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const ValueKey('go_to_screen_run_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('Go to "$selected" to Run Tests'),
                onPressed: widget.onNavigateToScreen != null
                    ? () {
                        widget.onClose?.call();
                        widget.onNavigateToScreen!(selected);
                      }
                    : () {
                        _showMismatchDialog(context, targetScreen: selected);
                      },
              ),
            ),
          ],
        ),
      );
    }

    final allSelected = filteredTests.isNotEmpty &&
        filteredTests.every((t) => _selectedTestIds.contains(t.id));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: const ValueKey('select_all_checkbox'),
              value: allSelected,
              activeColor: panelTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedTestIds.addAll(filteredTests.map((t) => t.id));
                  } else {
                    _selectedTestIds.removeAll(filteredTests.map((t) => t.id));
                  }
                });
              },
            ),
            Text(
              'Select All (${_selectedTestIds.length}/${filteredTests.length})',
              style: TextStyle(
                color: panelTheme.subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 14),
            if (_runner.isRunning)
              ElevatedButton.icon(
                key: const ValueKey('cancel_button'),
                icon: const Icon(Icons.stop_rounded, size: 16),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: panelTheme.errorColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _runner.cancel(),
              )
            else ...[
              OutlinedButton.icon(
                key: const ValueKey('run_selected_button'),
                icon: const Icon(Icons.playlist_play_rounded, size: 16),
                label: Text('Run Selected (${_selectedTestIds.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: panelTheme.textColor,
                  side: BorderSide(color: panelTheme.borderColor),
                  backgroundColor: panelTheme.surfaceColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _selectedTestIds.isEmpty
                    ? null
                    : () => _runSelectedTests(context),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const ValueKey('run_all_button'),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Run All'),
                style: FilledButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  foregroundColor: panelTheme.onPrimaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _runAllTests(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBanner(
      TestExecutionProgress progress, ScenarioPanelThemeData panelTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: panelTheme.primaryColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: panelTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(panelTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progress.currentTest != null
                      ? 'Running: ${progress.currentTest!.name} (${progress.currentStepIndex + 1}/${progress.totalStepsInCurrentTest})'
                      : 'Preparing test execution...',
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: panelTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(progress.percentage * 100).toInt()}%',
                  style: TextStyle(
                    color: panelTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage,
              backgroundColor: panelTheme.chipColor,
              valueColor: AlwaysStoppedAnimation(panelTheme.primaryColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildMetricBadge('Passed: ${progress.passedCount}',
                      panelTheme.successColor, panelTheme),
                  const SizedBox(width: 6),
                  _buildMetricBadge('Failed: ${progress.failedCount}',
                      panelTheme.errorColor, panelTheme),
                  const SizedBox(width: 6),
                  _buildMetricBadge('Skipped: ${progress.skippedCount}',
                      panelTheme.warningColor, panelTheme),
                ],
              ),
              Text(
                '${(progress.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s',
                style: TextStyle(
                  color: panelTheme.subtitleColor,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(
      String text, Color color, ScenarioPanelThemeData panelTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTestList(
    BuildContext context,
    List<ScenarioTest> tests,
    ScenarioPanelThemeData panelTheme,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final test = tests[index];
        final isSelected = _selectedTestIds.contains(test.id);
        final isExpanded = _expandedTestIds.contains(test.id);
        final latest = _latestResults[test.id];

        return _buildTestCard(
          context,
          test,
          isSelected,
          isExpanded,
          latest,
          panelTheme,
        );
      },
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    ScenarioTest test,
    bool isSelected,
    bool isExpanded,
    TestExecutionResult? latest,
    ScenarioPanelThemeData panelTheme,
  ) {
    final status = latest?.status ?? TestStatus.pending;
    final statusColor = _resolveStatusColor(status, panelTheme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: panelTheme.effectiveCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? panelTheme.primaryColor
              : panelTheme.borderColor.withValues(alpha: 0.8),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  _expandedTestIds.remove(test.id);
                } else {
                  _expandedTestIds.add(test.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: panelTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedTestIds.add(test.id);
                        } else {
                          _selectedTestIds.remove(test.id);
                        }
                      });
                    },
                  ),
                  _buildStatusBadge(status, statusColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.name,
                          style: TextStyle(
                            color: panelTheme.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (test.group != null &&
                                test.group!.trim().isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: panelTheme.chipColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: panelTheme.borderColor
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  test.group!,
                                  style: TextStyle(
                                    color: panelTheme.subtitleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '${test.steps.length} steps${latest != null ? " \u2022 ${latest.duration.inMilliseconds}ms" : ""}',
                              style: TextStyle(
                                color: panelTheme.subtitleColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (latest != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (latest.isFailed
                                ? panelTheme.errorColor
                                : panelTheme.successColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (latest.isFailed
                                  ? panelTheme.errorColor
                                  : panelTheme.successColor)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        latest.isFailed ? 'FAILED' : 'PASSED',
                        style: TextStyle(
                          color: latest.isFailed
                              ? panelTheme.errorColor
                              : panelTheme.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    key: ValueKey('run_single_${test.id}'),
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: _isTestRunBlocked(test)
                          ? panelTheme.subtitleColor.withValues(alpha: 0.5)
                          : panelTheme.primaryColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          panelTheme.primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    tooltip: _isTestRunBlocked(test)
                        ? 'Switch to ${test.screen} to run'
                        : 'Run test',
                    onPressed: _runner.isRunning
                        ? null
                        : () => _handleTapRunSingleTest(context, test),
                  ),
                  const SizedBox(width: 4),
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
            Divider(
              height: 1,
              color: panelTheme.borderColor.withValues(alpha: 0.6),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (test.description != null &&
                      test.description!.trim().isNotEmpty) ...[
                    Text(
                      test.description!,
                      style: TextStyle(
                        color: panelTheme.subtitleColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Steps Timeline',
                    style: TextStyle(
                      color: panelTheme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...test.steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: panelTheme.chipColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: panelTheme.subtitleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: panelTheme.textColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (latest != null && latest.isFailed) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
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
                            child: Text(
                              latest.errorMessage ?? 'Test execution failed',
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _resolveStatusColor(
      TestStatus status, ScenarioPanelThemeData panelTheme) {
    switch (status) {
      case TestStatus.passed:
        return panelTheme.successColor;
      case TestStatus.failed:
        return panelTheme.errorColor;
      case TestStatus.skipped:
        return panelTheme.warningColor;
      case TestStatus.running:
        return panelTheme.primaryColor;
      case TestStatus.pending:
        return panelTheme.subtitleColor;
    }
  }

  Widget _buildStatusBadge(TestStatus status, Color color) {
    switch (status) {
      case TestStatus.passed:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded, color: color, size: 18),
        );
      case TestStatus.failed:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cancel_rounded, color: color, size: 18),
        );
      case TestStatus.skipped:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.do_not_disturb_on_rounded, color: color, size: 18),
        );
      case TestStatus.running:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        );
      case TestStatus.pending:
        return Icon(
          Icons.circle_outlined,
          color: color.withValues(alpha: 0.5),
          size: 16,
        );
    }
  }

  Widget _buildEmptyState(ScenarioPanelThemeData panelTheme) {
    return Center(
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
              size: 36,
              color: panelTheme.subtitleColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No tests match your filter criteria',
            style: TextStyle(
              color: panelTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting a different screen, group, or keyword.',
            style: TextStyle(
              color: panelTheme.subtitleColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
