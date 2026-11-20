part of 'scenario_kit_ui.dart';

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.passedColor,
    required this.failedColor,
    required this.skippedColor,
    required this.trackColor,
  });

  final int passed, failed, skipped;
  final Color passedColor, failedColor, skippedColor, trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke,
        size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);
    final total = passed + failed + skipped;
    if (total == 0) return;
    var start = -math.pi / 2;
    void arc(int n, Color c) {
      if (n == 0) return;
      final sweep = n / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, paint..color = c);
      start += sweep;
    }

    arc(passed, passedColor);
    arc(failed, failedColor);
    arc(skipped, skippedColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) =>
      o.passed != passed || o.failed != failed || o.skipped != skipped;
}

enum _ReportFilter { all, failed, passed }

class SkReportsTab extends StatefulWidget {
  const SkReportsTab({
    super.key,
    required this.report,
    this.onExport,
    this.onSwitchToTests,
    this.emptyMessage,
  });

  final SkReportData? report;
  final ValueChanged<SkExportFormat>? onExport;
  final VoidCallback? onSwitchToTests;
  final String? emptyMessage;

  @override
  State<SkReportsTab> createState() => _SkReportsTabState();
}

class _SkReportsTabState extends State<SkReportsTab> {
  _ReportFilter _filter = _ReportFilter.all;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final r = widget.report;
    if (r == null || r.results.isEmpty) {
      return SkEmptyState(
        icon: Icons.insert_chart_outlined_rounded,
        title: 'No test runs yet',
        message: widget.emptyMessage ??
            'Run tests from the Tests tab and the results will show here.',
        actionLabel: widget.onSwitchToTests == null ? null : 'Go to Tests',
        actionKey: widget.onSwitchToTests == null
            ? null
            : const Key('go_to_tests_tab_button'),
        onAction: widget.onSwitchToTests,
      );
    }

    final shown = r.results.where((x) {
      switch (_filter) {
        case _ReportFilter.all:
          return true;
        case _ReportFilter.failed:
          return x.status == SkStatus.failed;
        case _ReportFilter.passed:
          return x.status == SkStatus.passed;
      }
    }).toList();

    return LayoutBuilder(builder: (context, c) {
      final compact = _isCompact(c.maxWidth);
      final pad = compact ? 16.0 : 24.0;
      final allGood = r.failed == 0;
      final headColor = allGood ? t.successColor : t.errorColor;

      Widget stat(String label, int n, Color color, {bool neutral = false}) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: neutral ? t.surfaceColor : t.tint(color, 26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: neutral ? t.borderColor : color.withAlpha(90)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: _ts(neutral ? t.subtitleColor : t.deep(color), 12,
                        FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$n',
                    style: _ts(neutral ? t.textColor : t.deep(color), 20,
                        FontWeight.w700)),
              ],
            ),
          );

      final donut = SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(96, 96),
              painter: _DonutPainter(
                passed: r.passed,
                failed: r.failed,
                skipped: r.skipped,
                passedColor: t.successColor,
                failedColor: t.errorColor,
                skippedColor: t.warningColor,
                trackColor: t.chipColor,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${r.passed}/${r.total}',
                    style: _ts(t.textColor, 18, FontWeight.w700, 1.1)),
                Text(
                  '${(r.total == 0 ? 0 : r.passed / r.total * 100).toStringAsFixed(1)}%',
                  style: _ts(t.subtitleColor, 11, FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );

      final headline = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allGood
                ? 'All ${r.total} tests passed'
                : '${r.failed} ${r.failed == 1 ? 'test' : 'tests'} failed',
            style: _ts(
                headColor == t.errorColor ? t.deep(headColor) : t.textColor, 19,
                FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Run finished in ${(r.duration.inMilliseconds / 1000).toStringAsFixed(2)}s',
            style: _ts(t.subtitleColor, 13.5, FontWeight.w400),
          ),
        ],
      );

      final stats = compact
          ? Column(children: [
              Row(children: [
                Expanded(
                    child: stat('Total', r.total, t.textColor, neutral: true)),
                const SizedBox(width: 10),
                Expanded(child: stat('Passed', r.passed, t.successColor)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: stat('Failed', r.failed, t.errorColor)),
                const SizedBox(width: 10),
                Expanded(child: stat('Skipped', r.skipped, t.warningColor)),
              ]),
            ])
          : Row(children: [
              Expanded(
                  child: stat('Total', r.total, t.textColor, neutral: true)),
              const SizedBox(width: 10),
              Expanded(child: stat('Passed', r.passed, t.successColor)),
              const SizedBox(width: 10),
              Expanded(child: stat('Failed', r.failed, t.errorColor)),
              const SizedBox(width: 10),
              Expanded(child: stat('Skipped', r.skipped, t.warningColor)),
            ]);

      final exportButtons = widget.onExport == null
          ? const SizedBox.shrink()
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: _outlinedStyle(t),
                    onPressed: () => widget.onExport!(SkExportFormat.html),
                    child: const Text('Export HTML'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: _filledStyle(t),
                    onPressed: () => widget.onExport!(SkExportFormat.pdf),
                    child: const Text('Export PDF'),
                  ),
                ),
              ],
            );

      final summary = Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                donut,
                const SizedBox(width: 18),
                Expanded(child: headline),
              ],
            ),
            const SizedBox(height: 16),
            stats,
            if (widget.onExport != null) ...[
              const SizedBox(height: 14),
              exportButtons,
            ],
          ],
        ),
      );

      final hint = r.hint == null
          ? null
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.tint(t.warningColor, 30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.warningColor.withAlpha(110)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: t.deep(t.warningColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.hint!,
                      style: _ts(t.deep(t.warningColor), 13.5,
                          FontWeight.w400, 1.5),
                    ),
                  ),
                ],
              ),
            );

      final filters = SkChipRow(
        children: [
          SkChip(
            key: const Key('report_filter_all'),
            label: 'All',
            count: r.total,
            small: true,
            selected: _filter == _ReportFilter.all,
            onTap: () => setState(() => _filter = _ReportFilter.all),
          ),
          SkChip(
            key: const Key('report_filter_failed'),
            label: 'Failed',
            count: r.failed,
            small: true,
            selected: _filter == _ReportFilter.failed,
            onTap: () => setState(() => _filter = _ReportFilter.failed),
          ),
          SkChip(
            key: const Key('report_filter_passed'),
            label: 'Passed',
            count: r.passed,
            small: true,
            selected: _filter == _ReportFilter.passed,
            onTap: () => setState(() => _filter = _ReportFilter.passed),
          ),
        ],
      );

      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 28),
        children: [
          summary,
          if (hint != null) ...[const SizedBox(height: 14), hint],
          const SizedBox(height: 20),
          Text('Test details', style: _ts(t.textColor, 16, FontWeight.w700)),
          const SizedBox(height: 10),
          filters,
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No tests in this filter.',
                    style: _ts(t.subtitleColor, 14, FontWeight.w400)),
              ),
            )
          else
            for (final item in shown) ...[
              SkTestTile(
                key: ValueKey('report_${item.id}'),
                item: item,
                expanded: _expanded.contains(item.id),
                onToggle: () => setState(() => _expanded.contains(item.id)
                    ? _expanded.remove(item.id)
                    : _expanded.add(item.id)),
              ),
              const SizedBox(height: 12),
            ],
        ],
      );
    });
  }
}