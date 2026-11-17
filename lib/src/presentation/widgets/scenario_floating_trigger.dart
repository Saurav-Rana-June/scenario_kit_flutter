import 'package:flutter/material.dart';

import '../../core/scenario_controller.dart';
import '../../testing/registry/scenario_test_registry.dart';
import '../scenario_scope.dart';
import '../theme/scenario_panel_theme.dart';
import 'scenario_panel.dart';

/// Floating trigger badge that displays the active scenario and opens
/// the [ScenarioPanel] bottom sheet when tapped.
class ScenarioFloatingTrigger extends StatefulWidget {
  /// Creates a [ScenarioFloatingTrigger].
  const ScenarioFloatingTrigger({
    super.key,
    this.controller,
    this.testRegistry,
    this.theme,
    this.initialAlignment = Alignment.bottomRight,
    this.isDraggable = true,
  });

  /// Explicit controller to bind to. If omitted, resolves from [ScenarioScope.of(context)].
  final ScenarioController? controller;

  /// Optional test registry to bind to in Test Mode. If omitted, uses [ScenarioTestRegistry.instance].
  final ScenarioTestRegistry? testRegistry;

  /// Custom theme for the trigger and opened panel.
  final ScenarioPanelThemeData? theme;

  /// Initial screen alignment for the floating trigger. Defaults to [Alignment.bottomRight].
  final Alignment initialAlignment;

  /// Whether the user can drag the trigger around the screen. Defaults to `true`.
  final bool isDraggable;

  @override
  State<ScenarioFloatingTrigger> createState() =>
      _ScenarioFloatingTriggerState();
}

class _ScenarioFloatingTriggerState extends State<ScenarioFloatingTrigger> {
  Offset _dragOffset = Offset.zero;

  ScenarioPanelThemeData _resolveTheme(BuildContext context) {
    if (widget.theme != null) return widget.theme!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? ScenarioPanelThemeData.dark()
        : ScenarioPanelThemeData.light();
  }

  void _openPanel(BuildContext context, ScenarioController controller) {
    final panelTheme = _resolveTheme(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: panelTheme.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: panelTheme.borderRadius.topLeft,
              topRight: panelTheme.borderRadius.topRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: panelTheme.panelElevation,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ScenarioPanel(
              controller: controller,
              testRegistry: widget.testRegistry,
              theme: panelTheme,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ),
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
        final activeScenario = controller.selectedScenario;
        final label = activeScenario?.name ?? 'No Scenario';

        Widget triggerWidget = Material(
          key: const Key('scenario_floating_trigger_button'),
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPanel(context, controller),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: panelTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: panelTheme.borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeScenario != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: panelTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: panelTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (widget.isDraggable) {
          triggerWidget = GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _dragOffset += details.delta;
              });
            },
            child: Transform.translate(
              offset: _dragOffset,
              child: triggerWidget,
            ),
          );
        }

        return Align(
          alignment: widget.initialAlignment,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: triggerWidget,
          ),
        );
      },
    );
  }
}
