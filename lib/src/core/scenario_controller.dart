import 'package:flutter/foundation.dart';

import 'scenario.dart';
import 'scenario_exceptions.dart';
import 'scenario_persistence.dart';
import 'scenario_registry.dart';

/// Controller responsible for managing the active [Scenario] selection.
///
/// Listens to its backing [ScenarioRegistry] and automatically adjusts selection
/// if the currently active scenario is removed or updated.
class ScenarioController extends ChangeNotifier {
  /// Creates a [ScenarioController].
  ///
  /// If [registry] is omitted, an empty [ScenarioRegistry] is created.
  /// If [initialScenarioId] is provided, attempts to select that scenario initially;
  /// otherwise defaults to [ScenarioRegistry.defaultScenario].
  ScenarioController({
    ScenarioRegistry? registry,
    String? initialScenarioId,
    this.persistence,
  })  : _registry = registry ?? ScenarioRegistry(),
        _ownsRegistry = registry == null {
    _registry.addListener(_handleRegistryChanged);

    if (initialScenarioId != null) {
      _selectedScenario =
          _registry.getById(initialScenarioId) ?? _registry.defaultScenario;
    } else {
      _selectedScenario = _registry.defaultScenario;
    }
  }

  /// Creates a [ScenarioController] populated with [scenarios].
  factory ScenarioController.fromScenarios(
    Iterable<Scenario> scenarios, {
    String? initialScenarioId,
    ScenarioSelectionPersistence? persistence,
  }) {
    final registry = ScenarioRegistry(scenarios);
    return ScenarioController(
      registry: registry,
      initialScenarioId: initialScenarioId,
      persistence: persistence,
    );
  }

  /// Optional hook to restore / persist the active scenario across sessions.
  final ScenarioSelectionPersistence? persistence;

  final ScenarioRegistry _registry;
  final bool _ownsRegistry;

  Scenario? _selectedScenario;
  bool _isDisposed = false;

  /// The backing [ScenarioRegistry] containing available scenarios.
  ScenarioRegistry get registry => _registry;

  /// Currently selected [Scenario], or `null` if the registry is empty.
  Scenario? get selectedScenario => _selectedScenario;

  /// Unique identifier of the currently selected scenario, or `null`.
  String? get selectedId => _selectedScenario?.id;

  /// Whether [scenario] is currently active.
  bool isSelected(Scenario scenario) => _selectedScenario?.id == scenario.id;

  /// Whether scenario with [id] is currently active.
  bool isSelectedId(String id) => _selectedScenario?.id == id;

  /// Selects [scenario].
  ///
  /// Automatically registers [scenario] into [registry] if not already present.
  void select(Scenario scenario) {
    if (!_registry.hasScenario(scenario.id)) {
      _registry.register(scenario);
    }
    _updateSelection(scenario);
  }

  /// Selects scenario with [id].
  ///
  /// Throws [ScenarioNotFoundException] if [id] is not registered.
  void selectById(String id) {
    final scenario = _registry.requireById(id);
    _updateSelection(scenario);
  }

  /// Selects scenario with [id] if it exists, without throwing.
  ///
  /// Returns `true` if selected, or `false` if not found.
  bool trySelectById(String id) {
    final scenario = _registry.getById(id);
    if (scenario != null) {
      _updateSelection(scenario);
      return true;
    }
    return false;
  }

  /// Resets selection to [ScenarioRegistry.defaultScenario].
  void resetToDefault() {
    _updateSelection(_registry.defaultScenario);
  }

  void _updateSelection(Scenario? newSelection) {
    if (_isDisposed || _selectedScenario == newSelection) return;
    _selectedScenario = newSelection;
    if (newSelection != null && persistence != null) {
      persistence!.saveLastScenarioId(newSelection.id);
    }
    notifyListeners();
  }

  void _handleRegistryChanged() {
    if (_isDisposed) return;

    if (_selectedScenario != null) {
      final updated = _registry.getById(_selectedScenario!.id);
      if (updated != null) {
        if (updated != _selectedScenario) {
          _updateSelection(updated);
        }
        return;
      }
    }

    // Previous selection no longer exists; fall back to default scenario
    _updateSelection(_registry.defaultScenario);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _registry.removeListener(_handleRegistryChanged);
    if (_ownsRegistry) {
      _registry.dispose();
    }
    super.dispose();
  }
}
