part of 'scenario_kit_ui.dart';

class SkChip extends StatelessWidget {
  const SkChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.small = false,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final fg = selected ? t.onPrimaryColor : t.textColor;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.primaryColor : t.surfaceColor,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? t.primaryColor : t.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 14,
              vertical: small ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: _ts(fg, small ? 12.5 : 13.5, FontWeight.w600)),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.onPrimaryColor.withAlpha(60)
                          : t.chipColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child:
                        Text('$count', style: _ts(fg, 12, FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkChipRow extends StatelessWidget {
  const SkChipRow({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SkSearchField extends StatefulWidget {
  const SkSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.showSlashHint = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final bool showSlashHint;

  @override
  State<SkSearchField> createState() => _SkSearchFieldState();
}

class _SkSearchFieldState extends State<SkSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    Widget? suffix;
    if (_controller.text.isNotEmpty) {
      suffix = IconButton(
        tooltip: 'Clear search',
        icon: Icon(Icons.close_rounded, color: t.subtitleColor, size: 20),
        onPressed: () {
          _controller.clear();
          widget.onChanged('');
          setState(() {});
        },
      );
    } else if (widget.showSlashHint) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.chipColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('/', style: _mono(t.subtitleColor, 12)),
          ),
        ),
      );
    }
    return TextField(
      controller: _controller,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      style: _ts(t.textColor, 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: _ts(t.subtitleColor, 15, FontWeight.w400),
        prefixIcon:
            Icon(Icons.search_rounded, color: t.subtitleColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: t.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(t.borderColor),
        enabledBorder: border(t.borderColor),
        focusedBorder: border(t.primaryColor, 2),
      ),
    );
  }
}

Color _statusColor(ScenarioPanelThemeData t, SkStatus s) {
  switch (s) {
    case SkStatus.passed:
      return t.successColor;
    case SkStatus.failed:
      return t.errorColor;
    case SkStatus.running:
      return t.primaryColor;
    case SkStatus.skipped:
      return t.warningColor;
    case SkStatus.idle:
      return t.subtitleColor;
  }
}

String _statusLabel(SkStatus s) {
  switch (s) {
    case SkStatus.passed:
      return 'PASSED';
    case SkStatus.failed:
      return 'FAILED';
    case SkStatus.running:
      return 'RUNNING';
    case SkStatus.skipped:
      return 'SKIPPED';
    case SkStatus.idle:
      return 'NOT RUN';
  }
}

Color _stepColor(ScenarioPanelThemeData t, SkStepState s) {
  switch (s) {
    case SkStepState.passed:
      return t.successColor;
    case SkStepState.failed:
      return t.errorColor;
    case SkStepState.skipped:
    case SkStepState.idle:
      return t.neutralBar;
  }
}

class SkStatusPill extends StatelessWidget {
  const SkStatusPill(this.status, {super.key});

  final SkStatus status;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    final c = _statusColor(t, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.tint(c, 28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(90)),
      ),
      child: Text(
        _statusLabel(status),
        style: _ts(t.deep(c), 11.5, FontWeight.w700),
      ),
    );
  }
}

class SkEmptyState extends StatelessWidget {
  const SkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final t = SkTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: t.tint(t.primaryColor, 24),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: t.primaryColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: _ts(t.textColor, 16, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: _ts(t.subtitleColor, 14, FontWeight.w400, 1.45)),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                key: actionKey,
                style: _filledStyle(t),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}