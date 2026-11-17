/// Base exception for all ScenarioKit errors.
abstract class ScenarioException implements Exception {
  /// Creates a [ScenarioException] with the given [message].
  const ScenarioException(this.message);

  /// Detailed error message.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when attempting to register a scenario with an ID that is already registered.
class DuplicateScenarioException extends ScenarioException {
  /// Creates a [DuplicateScenarioException] with the conflicting [id].
  DuplicateScenarioException(this.id)
      : super(
            'A scenario with ID "$id" is already registered in this registry.');

  /// The conflicting scenario identifier.
  final String id;
}

/// Thrown when a requested scenario cannot be found in the registry.
class ScenarioNotFoundException extends ScenarioException {
  /// Creates a [ScenarioNotFoundException] with the missing [id].
  ScenarioNotFoundException(this.id)
      : super('Scenario with ID "$id" was not found in the registry.');

  /// The missing scenario identifier.
  final String id;
}

/// Thrown when scenario definition parameters are invalid.
class InvalidScenarioException extends ScenarioException {
  /// Creates an [InvalidScenarioException] with the validation [message].
  const InvalidScenarioException(super.message);
}
