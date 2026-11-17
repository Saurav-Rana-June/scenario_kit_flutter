import 'package:flutter/material.dart';

import '../../testing/definitions/scenario_test.dart';
import '../../testing/definitions/test_status.dart';
import '../../testing/executor/test_execution_progress.dart';
import '../../testing/executor/test_execution_result.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../testing/reporting/scenario_test_report.dart';
import '../../testing/runner/execution_mode.dart';
import '../../testing/runner/scenario_test_runner.dart';
import '../../testing/runner/screen_execution_summary.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_report_viewer.dart';

/// Interactive developer dashboard for reviewing, filtering, executing, and
/// diagnosing automated screen-level and functionality-level tests.
class ScenarioTestDashboard extends StatefulWidget {
  /// Creates a [ScenarioTestDashboard].
  const ScenarioTestDashboard({
    super.key,
    this.registry,
    this.runner,
    this.theme,
    this.onClose,
  });

  /// The registry containing registered test suites and tests.
  final ScenarioTestRegistry? registry;

  /// The runner executing test suites.
  final ScenarioTestRunner? runner;

  /// Theme for the dashboard.
  final ScenarioPanelThemeData? theme;

  /// Callback when the dashboard close button is tapped.
  final VoidCallback? onClose;

  @override
  State<ScenarioTestDashboard> createState() => _ScenarioTestDashboardState();
}

class _ScenarioTestDashboardState extends State<ScenarioTestDashboard> {
  late final ScenarioTestRegistry _registry;
  late final ScenarioTestRunner _runner;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedScreen; // null means all screens
  String? _selectedGroup; // null means all groups
  final Set<String> _selectedTestIds = {};

  final Map<String, TestExecutionResult> _latestResults = {};
  ScreenExecutionSummary? _lastSummary;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry ?? ScenarioTestRegistry.instance;
    _runner = widget.runner ?? ScenarioTestRunner(registry: _registry);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q != _searchQuery) {
      setState(() {
        _searchQuery = q;
      });
    }
  }

  @override
  void dispose() {
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

    if (_searchQuery.isNotEmpty) {
      list = list.where((t) {
        final matchName = t.name.toLowerCase().contains(_searchQuery);
        final matchDesc =
            t.description?.toLowerCase().contains(_searchQuery) ?? false;
        final matchGroup =
            t.group?.toLowerCase().contains(_searchQuery) ?? false;
        final matchScreen =
            t.screen?.toLowerCase().contains(_searchQuery) ?? false;
        return matchName || matchDesc || matchGroup || matchScreen;
      }).toList();
    }

    return list;
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
    final filtered = _getFilteredItems();
    final toRun = filtered
        .where((t) => _selectedTestIds.contains(t.id))
        .map((t) => t.id)
        .toList();
    if (toRun.isEmpty) return;

    final summary = await _runner.runSelectedTests(toRun, context: context);
    setState(() {
      _lastSummary = summary;
      for (final r in summary.results) {
        _latestResults[r.testId] = r;
      }
    });
  }

  Future<void> _runAllTests(BuildContext context) async {
    final filtered = _getFilteredItems();
    if (filtered.isEmpty) return;

    ScreenExecutionSummary summary;
    if (_selectedScreen != null) {
      summary = await _runner.runScreenTests(
        _selectedScreen!,
        group: _selectedGroup,
        context: context,
      );
    } else {
      summary = await _runner.runSelectedTests(
        filtered.map((t) => t.id).toList(),
        context: context,
      );
    }

    setState(() {
      _lastSummary = summary;
      for (final r in summary.results) {
        _latestResults[r.testId] = r;
      }
    });
  }

  Future<void> _runSingleTest(BuildContext context, ScenarioTest test) async {
    final result =
        await _runner.runFunctionalityTest(test.id, context: context);
    setState(() {
      _latestResults[test.id] = result;
      _lastSummary = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.functionality,
        results: [result],
        startTime: result.timestamp,
        endTime: result.timestamp.add(result.duration),
        screenName: test.screen,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final panelTheme = widget.theme ?? ScenarioPanelThemeData.dark();
    final filteredTests = _getFilteredItems();
    final screens = _registry.screens;
    final groups = _getAvailableGroups();

    return Material(
      color: panelTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(panelTheme),
          _buildScreenFilterChips(screens, panelTheme),
          if (groups.isNotEmpty) _buildGroupFilterChips(groups, panelTheme),
          _buildSearchBar(panelTheme),
          _buildActionControls(context, filteredTests, panelTheme),
          ValueListenableBuilder<TestExecutionProgress>(
            valueListenable: _runner.progressNotifier,
            builder: (ctx, progress, _) {
              if (!progress.isRunning) return const SizedBox.shrink();
              return _buildProgressBanner(progress, panelTheme);
            },
          ),
          const Divider(height: 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: panelTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: panelTheme.borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check, color: panelTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Test Mode',
            style: TextStyle(
              color: panelTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: panelTheme.chipColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_registry.totalTestCount}',
              style: TextStyle(color: panelTheme.subtitleColor, fontSize: 11),
            ),
          ),
          const Spacer(),
          if (_lastSummary != null)
            TextButton.icon(
              key: const ValueKey('view_report_button'),
              icon: const Icon(Icons.assessment, size: 16),
              label: const Text('View Report'),
              style: TextButton.styleFrom(
                foregroundColor: panelTheme.primaryColor,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                final report = ScenarioTestReport.fromSummaries(
                  title: 'In-App Test Report',
                  summaries: [_lastSummary!],
                );
                ScenarioReportViewerDialog.show(context,
                    report: report, theme: panelTheme);
              },
            ),
          if (widget.onClose != null)
            IconButton(
              icon:
                  Icon(Icons.close, color: panelTheme.subtitleColor, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Screens'),
            selected: _selectedScreen == null,
            onSelected: (_) => setState(() {
              _selectedScreen = null;
              _selectedGroup = null;
            }),
            backgroundColor: panelTheme.chipColor,
            selectedColor: panelTheme.primaryColor,
            labelStyle: TextStyle(
              color: _selectedScreen == null
                  ? panelTheme.onPrimaryColor
                  : panelTheme.textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          ...screens.map((screen) {
            final isSel = _selectedScreen == screen;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(screen),
                selected: isSel,
                onSelected: (_) => setState(() {
                  _selectedScreen = screen;
                  _selectedGroup = null;
                }),
                backgroundColor: panelTheme.chipColor,
                selectedColor: panelTheme.primaryColor,
                labelStyle: TextStyle(
                  color:
                      isSel ? panelTheme.onPrimaryColor : panelTheme.textColor,
                  fontSize: 12,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips(
      List<String> groups, ScenarioPanelThemeData panelTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Groups'),
            selected: _selectedGroup == null,
            onSelected: (_) => setState(() => _selectedGroup = null),
            backgroundColor: panelTheme.chipColor,
            selectedColor: panelTheme.primaryColor.withValues(alpha: 0.7),
            labelStyle: TextStyle(
              color: _selectedGroup == null
                  ? panelTheme.onPrimaryColor
                  : panelTheme.subtitleColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          ...groups.map((group) {
            final isSel = _selectedGroup == group;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(group),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedGroup = group),
                backgroundColor: panelTheme.chipColor,
                selectedColor: panelTheme.primaryColor.withValues(alpha: 0.7),
                labelStyle: TextStyle(
                  color: isSel
                      ? panelTheme.onPrimaryColor
                      : panelTheme.subtitleColor,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ScenarioPanelThemeData panelTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: panelTheme.textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search test cases or steps...',
          hintStyle: TextStyle(color: panelTheme.subtitleColor, fontSize: 13),
          prefixIcon:
              Icon(Icons.search, color: panelTheme.subtitleColor, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: panelTheme.subtitleColor, size: 16),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: panelTheme.surfaceColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: panelTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: panelTheme.borderColor),
          ),
        ),
      ),
    );
  }

  Widget _buildActionControls(
    BuildContext context,
    List<ScenarioTest> filteredTests,
    ScenarioPanelThemeData panelTheme,
  ) {
    final allSelected = filteredTests.isNotEmpty &&
        filteredTests.every((t) => _selectedTestIds.contains(t.id));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: const ValueKey('select_all_checkbox'),
              value: allSelected,
              activeColor: panelTheme.primaryColor,
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
              style: TextStyle(color: panelTheme.subtitleColor, fontSize: 12),
            ),
            const SizedBox(width: 16),
            if (_runner.isRunning)
              ElevatedButton.icon(
                key: const ValueKey('cancel_button'),
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _runner.cancel(),
              )
            else ...[
              OutlinedButton(
                key: const ValueKey('run_all_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: panelTheme.textColor,
                  side: BorderSide(color: panelTheme.borderColor),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _runAllTests(context),
                child: const Text('Run All'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: const ValueKey('run_selected_button'),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text('Run Selected (${_selectedTestIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: panelTheme.primaryColor,
                  foregroundColor: panelTheme.onPrimaryColor,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _selectedTestIds.isEmpty
                    ? null
                    : () => _runSelectedTests(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: panelTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.currentTest != null
                      ? 'Running: ${progress.currentTest!.name} (${progress.currentStepIndex + 1}/${progress.totalStepsInCurrentTest})'
                      : 'Preparing tests...',
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress.percentage * 100).toInt()}%',
                style: TextStyle(
                  color: panelTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage,
              backgroundColor: panelTheme.backgroundColor,
              valueColor: AlwaysStoppedAnimation(panelTheme.primaryColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passed: ${progress.passedCount} \u2022 Failed: ${progress.failedCount} \u2022 Skipped: ${progress.skippedCount}',
                style: TextStyle(color: panelTheme.subtitleColor, fontSize: 11),
              ),
              Text(
                '${(progress.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s',
                style: TextStyle(color: panelTheme.subtitleColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestList(
    BuildContext context,
    List<ScenarioTest> tests,
    ScenarioPanelThemeData panelTheme,
  ) {
    return ListView.separated(
      itemCount: tests.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: panelTheme.borderColor),
      itemBuilder: (ctx, index) {
        final test = tests[index];
        final isSelected = _selectedTestIds.contains(test.id);
        final latest = _latestResults[test.id];

        return ListTile(
          dense: true,
          leading: Checkbox(
            value: isSelected,
            activeColor: panelTheme.primaryColor,
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
          title: Row(
            children: [
              _buildStatusIcon(latest?.status ?? TestStatus.pending),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  test.name,
                  style: TextStyle(
                    color: panelTheme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (test.group != null) ...[
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: panelTheme.chipColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    test.group!,
                    style: TextStyle(
                        color: panelTheme.subtitleColor, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${test.steps.length} steps${latest != null ? " \u2022 ${latest.duration.inMilliseconds}ms" : ""}',
                style: TextStyle(color: panelTheme.subtitleColor, fontSize: 11),
              ),
            ],
          ),
          trailing: IconButton(
            key: ValueKey('run_single_${test.id}'),
            icon: const Icon(Icons.play_arrow, size: 18),
            color: panelTheme.primaryColor,
            onPressed:
                _runner.isRunning ? null : () => _runSingleTest(context, test),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return const Icon(Icons.check_circle,
            color: Color(0xFF22C55E), size: 16);
      case TestStatus.failed:
        return const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 16);
      case TestStatus.skipped:
        return const Icon(Icons.do_not_disturb_on,
            color: Color(0xFFF59E0B), size: 16);
      case TestStatus.running:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TestStatus.pending:
        return const Icon(Icons.circle_outlined,
            color: Color(0xFF6B7280), size: 14);
    }
  }

  Widget _buildEmptyState(ScenarioPanelThemeData panelTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: panelTheme.subtitleColor),
          const SizedBox(height: 8),
          Text(
            'No tests match your filter criteria',
            style: TextStyle(color: panelTheme.subtitleColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
