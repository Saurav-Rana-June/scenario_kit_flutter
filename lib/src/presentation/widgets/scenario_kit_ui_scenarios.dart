part of 'scenario_kit_ui.dart';

class SkScenarioCard extends StatelessWidget {
  const SkScenarioCard({
    super.key,
    required this.item,
    required this.active,
    this.onApply,
    this.onApplyAndPreview,
    this.onShowMeta,
  });

  final SkScenarioItem item;
  final bool active;
  final VoidCallback? onApply;
  final VoidCallback? onApplyAndPreview;
  final VoidCallback? onShowMeta;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    Widget badge(String text, Color bg, Color fg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text, style: _ts(fg, 11, FontWeight.w700)),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? t.tint(t.primaryColor, 22) : t.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? t.primaryColor : t.borderColor,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: _ts(t.textColor, 16, FontWeight.w600)),
              ),
              if (item.isDefault) ...[
                const SizedBox(width: 8),
                badge('DEFAULT', t.chipColor, t.textColor),
              ],
              if (active) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 13, color: t.onPrimaryColor),
                      const SizedBox(width: 4),
                      Text('Active',
                          style: _ts(t.onPrimaryColor, 12, FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: _ts(t.subtitleColor, 14, FontWeight.w400, 1.45)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.chipColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.id, style: _mono(t.textColor, 12)),
              ),
              badge(item.group, t.chipColor, t.textColor),
              if (item.metaCount > 0)
                InkWell(
                  onTap: onShowMeta,
                  borderRadius: BorderRadius.circular(6),
                  child: badge('meta ${item.metaCount}',
                      t.tint(t.primaryColor, 34), t.primaryColor),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (active)
                OutlinedButton(
                  style: _outlinedStyle(t, color: t.primaryColor),
                  onPressed: null,
                  child: const Text('Applied'),
                )
              else
                FilledButton(
                  style: _filledStyle(t),
                  onPressed: onApply,
                  child: const Text('Apply scenario'),
                ),
              OutlinedButton(
                style: _outlinedStyle(t),
                onPressed: onApplyAndPreview,
                child: const Text('Apply and preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SkScenariosTab extends StatefulWidget {
  const SkScenariosTab({
    super.key,
    required this.scenarios,
    required this.activeId,
    this.onApply,
    this.onApplyAndPreview,
    this.onShowMeta,
  });

  final List<SkScenarioItem> scenarios;
  final String? activeId;
  final ValueChanged<String>? onApply;
  final ValueChanged<String>? onApplyAndPreview;
  final ValueChanged<String>? onShowMeta;

  @override
  State<SkScenariosTab> createState() => _SkScenariosTabState();
}

class _SkScenariosTabState extends State<SkScenariosTab> {
  String _query = '';
  String? _group;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final groups = <String>[];
    for (final s in widget.scenarios) {
      if (!groups.contains(s.group)) groups.add(s.group);
    }
    groups.sort();

    final q = _query.trim().toLowerCase();
    final visible = widget.scenarios.where((s) {
      if (_group != null && s.group != _group) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q) ||
          s.group.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(builder: (context, c) {
      final compact = _isCompact(c.maxWidth);
      final pad = compact ? 16.0 : 24.0;

      Widget card(SkScenarioItem s) => SkScenarioCard(
            item: s,
            active: s.id == widget.activeId,
            onApply: widget.onApply == null ? null : () => widget.onApply!(s.id),
            onApplyAndPreview: widget.onApplyAndPreview == null
                ? null
                : () => widget.onApplyAndPreview!(s.id),
            onShowMeta:
                widget.onShowMeta == null ? null : () => widget.onShowMeta!(s.id),
          );

      Widget list;
      if (visible.isEmpty) {
        list = const SkEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No scenarios found',
          message: 'Try a different name, ID, group or tag.',
        );
      } else if (compact) {
        list = ListView.separated(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => card(visible[i]),
        );
      } else {
        final rows = (visible.length / 2).ceil();
        list = ListView.separated(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
          itemCount: rows,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, r) {
            final a = visible[r * 2];
            final b = r * 2 + 1 < visible.length ? visible[r * 2 + 1] : null;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card(a)),
                  const SizedBox(width: 14),
                  Expanded(child: b == null ? const SizedBox() : card(b)),
                ],
              ),
            );
          },
        );
      }

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 4),
            child: SkSearchField(
              hint: compact
                  ? 'Search scenarios'
                  : 'Search scenarios by name, ID, group, or tag',
              showSlashHint: !compact,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 12),
          SkChipRow(
            padding: EdgeInsets.symmetric(horizontal: pad),
            children: [
              SkChip(
                key: const Key('filter_chip_All'),
                label: 'All',
                count: widget.scenarios.length,
                selected: _group == null,
                onTap: () => setState(() => _group = null),
              ),
              for (final g in groups)
                SkChip(
                  key: Key('filter_chip_$g'),
                  label: g,
                  count: widget.scenarios.where((s) => s.group == g).length,
                  selected: _group == g,
                  onTap: () => setState(() => _group = g),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: t.borderColor),
          Expanded(child: list),
        ],
      );
    });
  }
}