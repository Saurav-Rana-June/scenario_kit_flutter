/// Optional persistence for the last selected scenario ID (e.g. dev tools restore).
abstract class ScenarioSelectionPersistence {
  /// Restores the last selected scenario ID, or `null` to use registry default.
  Future<String?> loadLastScenarioId();

  /// Persists [scenarioId] whenever the user or code switches scenarios.
  Future<void> saveLastScenarioId(String scenarioId);
}

/// In-memory persistence (resets when the process ends).
class InMemoryScenarioSelectionPersistence
    implements ScenarioSelectionPersistence {
  String? _lastId;

  @override
  Future<String?> loadLastScenarioId() async => _lastId;

  @override
  Future<void> saveLastScenarioId(String scenarioId) async {
    _lastId = scenarioId;
  }
}
