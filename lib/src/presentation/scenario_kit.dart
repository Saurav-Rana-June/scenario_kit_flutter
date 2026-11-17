import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../core/scenario_registry.dart';
import 'scenario_scope.dart';
import 'scenario_viewer.dart';
import 'theme/scenario_panel_theme.dart';
import 'widgets/scenario_floating_trigger.dart';

/// The top-level developer wrapper for ScenarioKit.
///
/// Wraps application screens or [ScenarioViewer] with developer-friendly scenario
/// switching controls and an interactive floating trigger.
///
/// Automatically disabled in release mode by default (`enabled: kDebugMode`), ensuring
/// zero debug UI overhead in production builds.
class ScenarioKit extends StatefulWidget {
  /// Creates a [ScenarioKit] wrapper.
  ///
  /// Provide scenarios via [scenarios], [registry], or [controller].
  /// If [child] is provided, it is displayed with the floating trigger overlay.
  /// If [child] is omitted, [ScenarioViewer] is rendered to preview registered scenarios.
  const ScenarioKit({
    super.key,
    this.scenarios,
    this.registry,
    this.controller,
    this.child,
    this.initialScenarioId,
    this.enabled = kDebugMode,
    this.showFloatingTrigger = true,
    this.floatingTriggerAlignment = Alignment.bottomRight,
    this.theme,
    this.emptyBuilder,
  }) : assert(
          child != null ||
              scenarios != null ||
              registry != null ||
              controller != null,
          'Must provide either child, scenarios, registry, or controller to ScenarioKit.',
        );

  /// Scenarios to make available in this scope.
  final List<Scenario>? scenarios;

  /// Custom [ScenarioRegistry].
  final ScenarioRegistry? registry;

  /// Explicit [ScenarioController].
  final ScenarioController? controller;

  /// Screen or widget to wrap. If `null`, [ScenarioViewer] is displayed.
  final Widget? child;

  /// ID of the initial scenario to select.
  final String? initialScenarioId;

  /// Whether the ScenarioKit developer overlay and controls are enabled.
  ///
  /// Defaults to [kDebugMode] so preview panels are excluded in production release builds.
  final bool enabled;

  /// Whether to display the interactive floating trigger button. Defaults to `true`.
  final bool showFloatingTrigger;

  /// Initial alignment of the floating trigger. Defaults to [Alignment.bottomRight].
  final Alignment floatingTriggerAlignment;

  /// Custom developer theme for the panels and floating trigger.
  final ScenarioPanelThemeData? theme;

  /// Widget builder shown when no scenarios are available.
  final WidgetBuilder? emptyBuilder;

  @override
  State<ScenarioKit> createState() => _ScenarioKitState();
}

class _ScenarioKitState extends State<ScenarioKit> {
  late ScenarioController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else if (widget.registry != null) {
      _controller = ScenarioController(
        registry: widget.registry,
        initialScenarioId: widget.initialScenarioId,
      );
      _ownsController = true;
    } else {
      _controller = ScenarioController.fromScenarios(
        widget.scenarios ?? const [],
        initialScenarioId: widget.initialScenarioId,
      );
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(covariant ScenarioKit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If disabled (e.g. in release mode), render child without developer overlays
    if (!widget.enabled) {
      if (widget.child != null) return widget.child!;
      return ScenarioViewer(
        controller: _controller,
        emptyBuilder: widget.emptyBuilder,
      );
    }

    final content = widget.child ??
        ScenarioViewer(
          controller: _controller,
          emptyBuilder: widget.emptyBuilder,
        );

    if (!widget.showFloatingTrigger) {
      return ScenarioScope(
        notifier: _controller,
        child: content,
      );
    }

    return ScenarioScope(
      notifier: _controller,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          ScenarioFloatingTrigger(
            controller: _controller,
            theme: widget.theme,
            initialAlignment: widget.floatingTriggerAlignment,
          ),
        ],
      ),
    );
  }
}
