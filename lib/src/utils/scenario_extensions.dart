import 'package:flutter/widgets.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../models/mock_data.dart';
import '../presentation/scenario_scope.dart';

/// Extension methods for retrieving strongly typed mock data and metadata from a [Scenario].
extension ScenarioMockExtensions on Scenario {
  /// Default metadata key where mock data is stored.
  static const String defaultMockKey = 'mock_data';

  /// Default metadata key where simulated delay duration is stored.
  static const String simulatedDelayKey = 'simulated_delay';

  /// Retrieves the typed mock value of type [T] from [metadata].
  ///
  /// Automatically resolves values wrapped inside a [MockData] container.
  /// Returns `null` if the key does not exist or cannot be cast to [T].
  T? getMock<T>([String key = defaultMockKey]) {
    final entry = metadata[key];
    if (entry == null) return null;

    if (entry is MockData<T>) {
      return entry.value;
    }
    if (entry is MockData) {
      final val = entry.value;
      if (val is T) return val;
    }
    if (entry is T) {
      return entry;
    }
    return null;
  }

  /// Retrieves the [MockData] container of type [T] from [metadata].
  MockData<T>? getMockContainer<T>([String key = defaultMockKey]) {
    final entry = metadata[key];
    if (entry is MockData<T>) {
      return entry;
    }
    return null;
  }

  /// Whether this scenario includes mock data under [key].
  bool hasMock([String key = defaultMockKey]) => metadata.containsKey(key);

  /// Optional simulated delay duration specified for this scenario.
  Duration? get simulatedDelay {
    final delay = metadata[simulatedDelayKey];
    if (delay is Duration) return delay;
    return null;
  }
}

/// Extension methods on [BuildContext] for effortless ScenarioKit access.
extension ScenarioContextExtensions on BuildContext {
  /// Returns the closest [ScenarioController] ancestor.
  ScenarioController get scenarioController => ScenarioScope.of(this);

  /// Returns the closest [ScenarioController] ancestor, or `null`.
  ScenarioController? get maybeScenarioController =>
      ScenarioScope.maybeOf(this);

  /// Returns the currently active [Scenario] in this tree, or `null`.
  Scenario? get currentScenario => ScenarioScope.selectedScenarioOf(this);
}
