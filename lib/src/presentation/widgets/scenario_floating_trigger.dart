import 'dart:ui';

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
    final size = MediaQuery.of(context).size;
    final isStudioMode = size.width >= 800;

    if (isStudioMode) {
      showDialog<void>(
        context: context,
        barrierColor: const Color(0x732A2A44),
        builder: (dialogContext) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 1020,
                height: 800,
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.94,
                  maxHeight: size.height * 0.94,
                ),
                decoration: BoxDecoration(
                  color: panelTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x73000000),
                      blurRadius: 80,
                      offset: Offset(0, 24),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ScenarioPanel(
                  controller: controller,
                  testRegistry: widget.testRegistry,
                  theme: panelTheme,
                  testExecutionContext: context,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: panelTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: panelTheme.panelElevation * 2,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: ScenarioPanel(
                controller: controller,
                testRegistry: widget.testRegistry,
                theme: panelTheme,
                testExecutionContext: context,
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
            ),
          );
        },
      );
    }
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
        final statusColor = activeScenario != null
            ? panelTheme.successColor
            : panelTheme.errorColor;

        Widget triggerWidget = Material(
          key: const Key('scenario_floating_trigger_button'),
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPanel(context, controller),
            borderRadius: BorderRadius.circular(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: panelTheme.surfaceColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: panelTheme.borderColor.withValues(alpha: 0.9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: panelTheme.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
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
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color:
                              panelTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: panelTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: panelTheme.textColor,
                          ),
                        ),
                      ),
                      if (widget.isDraggable) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.drag_indicator_rounded,
                          size: 14,
                          color:
                              panelTheme.subtitleColor.withValues(alpha: 0.4),
                        ),
                      ],
                    ],
                  ),
                ),
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
