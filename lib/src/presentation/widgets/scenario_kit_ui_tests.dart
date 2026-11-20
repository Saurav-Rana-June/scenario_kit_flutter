part of 'scenario_kit_ui.dart';

class SkRunProgressCard extends StatelessWidget {
  const SkRunProgressCard({super.key, required this.progress});

  final SkRunProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final p = progress;
    final pct = p.total == 0 ? 0.0 : p.completed / p.total;
    Widget count(String label, int n, Color c) => Text('$label $n',
        style: _ts(t.deep(c), 13, FontWeight.w600));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.tint(t.primaryColor, 18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.primaryColor.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: t.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Running: ${p.currentName} (${p.completed} of ${p.total})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(t.textColor, 14, FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(pct * 100).round()}%',
                  style: _ts(t.primaryColor, 13, FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              color: t.primaryColor,
              backgroundColor: t.tint(t.primaryColor, 40),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              count('Passed', p.passed, t.successColor),
              count('Failed', p.failed, t.errorColor),
              count('Skipped', p.skipped, t.warningColor),
              Text(
                '${(p.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s',
                style: _ts(t.subtitleColor, 13, FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SkStepTimeline extends StatelessWidget {
  const SkStepTimeline({super.key, required this.steps});

  final List<SkStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _dot(t, steps[i].state),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: t.borderColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == steps.length - 1 ? 0 : 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: steps[i].state == SkStepState.failed
                            ? t.tint(t.errorColor, 28)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              steps[i].text,
                              style: _mono(
                                steps[i].state == SkStepState.failed
                                    ? t.deep(t.errorColor)
                                    : (steps[i].state == SkStepState.skipped ||
                                            steps[i].state == SkStepState.idle
                                        ? t.subtitleColor
                                        : t.textColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            steps[i].durationMs != null
                                ? _fmtMs(steps[i].durationMs!)
                                : (steps[i].state == SkStepState.skipped
                                    ? 'not run'
                                    : ''),
                            style: _ts(t.subtitleColor, 12, FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(ScenarioPanelThemeData t, SkStepState s) {
    final c = _stepColor(t, s);
    IconData? icon;
    Color iconColor = Colors.white;
    switch (s) {
      case SkStepState.passed:
        icon = Icons.check_rounded;
        break;
      case SkStepState.failed:
        icon = Icons.close_rounded;
        break;
      case SkStepState.skipped:
      case SkStepState.idle:
        icon = Icons.remove_rounded;
        iconColor = t.subtitleColor;
        break;
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.item});

  final SkTestItem item;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    if (item.steps.isEmpty) return const SizedBox.shrink();
    final passed =
        item.steps.where((s) => s.state == SkStepState.passed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < item.steps.length; i++)
              Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                      right: i == item.steps.length - 1 ? 0 : 3),
                  decoration: BoxDecoration(
                    color: _stepColor(t, item.steps[i].state),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text('$passed of ${item.steps.length} steps passed',
            style: _ts(t.subtitleColor, 11.5, FontWeight.w400)),
      ],
    );
  }
}

class SkTestTile extends StatelessWidget {
  const SkTestTile({
    super.key,
    required this.item,
    required this.expanded,
    required this.onToggle,
    this.selected,
    this.onSelectedChanged,
    this.onRun,
  });

  final SkTestItem item;
  final bool expanded;
  final VoidCallback onToggle;
  final bool? selected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final failed = item.status == SkStatus.failed;
    final accent = _statusColor(t, item.status);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 640;
      final hasCheck = selected != null;
      final leftPad = wide ? (hasCheck ? 66.0 : 16.0 + 40 + 14) : 16.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expanded && failed
                ? t.errorColor.withAlpha(120)
                : (expanded ? accent.withAlpha(120) : t.borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(expanded ? 26 : 10),
              blurRadius: expanded ? 18 : 2,
              offset: Offset(0, expanded ? 6 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, t, wide, leftPad),
            if (failed && !expanded && item.error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(wide ? leftPad : 16, 0, 16, 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.tint(t.errorColor, 28),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.failedStepIndex >= 0
                            ? 'Failed at step ${item.failedStepIndex + 1}'
                            : 'Failed',
                        style: _ts(t.deep(t.errorColor), 12, FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.error!.split('\n').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _mono(t.deep(t.errorColor), 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (expanded) _body(context, t, leftPad),
          ],
        ),
      );
    });
  }

  Widget _statusIcon(ScenarioPanelThemeData t) {
    final c = _statusColor(t, item.status);
    Widget inner;
    switch (item.status) {
      case SkStatus.passed:
        inner = Icon(Icons.check_rounded, color: c, size: 22);
        break;
      case SkStatus.failed:
        inner = Icon(Icons.close_rounded, color: c, size: 22);
        break;
      case SkStatus.running:
        inner = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: c),
        );
        break;
      case SkStatus.skipped:
        inner = Icon(Icons.remove_rounded, color: c, size: 22);
        break;
      case SkStatus.idle:
        inner = Icon(Icons.circle_outlined, color: c, size: 18);
        break;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: t.tint(c, 28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: inner),
    );
  }

  Widget _chip(ScenarioPanelThemeData t, String text, {bool brand = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: brand ? t.tint(t.primaryColor, 34) : t.chipColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: _ts(brand ? t.primaryColor : t.textColor, 12,
              FontWeight.w600)),
    );
  }

  Widget _header(
      BuildContext context, ScenarioPanelThemeData t, bool wide, double leftPad) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name, style: _ts(t.textColor, 15, FontWeight.w600, 1.25)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _chip(t, item.screen),
            _chip(t, item.group, brand: true),
            if (item.durationMs != null)
              Text(_fmtMs(item.durationMs!),
                  style: _ts(t.subtitleColor, 12.5, FontWeight.w400)),
          ],
        ),
      ],
    );

    final check = selected == null
        ? const SizedBox.shrink()
        : Checkbox(
            value: selected,
            visualDensity: VisualDensity.compact,
            activeColor: t.primaryColor,
            onChanged: onSelectedChanged == null
                ? null
                : (v) => onSelectedChanged!(v ?? false),
          );

    final run = onRun == null
        ? const SizedBox.shrink()
        : IconButton(
            tooltip: 'Run this test',
            onPressed: item.status == SkStatus.running ? null : onRun,
            icon: Icon(Icons.play_arrow_rounded,
                color: t.primaryColor, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: t.tint(t.primaryColor, 30),
              minimumSize: const Size(40, 40),
            ),
          );

    final chevron = IconButton(
      tooltip: expanded ? 'Hide steps' : 'Show steps',
      onPressed: onToggle,
      icon: AnimatedRotation(
        turns: expanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(Icons.expand_more_rounded, color: t.textColor),
      ),
    );

    if (wide) {
      return InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
          child: Row(
            children: [
              if (selected != null) check else const SizedBox(width: 4),
              _statusIcon(t),
              const SizedBox(width: 14),
              Expanded(child: title),
              const SizedBox(width: 14),
              SizedBox(width: 128, child: _StepStrip(item: item)),
              const SizedBox(width: 12),
              SkStatusPill(item.status),
              const SizedBox(width: 8),
              run,
              chevron,
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selected != null) check else const SizedBox(width: 8),
                _statusIcon(t),
                const SizedBox(width: 12),
                Expanded(child: title),
                chevron,
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(
                children: [
                  Expanded(child: _StepStrip(item: item)),
                  const SizedBox(width: 10),
                  SkStatusPill(item.status),
                  if (onRun != null) ...[const SizedBox(width: 6), run],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ScenarioPanelThemeData t, double left) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.backgroundColor,
        border: Border(top: BorderSide(color: t.borderColor)),
      ),
      padding: EdgeInsets.fromLTRB(left, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description.isNotEmpty) ...[
            Text(item.description,
                style: _ts(t.subtitleColor, 13.5, FontWeight.w400, 1.5)),
            const SizedBox(height: 14),
          ],
          SkStepTimeline(steps: item.steps),
          if (item.status == SkStatus.failed && item.error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.tint(t.errorColor, 24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.errorColor.withAlpha(90)),
              ),
              child: SelectableText(
                item.error!,
                style: _mono(t.deep(t.errorColor)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onRun != null)
                FilledButton.icon(
                  style: _filledStyle(t),
                  onPressed: item.status == SkStatus.running ? null : onRun,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Run again'),
                ),
              if (item.status == SkStatus.failed && item.error != null)
                OutlinedButton(
                  style: _outlinedStyle(t),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.error!));
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Error copied')),
                    );
                  },
                  child: const Text('Copy error'),
                ),
              if (item.screenshot != null)
                OutlinedButton(
                  style: _outlinedStyle(t),
                  onPressed: () => showDialog<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (_) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(child: item.screenshot!),
                    ),
                  ),
                  child: const Text('View screenshot'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SkTestsTab extends StatefulWidget {
  const SkTestsTab({
    super.key,
    required this.tests,
    this.activeScreen,
    this.progress,
    this.onRun,
    this.onCancel,
    this.onViewReport,
  });

  final List<SkTestItem> tests;
  final String? activeScreen;
  final SkRunProgress? progress;
  final ValueChanged<List<String>>? onRun;
  final VoidCallback? onCancel;
  final VoidCallback? onViewReport;

  @override
  State<SkTestsTab> createState() => _SkTestsTabState();
}

class _SkTestsTabState extends State<SkTestsTab> {
  String _query = '';
  String? _screen;
  String? _group;
  final Set<String> _selected = {};
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _applyActiveScreen();
  }

  @override
  void didUpdateWidget(covariant SkTestsTab old) {
    super.didUpdateWidget(old);
    if (old.activeScreen != widget.activeScreen) _applyActiveScreen();
  }

  void _applyActiveScreen() {
    final s = widget.activeScreen;
    if (s != null && widget.tests.any((t) => t.screen == s)) _screen = s;
  }

  List<SkTestItem> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.tests.where((t) {
      if (_screen != null && t.screen != _screen) return false;
      if (_group != null && t.group != _group) return false;
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.steps.any((s) => s.text.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final screens = <String>[];
    final groups = <String>[];
    for (final x in widget.tests) {
      if (!screens.contains(x.screen)) screens.add(x.screen);
      if (!groups.contains(x.group)) groups.add(x.group);
    }
    groups.sort();
    final visible = _visible;
    final running = widget.progress != null;
    final selectedVisible =
        visible.where((x) => _selected.contains(x.id)).length;

    return LayoutBuilder(builder: (context, c) {
      final compact = _isCompact(c.maxWidth);
      final pad = compact ? 16.0 : 24.0;

      final reportBtn = widget.onViewReport == null
          ? null
          : (compact
              ? IconButton(
                  tooltip: 'View report',
                  onPressed: widget.onViewReport,
                  icon: Icon(Icons.bar_chart_rounded, color: t.primaryColor),
                  style: IconButton.styleFrom(
                    backgroundColor: t.tint(t.primaryColor, 30),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : FilledButton.icon(
                  onPressed: widget.onViewReport,
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text('View report'),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.tint(t.primaryColor, 30),
                    foregroundColor: t.primaryColor,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ));

      final actionBar = Container(
        padding: EdgeInsets.fromLTRB(pad, 10, pad, 12),
        decoration: BoxDecoration(
          color: t.surfaceColor,
          border: Border.symmetric(
            horizontal: BorderSide(color: t.borderColor),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: selectedVisible == 0
                      ? false
                      : (selectedVisible == visible.length ? true : null),
                  visualDensity: VisualDensity.compact,
                  activeColor: t.primaryColor,
                  onChanged: (_) => setState(() {
                    if (selectedVisible == visible.length) {
                      _selected.removeAll(visible.map((e) => e.id));
                    } else {
                      _selected.addAll(visible.map((e) => e.id));
                    }
                  }),
                ),
                Expanded(
                  child: Text(
                    compact
                        ? 'All $selectedVisible/${visible.length}'
                        : 'Select all ($selectedVisible/${visible.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(t.textColor, 13, FontWeight.w500),
                  ),
                ),
                if (running)
                  OutlinedButton.icon(
                    style: _outlinedStyle(t, color: t.errorColor),
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Cancel run'),
                  )
                else ...[
                  OutlinedButton(
                    style: _outlinedStyle(t),
                    onPressed: selectedVisible == 0 || widget.onRun == null
                        ? null
                        : () => widget.onRun!(visible
                            .where((x) => _selected.contains(x.id))
                            .map((x) => x.id)
                            .toList()),
                    child: Text(compact
                        ? 'Run ($selectedVisible)'
                        : 'Run selected ($selectedVisible)'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: _filledStyle(t),
                    onPressed: visible.isEmpty || widget.onRun == null
                        ? null
                        : () => widget.onRun!(
                            visible.map((x) => x.id).toList()),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Run all'),
                  ),
                ],
              ],
            ),
            if (running) ...[
              const SizedBox(height: 10),
              SkRunProgressCard(progress: widget.progress!),
            ],
          ],
        ),
      );

      Widget list;
      if (visible.isEmpty) {
        list = const SkEmptyState(
          icon: Icons.fact_check_outlined,
          title: 'No tests match',
          message: 'Change the screen, group or search filters.',
        );
      } else {
        list = ListView.separated(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = visible[i];
            return SkTestTile(
              key: ValueKey(item.id),
              item: item,
              expanded: _expanded.contains(item.id),
              selected: _selected.contains(item.id),
              onSelectedChanged: (v) => setState(
                  () => v ? _selected.add(item.id) : _selected.remove(item.id)),
              onToggle: () => setState(() => _expanded.contains(item.id)
                  ? _expanded.remove(item.id)
                  : _expanded.add(item.id)),
              onRun: widget.onRun == null || running
                  ? null
                  : () => widget.onRun!([item.id]),
            );
          },
        );
      }

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
            child: Row(
              children: [
                Expanded(
                  child: SkSearchField(
                    hint: 'Search test cases or steps',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (reportBtn != null) ...[
                  const SizedBox(width: 12),
                  reportBtn,
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SkChipRow(
            padding: EdgeInsets.symmetric(horizontal: pad),
            children: [
              SkChip(
                label: 'All screens',
                count: widget.tests.length,
                selected: _screen == null,
                onTap: () => setState(() => _screen = null),
              ),
              for (final s in screens)
                SkChip(
                  label: s,
                  count: widget.tests.where((x) => x.screen == s).length,
                  selected: _screen == s,
                  onTap: () => setState(() => _screen = s),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SkChipRow(
            padding: EdgeInsets.symmetric(horizontal: pad),
            children: [
              SkChip(
                label: 'All groups',
                small: true,
                selected: _group == null,
                onTap: () => setState(() => _group = null),
              ),
              for (final g in groups)
                SkChip(
                  label: g,
                  small: true,
                  selected: _group == g,
                  onTap: () => setState(() => _group = g),
                ),
            ],
          ),
          const SizedBox(height: 12),
          actionBar,
          Expanded(child: list),
        ],
      );
    });
  }
}