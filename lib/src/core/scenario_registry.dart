import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'scenario.dart';
import 'scenario_exceptions.dart';

/// Registry responsible for storing, organizing, and querying [Scenario] instances.
///
/// Implements [ChangeNotifier] so previewers and developer toolbars can reactively
/// rebuild when scenarios are registered, unregistered, or modified.
class ScenarioRegistry extends ChangeNotifier {
  /// Creates a [ScenarioRegistry].
  ///
  /// Optionally populates the registry with [initialScenarios].
  ScenarioRegistry([Iterable<Scenario>? initialScenarios]) {
    if (initialScenarios != null) {
      registerAll(initialScenarios);
    }
  }

  static ScenarioRegistry? _instance;

  /// Global ambient instance for simple or single-registry applications.
  ///
  /// For modularity and testability, prefer instantiating separate [ScenarioRegistry]
  /// instances and passing them where needed.
  static ScenarioRegistry get instance => _instance ??= ScenarioRegistry();

  /// Resets the global ambient instance. Mainly useful in testing environments.
  @visibleForTesting
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  final Map<String, Scenario> _scenarios = <String, Scenario>{};

  /// Returns an unmodifiable list of all registered scenarios in registration order.
  List<Scenario> get scenarios =>
      UnmodifiableListView<Scenario>(_scenarios.values);

  /// Number of registered scenarios.
  int get length => _scenarios.length;

  /// Whether the registry contains zero scenarios.
  bool get isEmpty => _scenarios.isEmpty;

  /// Whether the registry contains at least one scenario.
  bool get isNotEmpty => _scenarios.isNotEmpty;

  /// Returns the default scenario.
  ///
  /// Resolves to the first scenario explicitly marked with [Scenario.isDefault],
  /// or falls back to the first registered scenario. Returns `null` if empty.
  Scenario? get defaultScenario {
    if (_scenarios.isEmpty) return null;
    return _scenarios.values.firstWhere(
      (s) => s.isDefault,
      orElse: () => _scenarios.values.first,
    );
  }

  /// Returns a sorted list of all unique group names present in this registry.
  List<String> get groups {
    final groupSet = <String>{};
    for (final scenario in _scenarios.values) {
      if (scenario.group != null && scenario.group!.trim().isNotEmpty) {
        groupSet.add(scenario.group!.trim());
      }
    }
    final list = groupSet.toList()..sort();
    return UnmodifiableListView<String>(list);
  }

  /// Returns a map grouping scenarios by their group name.
  ///
  /// Scenarios without a group appear under the `null` key.
  Map<String?, List<Scenario>> get scenariosByGroup {
    final map = <String?, List<Scenario>>{};
    for (final scenario in _scenarios.values) {
      final key = scenario.group?.trim();
      map.putIfAbsent(key, () => <Scenario>[]).add(scenario);
    }
    return Map<String?, List<Scenario>>.unmodifiable(
      map.map((k, v) => MapEntry(k, UnmodifiableListView<Scenario>(v))),
    );
  }

  /// Registers a new [Scenario].
  ///
  /// Throws [DuplicateScenarioException] if a scenario with the same ID
  /// is already registered.
  void register(Scenario scenario) {
    if (_scenarios.containsKey(scenario.id)) {
      throw DuplicateScenarioException(scenario.id);
    }
    _scenarios[scenario.id] = scenario;
    notifyListeners();
  }

  /// Registers multiple scenarios atomically.
  ///
  /// Throws [DuplicateScenarioException] if duplicate IDs are present in
  /// [scenarios] or if any ID is already registered, leaving existing registrations intact.
  void registerAll(Iterable<Scenario> scenarios) {
    final seenNewIds = <String>{};
    for (final scenario in scenarios) {
      if (_scenarios.containsKey(scenario.id) || !seenNewIds.add(scenario.id)) {
        throw DuplicateScenarioException(scenario.id);
      }
    }

    for (final scenario in scenarios) {
      _scenarios[scenario.id] = scenario;
    }
    notifyListeners();
  }

  /// Unregisters the scenario with [id].
  ///
  /// Returns `true` if a scenario was removed, or `false` if not found.
  bool unregister(String id) {
    final removed = _scenarios.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Clears all scenarios from the registry.
  void clear() {
    if (_scenarios.isEmpty) return;
    _scenarios.clear();
    notifyListeners();
  }

  /// Returns the scenario with [id], or `null` if not found.
  Scenario? getById(String id) => _scenarios[id];

  /// Returns the scenario with [id], or throws [ScenarioNotFoundException].
  Scenario requireById(String id) {
    final scenario = _scenarios[id];
    if (scenario == null) {
      throw ScenarioNotFoundException(id);
    }
    return scenario;
  }

  /// Returns `true` if a scenario with [id] is registered.
  bool hasScenario(String id) => _scenarios.containsKey(id);

  /// Returns all scenarios matching [group].
  List<Scenario> getByGroup(String? group) {
    final target = group?.trim();
    final matches = _scenarios.values.where((s) => s.group?.trim() == target);
    return UnmodifiableListView<Scenario>(matches.toList());
  }
}
