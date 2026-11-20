import 'package:flutter/material.dart';

import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../../utils/scenario_panel_host.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_kit_ui.dart';
import 'scenario_panel.dart';

/// Floating trigger badge that displays the active scenario and opens
/// the [ScenarioPanel] bottom sheet when tapped.
class ScenarioFloatingTrigger extends StatefulWidget {
  const ScenarioFloatingTrigger({
    super.key,
    this.controller,
    this.testRegistry,
    this.theme,
    this.initialAlignment = Alignment.bottomRight,
    this.isDraggable = true,
    this.screenName,
    this.onNavigateToScreen,
  });

  final ScenarioController? controller;
  final ScenarioTestRegistry? testRegistry;
  final ScenarioPanelThemeData? theme;
  final Alignment initialAlignment;
  final bool isDraggable;
  final String? screenName;
  final void Function(String screenName)? onNavigateToScreen;

  @override
  State<ScenarioFloatingTrigger> createState() =>
      _ScenarioFloatingTriggerState();
}

class _ScenarioFloatingTriggerState extends State<ScenarioFloatingTrigger> {
  static const _edgeMargin = 16.0;

  final GlobalKey _pillKey = GlobalKey();

  /// Top-left position of the pill in the overlay [Stack] (after layout).
  Offset? _position;
  bool _placedFromAlignment = false;

  ScenarioPanelThemeData _resolveTheme(BuildContext context) {
    return widget.theme ?? ScenarioPanelThemeData.light();
  }

  void _openPanel(BuildContext context, ScenarioController controller) {
    final panelTheme = _resolveTheme(context);
    final modalContext = ScenarioPanelHost.modalContext(context);
    showScenarioKitSheet<void>(
      context: modalContext,
      theme: panelTheme,
      isDismissible: false,
      builder: (sheetContext) => ScenarioPanel(
        controller: controller,
        testRegistry: widget.testRegistry,
        theme: panelTheme,
        testExecutionContext: context,
        screenName: widget.screenName,
        onNavigateToScreen: widget.onNavigateToScreen,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  Offset _positionForAlignment(
    Alignment alignment,
    Size area,
    Size pill,
    EdgeInsets safe,
  ) {
    final minX = safe.left + _edgeMargin;
    final minY = safe.top + _edgeMargin;
    final maxX = area.width - safe.right - _edgeMargin - pill.width;
    final maxY = area.height - safe.bottom - _edgeMargin - pill.height;
    final spanX = (maxX - minX).clamp(0.0, double.infinity);
    final spanY = (maxY - minY).clamp(0.0, double.infinity);
    final tX = (alignment.x + 1) / 2;
    final tY = (alignment.y + 1) / 2;
    return Offset(minX + spanX * tX, minY + spanY * tY);
  }

  double _clampAxis(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max);
  }

  void _clampPosition(Size area, Size pill, EdgeInsets safe) {
    final pos = _position;
    if (pos == null) return;
    final minX = safe.left + _edgeMargin;
    final minY = safe.top + _edgeMargin;
    final maxX = area.width - safe.right - _edgeMargin - pill.width;
    final maxY = area.height - safe.bottom - _edgeMargin - pill.height;
    _position = Offset(
      _clampAxis(pos.dx, minX, maxX),
      _clampAxis(pos.dy, minY, maxY),
    );
  }

  void _ensurePosition(Size area) {
    if (_placedFromAlignment) return;
    final box =
        _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pillSize = box.size;
    final safe = MediaQuery.paddingOf(context);
    setState(() {
      _position = _positionForAlignment(
        widget.initialAlignment,
        area,
        pillSize,
        safe,
      );
      _placedFromAlignment = true;
      _clampPosition(area, pillSize, safe);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size area) {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pillSize = box.size;
    final safe = MediaQuery.paddingOf(context);

    setState(() {
      _position = (_position ?? Offset.zero) + details.delta;
      _clampPosition(area, pillSize, safe);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? ScenarioScope.of(context);
    final panelTheme = _resolveTheme(context);

    return SafeArea(
      top: false,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Size(constraints.maxWidth, constraints.maxHeight);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _ensurePosition(area);
            });

            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final activeScenario = controller.selectedScenario;
                final label = activeScenario?.name ?? 'No Scenario';
                final healthy = activeScenario != null;

                final pill = SkFloatingPill(
                  label: label,
                  healthy: healthy,
                  theme: panelTheme,
                  showDragHint: widget.isDraggable,
                  onTap: widget.isDraggable
                      ? null
                      : () => _openPanel(context, controller),
                );

                Widget interactive = pill;
                if (widget.isDraggable) {
                  interactive = GestureDetector(
                    key: _pillKey,
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => _onPanUpdate(d, area),
                    onTap: () => _openPanel(context, controller),
                    child: pill,
                  );
                } else {
                  interactive = KeyedSubtree(
                    key: _pillKey,
                    child: pill,
                  );
                }

                final pos = _position;
                if (pos == null) {
                  return Offstage(
                    child: interactive,
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      child: interactive,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}