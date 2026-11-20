part of 'scenario_kit_ui.dart';

class SkTabSpec {
  const SkTabSpec({
    required this.tab,
    required this.label,
    required this.badge,
    this.warning = false,
    this.testKey,
  });

  final SkTab tab;
  final String label;
  final String badge;
  final bool warning;
  final Key? testKey;
}

class SkSegmentedTabs extends StatelessWidget {
  const SkSegmentedTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChanged,
    this.expand = false,
  });

  final List<SkTabSpec> tabs;
  final SkTab active;
  final ValueChanged<SkTab> onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    Widget item(SkTabSpec s) {
      final sel = s.tab == active;
      final badgeBg = s.warning
          ? t.tint(t.errorColor, 40)
          : (sel ? t.tint(t.primaryColor, 34) : t.borderColor);
      final badgeFg = s.warning
          ? t.deep(t.errorColor)
          : (sel ? t.primaryColor : t.textColor);
      final tile = Material(
        color: sel ? t.surfaceColor : Colors.transparent,
        elevation: sel ? 1 : 0,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          key: s.testKey,
          borderRadius: BorderRadius.circular(9),
          onTap: () => onChanged(s.tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    s.label,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(sel ? t.primaryColor : t.textColor, 14,
                        FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child:
                      Text(s.badge, style: _ts(badgeFg, 12, FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
      return Semantics(selected: sel, button: true, child: tile);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            expand ? Expanded(child: item(tabs[i])) : item(tabs[i]),
          ],
        ],
      ),
    );
  }
}

class SkSheet extends StatelessWidget {
  const SkSheet({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.scenarioCount,
    required this.testCount,
    required this.child,
    this.reportBadge = '0',
    this.reportHasFailures = false,
    this.onExport,
    this.onReset,
    this.onClose,
  });

  final SkTab activeTab;
  final ValueChanged<SkTab> onTabChanged;
  final int scenarioCount;
  final int testCount;
  final String reportBadge;
  final bool reportHasFailures;
  final VoidCallback? onExport;
  final VoidCallback? onReset;
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final tabs = [
      SkTabSpec(
        tab: SkTab.scenarios,
        label: 'Scenarios',
        badge: '$scenarioCount',
        testKey: const Key('panel_tab_scenarios'),
      ),
      SkTabSpec(
        tab: SkTab.tests,
        label: 'Tests',
        badge: '$testCount',
        testKey: const Key('panel_tab_tests'),
      ),
      SkTabSpec(
        tab: SkTab.reports,
        label: 'Reports',
        badge: reportBadge,
        warning: reportHasFailures,
        testKey: const Key('panel_tab_reports'),
      ),
    ];

    return ColoredBox(
      color: t.backgroundColor,
      child: Column(
        children: [
          Container(
            color: t.surfaceColor,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          LayoutBuilder(builder: (context, c) {
            final compact = _isCompact(c.maxWidth);
            final brand = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: t.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: t.onPrimaryColor, size: 19),
                ),
                const SizedBox(width: 10),
                Text('ScenarioKit',
                    style: _ts(t.textColor, 17, FontWeight.w700)),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onExport != null)
                  compact
                      ? _headerIcon(t, Icons.ios_share_rounded, 'Export',
                          onExport!,
                          key: const Key('panel_export_button'))
                      : OutlinedButton.icon(
                          key: const Key('panel_export_button'),
                          style: _outlinedStyle(t),
                          onPressed: onExport,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Export'),
                        ),
                if (onReset != null) ...[
                  const SizedBox(width: 8),
                  _headerIcon(t, Icons.restart_alt_rounded,
                      'Reset to default scenario', onReset!),
                ],
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  _headerIcon(t, Icons.close_rounded, 'Close', onClose!),
                ],
              ],
            );

            return Container(
              decoration: BoxDecoration(
                color: t.surfaceColor,
                border: Border(bottom: BorderSide(color: t.borderColor)),
              ),
              padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 24, 8, compact ? 16 : 24, 14),
              child: compact
                  ? Column(
                      children: [
                        Row(children: [
                          brand,
                          const Spacer(),
                          actions,
                        ]),
                        const SizedBox(height: 12),
                        SkSegmentedTabs(
                          tabs: tabs,
                          active: activeTab,
                          onChanged: onTabChanged,
                          expand: true,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        brand,
                        const SizedBox(width: 12),
                        Expanded(
                          child: SkSegmentedTabs(
                            tabs: tabs,
                            active: activeTab,
                            onChanged: onTabChanged,
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        actions,
                      ],
                    ),
            );
          }),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _headerIcon(ScenarioPanelThemeData t, IconData icon, String tip,
      VoidCallback onTap,
      {Key? key}) {
    return IconButton(
      key: key,
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: t.textColor),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        side: BorderSide(color: t.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

Future<T?> showScenarioKitSheet<T>({
  required BuildContext context,
  required ScenarioPanelThemeData theme,
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool isDismissible = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 880),
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final compact = size.width < 600;
      const radius = Radius.circular(22);
      final scheme = ColorScheme.fromSeed(
        seedColor: theme.primaryColor,
        brightness:
            ThemeData.estimateBrightnessForColor(theme.backgroundColor),
      ).copyWith(
        primary: theme.primaryColor,
        onPrimary: theme.onPrimaryColor,
        surface: theme.surfaceColor,
        error: theme.errorColor,
      );
      return Theme(
        data: ThemeData(useMaterial3: true, colorScheme: scheme),
        child: SkTheme(
          data: theme,
          child: Container(
            height: size.height * (compact ? 0.92 : 0.85),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x47141428),
                  blurRadius: 48,
                  offset: Offset(0, -12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: radius),
              child: Material(
                color: Colors.transparent,
                child: SafeArea(top: false, child: builder(ctx)),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SkFloatingPill extends StatelessWidget {
  const SkFloatingPill({
    super.key,
    required this.label,
    this.onTap,
    this.healthy = true,
    this.theme,
    this.showDragHint = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool healthy;
  final ScenarioPanelThemeData? theme;
  final bool showDragHint;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ScenarioPanelThemeData.light();
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: healthy ? t.successColor : t.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: t.tint(t.primaryColor, 34),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune_rounded, size: 16, color: t.primaryColor),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(t.textColor, 14, FontWeight.w600),
            ),
          ),
          if (showDragHint) ...[
            const SizedBox(width: 6),
            Icon(Icons.drag_indicator_rounded,
                size: 14, color: t.subtitleColor.withAlpha(100)),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      label: 'Open ScenarioKit, active scenario $label',
      child: Material(
        key: const Key('scenario_floating_trigger_button'),
        color: t.surfaceColor.withAlpha(240),
        elevation: 8,
        shadowColor: Colors.black38,
        shape: StadiumBorder(side: BorderSide(color: t.borderColor)),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

enum SkExportFormat { html, pdf }

enum SkDeviceFrame { phone, tablet, desktop }

class SkExportOptions {
  const SkExportOptions({
    required this.format,
    required this.device,
    required this.allScenarios,
    required this.includeNotes,
    required this.includeTests,
  });

  final SkExportFormat format;
  final SkDeviceFrame device;
  final bool allScenarios;
  final bool includeNotes;
  final bool includeTests;
}

Future<void> showSkExportSheet({
  required BuildContext context,
  required ScenarioPanelThemeData theme,
  required ValueChanged<SkExportOptions> onExport,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (ctx) => SkTheme(
      data: theme,
      child: _ExportSheet(onExport: onExport),
    ),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.onExport});

  final ValueChanged<SkExportOptions> onExport;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  SkExportFormat _format = SkExportFormat.html;
  SkDeviceFrame _device = SkDeviceFrame.phone;
  bool _all = true;
  bool _notes = true;
  bool _tests = false;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);

    Widget formatCard(SkExportFormat f, String title, String sub) {
      final sel = _format == f;
      return Expanded(
        child: Material(
          color: sel ? t.tint(t.primaryColor, 22) : t.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: sel ? t.primaryColor : t.borderColor,
              width: sel ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _format = f),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _ts(t.textColor, 14, FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: _ts(t.subtitleColor, 12, FontWeight.w400)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget check(String label, bool v, ValueChanged<bool> on) =>
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: t.primaryColor,
          value: v,
          onChanged: (x) => on(x ?? false),
          title: Text(label, style: _ts(t.textColor, 14, FontWeight.w400)),
        );

    return Container(
      decoration: BoxDecoration(
        color: t.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Export prototype',
                    style: _ts(t.textColor, 17, FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  formatCard(SkExportFormat.html, 'HTML', 'Interactive, one file'),
                  const SizedBox(width: 10),
                  formatCard(SkExportFormat.pdf, 'PDF', 'Print-ready pages'),
                ]),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<SkDeviceFrame>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: SkDeviceFrame.phone, label: Text('Phone')),
                      ButtonSegment(
                          value: SkDeviceFrame.tablet, label: Text('Tablet')),
                      ButtonSegment(
                          value: SkDeviceFrame.desktop, label: Text('Desktop')),
                    ],
                    selected: {_device},
                    onSelectionChanged: (s) =>
                        setState(() => _device = s.first),
                  ),
                ),
                const SizedBox(height: 8),
                check('All scenarios (not just the active one)', _all,
                    (v) => setState(() => _all = v)),
                check('Include notes and metadata', _notes,
                    (v) => setState(() => _notes = v)),
                check('Append test results', _tests,
                    (v) => setState(() => _tests = v)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(t),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onExport(SkExportOptions(
                        format: _format,
                        device: _device,
                        allScenarios: _all,
                        includeNotes: _notes,
                        includeTests: _tests,
                      ));
                    },
                    child: Text(_format == SkExportFormat.html
                        ? 'Export as HTML'
                        : 'Export as PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}