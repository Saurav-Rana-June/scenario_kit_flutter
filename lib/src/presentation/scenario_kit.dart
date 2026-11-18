import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/scenario.dart';
import '../core/scenario_content_mode.dart';
import '../core/scenario_controller.dart';
import '../core/scenario_persistence.dart';
import '../core/scenario_registry.dart';
import '../testing/registry/scenario_test_registry.dart';
import '../testing/screenshot/scenario_repaint_boundary.dart';
import '../testing/screenshot/scenario_screenshot_service.dart';
import 'scenario_kit_bindings.dart';
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
  ///
  /// **Content modes**
  /// - Without [child]: renders [ScenarioViewer] from scenarios ([ScenarioKitContentMode.preview]).
  /// - With [child] only: keeps [child] visible; scenario picker updates [ScenarioController] for adapters ([ScenarioKitContentMode.overlay]).
  /// - With [child] and [scenarios]: [ScenarioKitContentMode.hybrid] registers [child] as a default scenario and previews all states via [ScenarioViewer].
  const ScenarioKit({
    super.key,
    this.scenarios,
    this.registry,
    this.controller,
    this.child,
    this.contentMode,
    this.initialScenarioId,
    this.enabled = kDebugMode,
    this.showFloatingTrigger = true,
    this.floatingTriggerAlignment = Alignment.bottomRight,
    this.theme,
    this.emptyBuilder,
    this.testRegistry,
    this.persistence,
    this.hideOverlayWhileTestsRun = true,
    this.screenName,
    this.onNavigateToScreen,
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

  /// Screen or widget to wrap. Interpretation depends on [contentMode].
  final Widget? child;

  /// How [child] and [scenarios] are combined. Inferred when omitted.
  final ScenarioKitContentMode? contentMode;

  /// ID of the initial scenario to select.
  final String? initialScenarioId;

  /// Whether the ScenarioKit developer overlay and controls are enabled.
  final bool enabled;

  /// Whether to display the interactive floating trigger button.
  final bool showFloatingTrigger;

  /// Initial alignment of the floating trigger.
  final Alignment floatingTriggerAlignment;

  /// Custom developer theme for the panels and floating trigger.
  final ScenarioPanelThemeData? theme;

  /// Widget builder shown when no scenarios are available.
  final WidgetBuilder? emptyBuilder;

  /// Optional test registry to bind to in Test Mode.
  final ScenarioTestRegistry? testRegistry;

  /// Optional persistence for last selected scenario ID.
  final ScenarioSelectionPersistence? persistence;

  /// Hides the floating trigger while functional tests are executing.
  final bool hideOverlayWhileTestsRun;

  /// Name of the screen wrapped by this [ScenarioKit] (e.g. `Dashboard Screen`).
  ///
  /// Used by Test Mode to pre-select matching tests and warn on screen mismatch.
  final String? screenName;

  /// Optional callback when the user chooses **Go to Screen** for another suite.
  final void Function(String screenName)? onNavigateToScreen;

  @override
  State<ScenarioKit> createState() => _ScenarioKitState();
}

class _ScenarioKitState extends State<ScenarioKit> {
  late ScenarioController _controller;
  bool _ownsController = false;
  final GlobalKey _screenshotBoundaryKey = GlobalKey();
  final GlobalKey _appContentKey = GlobalKey();
  late final ScenarioScreenshotService _screenshotService;
  final ValueNotifier<bool> _testsRunning = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _screenshotService = ScenarioScreenshotService(
      boundaryKey: _screenshotBoundaryKey,
    );
    _initController();
    _restorePersistedScenario();
  }

  ScenarioKitContentMode get _resolvedContentMode {
    if (widget.contentMode != null) return widget.contentMode!;
    if (widget.child == null) return ScenarioKitContentMode.preview;
    if (widget.scenarios != null && widget.scenarios!.isNotEmpty) {
      return ScenarioKitContentMode.hybrid;
    }
    return ScenarioKitContentMode.overlay;
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      return;
    }

    if (widget.registry != null) {
      _controller = ScenarioController(
        registry: widget.registry,
        initialScenarioId: widget.initialScenarioId,
        persistence: widget.persistence,
      );
      _ownsController = true;
      return;
    }

    final scenarios = _buildEffectiveScenarios();
    _controller = ScenarioController.fromScenarios(
      scenarios,
      initialScenarioId: widget.initialScenarioId,
      persistence: widget.persistence,
    );
    _ownsController = true;
  }

  List<Scenario> _buildEffectiveScenarios() {
    final input = widget.scenarios ?? const <Scenario>[];
    if (widget.child == null ||
        _resolvedContentMode != ScenarioKitContentMode.hybrid) {
      return input;
    }

    final childScenario = Scenario.success(
      id: 'production_child',
      name: 'Production Screen',
      description: 'Wrapped production widget',
      isDefault: input.every((s) => !s.isDefault),
      builder: (context) => widget.child!,
    );

    final combined = <Scenario>[childScenario, ...input];
    return combined;
  }

  Future<void> _restorePersistedScenario() async {
    final persistence = widget.persistence;
    if (persistence == null || !_ownsController) return;
    final id = await persistence.loadLastScenarioId();
    if (!mounted || id == null) return;
    _controller.trySelectById(id);
  }

  @override
  void didUpdateWidget(covariant ScenarioKit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = widget.controller != oldWidget.controller;
    final scenariosChanged = widget.scenarios != oldWidget.scenarios;
    final childChanged = widget.child != oldWidget.child;
    final modeChanged = widget.contentMode != oldWidget.contentMode;

    if (controllerChanged) {
      if (_ownsController) {
        _controller.dispose();
      }
      _initController();
      return;
    }

    if (_ownsController && (scenariosChanged || childChanged || modeChanged)) {
      _controller.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _testsRunning.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Widget _buildContent() {
    switch (_resolvedContentMode) {
      case ScenarioKitContentMode.preview:
      case ScenarioKitContentMode.hybrid:
        return ScenarioViewer(
          controller: _controller,
          emptyBuilder: widget.emptyBuilder,
          wrapWithScope: false,
        );
      case ScenarioKitContentMode.overlay:
        return widget.child ??
            ScenarioViewer(
              controller: _controller,
              emptyBuilder: widget.emptyBuilder,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      final content = widget.child ?? _buildContent();
      return ScenarioRepaintBoundary(
        boundaryKey: _screenshotBoundaryKey,
        child: ScenarioScope(
          controller: _controller,
          screenName: widget.screenName,
          onNavigateToScreen: widget.onNavigateToScreen,
          child: content,
        ),
      );
    }

    final content = ScenarioRepaintBoundary(
      boundaryKey: _screenshotBoundaryKey,
      child: KeyedSubtree(
        key: _appContentKey,
        child: _buildContent(),
      ),
    );

    final body = !widget.showFloatingTrigger
        ? content
        : Stack(
            fit: StackFit.passthrough,
            children: [
              content,
              ValueListenableBuilder<bool>(
                valueListenable: _testsRunning,
                builder: (context, running, _) {
                  final hidden = widget.hideOverlayWhileTestsRun && running;
                  return IgnorePointer(
                    ignoring: hidden,
                    child: Opacity(
                      opacity: hidden ? 0 : 1,
                      child: ScenarioFloatingTrigger(
                        controller: _controller,
                        testRegistry: widget.testRegistry,
                        theme: widget.theme,
                        initialAlignment: widget.floatingTriggerAlignment,
                        screenName: widget.screenName,
                        onNavigateToScreen: widget.onNavigateToScreen,
                      ),
                    ),
                  );
                },
              ),
            ],
          );

    return ScenarioScope(
      controller: _controller,
      screenName: widget.screenName,
      onNavigateToScreen: widget.onNavigateToScreen,
      child: ScenarioKitBindings(
        screenshotBoundaryKey: _screenshotBoundaryKey,
        appContentKey: _appContentKey,
        screenshotService: _screenshotService,
        testsRunning: _testsRunning,
        child: body,
      ),
    );
  }
}
