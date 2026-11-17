import 'package:flutter/material.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../core/scenario_registry.dart';
import 'scenario_scope.dart';

/// Renders the active scenario and provides smooth animated transitions
/// when switching between scenarios.
class ScenarioViewer extends StatefulWidget {
  /// Creates a [ScenarioViewer].
  ///
  /// You can provide scenarios via [scenarios], [registry], or an explicit [controller].
  /// If [controller] is provided, it takes precedence.
  const ScenarioViewer({
    super.key,
    this.scenarios,
    this.registry,
    this.controller,
    this.initialScenarioId,
    this.emptyBuilder,
    this.animationDuration = const Duration(milliseconds: 250),
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
  }) : assert(
          controller != null || registry != null || scenarios != null,
          'Must provide either controller, registry, or scenarios to ScenarioViewer.',
        );

  /// Scenarios to display. Used when [controller] and [registry] are omitted.
  final List<Scenario>? scenarios;

  /// Custom [ScenarioRegistry]. Used when [controller] is omitted.
  final ScenarioRegistry? registry;

  /// Explicit [ScenarioController] to manage scenario selection.
  final ScenarioController? controller;

  /// ID of the scenario to display initially.
  final String? initialScenarioId;

  /// Widget builder shown when no scenarios are available or registered.
  final WidgetBuilder? emptyBuilder;

  /// Duration of the scenario switch transition. Defaults to 250ms.
  final Duration animationDuration;

  /// Transition animation builder for scenario switching.
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  @override
  State<ScenarioViewer> createState() => _ScenarioViewerState();
}

class _ScenarioViewerState extends State<ScenarioViewer> {
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
  void didUpdateWidget(covariant ScenarioViewer oldWidget) {
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

  Widget _buildDefaultEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No Scenario Available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Register at least one scenario to preview UI states.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScenarioScope(
      notifier: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final selectedScenario = _controller.selectedScenario;
          final Widget content;

          if (selectedScenario != null) {
            content = KeyedSubtree(
              key: ValueKey<String>(selectedScenario.id),
              child: Builder(builder: selectedScenario.builder),
            );
          } else {
            content = KeyedSubtree(
              key: const ValueKey<String>('__empty_scenario__'),
              child: widget.emptyBuilder != null
                  ? widget.emptyBuilder!(context)
                  : _buildDefaultEmpty(context),
            );
          }

          return AnimatedSwitcher(
            duration: widget.animationDuration,
            transitionBuilder: widget.transitionBuilder,
            child: content,
          );
        },
      ),
    );
  }
}
