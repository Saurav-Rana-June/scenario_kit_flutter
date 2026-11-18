/// Controls how [ScenarioKit] combines a production [child] with [Scenario] builders.
enum ScenarioKitContentMode {
  /// Renders [ScenarioViewer] from registered scenarios (default when [child] is null).
  ///
  /// When a [child] is also provided, scenarios fully replace the child in the viewer.
  preview,

  /// Keeps [child] on screen; scenario selection only updates [ScenarioController]
  /// for [ScenarioStateAdapter] / [ScenarioStateBuilder] integrations.
  overlay,

  /// Uses [ScenarioViewer]: registers an implicit default scenario that builds [child],
  /// plus any additional scenarios from the [scenarios] list.
  hybrid,
}