import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/scenario_exceptions.dart';
import 'scenario_test_step.dart';
import 'screenshot_policy.dart';

/// Callback invoked before or after a [ScenarioTest] executes.
typedef TestLifecycleCallback = Future<void> Function(BuildContext context);

/// Represents an automated functional test case for an application screen.
///
/// Encapsulates ordered interaction steps, assertions, timeouts, preconditions,
/// and screenshot policies.
@immutable
class ScenarioTest {
  /// Creates a [ScenarioTest].
  ///
  /// If [id] is omitted, an ID slug will be automatically derived from [name].
  /// Throws [InvalidScenarioException] if [name] is empty or whitespace.
  ScenarioTest({
    required this.name,
    this.steps = const [],
    String? id,
    this.description,
    this.screen,
    this.group,
    Iterable<String>? tags,
    this.timeout = const Duration(seconds: 30),
    this.setup,
    this.teardown,
    this.screenshotPolicy = const ScreenshotPolicy.onFailureOnly(),
    this.isEnabled = true,
    this.requiredScenarioId,
    Map<String, dynamic>? metadata,
  })  : id = _sanitizeId(id, name),
        tags = List<String>.unmodifiable(tags ?? const <String>[]),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (name.trim().isEmpty) {
      throw const InvalidScenarioException(
          'ScenarioTest name cannot be empty.');
    }
    if (timeout <= Duration.zero) {
      throw const InvalidScenarioException(
          'ScenarioTest timeout must be positive.');
    }
  }

  /// Unique identifier for this test case.
  final String id;

  /// Human-readable title of this test.
  final String name;

  /// Detailed description of the test scenario and expected outcome.
  final String? description;

  /// Associated screen name (e.g. "LoginScreen", "CheckoutScreen").
  final String? screen;

  /// Feature group or category (e.g. "Authentication", "Validation").
  final String? group;

  /// Optional tags used for filtering tests (e.g. "smoke", "regression").
  final List<String> tags;

  /// Maximum duration allowed for this test to complete.
  final Duration timeout;

  /// Optional setup hook executed before test steps run.
  final TestLifecycleCallback? setup;

  /// Optional teardown hook executed after test steps run, regardless of success.
  final TestLifecycleCallback? teardown;

  /// Ordered sequence of test steps and assertions to execute.
  final List<ScenarioTestStep> steps;

  /// Configuration governing when screenshots should be captured.
  final ScreenshotPolicy screenshotPolicy;

  /// Whether this test is active. Disabled tests are marked skipped.
  final bool isEnabled;

  /// When set, [ScenarioTestRunner] selects this scenario ID before executing steps.
  final String? requiredScenarioId;

  /// Arbitrary custom metadata associated with this test.
  final Map<String, dynamic> metadata;

  static String _sanitizeId(String? id, String name) {
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    final sanitized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (sanitized.isEmpty) {
      throw const InvalidScenarioException(
        'Could not generate a valid test ID from name. Please specify an explicit id.',
      );
    }
    return sanitized;
  }

  /// Creates a copy of this test with specified fields replaced.
  ScenarioTest copyWith({
    String? id,
    String? name,
    String? description,
    String? screen,
    String? group,
    Iterable<String>? tags,
    Duration? timeout,
    TestLifecycleCallback? setup,
    TestLifecycleCallback? teardown,
    List<ScenarioTestStep>? steps,
    ScreenshotPolicy? screenshotPolicy,
    bool? isEnabled,
    String? requiredScenarioId,
    Map<String, dynamic>? metadata,
  }) {
    return ScenarioTest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      screen: screen ?? this.screen,
      group: group ?? this.group,
      tags: tags ?? this.tags,
      timeout: timeout ?? this.timeout,
      setup: setup ?? this.setup,
      teardown: teardown ?? this.teardown,
      steps: steps ?? this.steps,
      screenshotPolicy: screenshotPolicy ?? this.screenshotPolicy,
      isEnabled: isEnabled ?? this.isEnabled,
      requiredScenarioId: requiredScenarioId ?? this.requiredScenarioId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScenarioTest &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.screen == screen &&
        other.group == group &&
        listEquals(other.tags, tags) &&
        other.timeout == timeout &&
        other.screenshotPolicy == screenshotPolicy &&
        other.isEnabled == isEnabled &&
        other.requiredScenarioId == requiredScenarioId &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    var metaHash = 0;
    for (final entry in metadata.entries) {
      metaHash ^= Object.hash(entry.key, entry.value);
    }
    return Object.hash(
      id,
      name,
      description,
      screen,
      group,
      Object.hashAll(tags),
      timeout,
      screenshotPolicy,
      isEnabled,
      requiredScenarioId,
      metaHash,
    );
  }

  @override
  String toString() =>
      'ScenarioTest(id: $id, name: $name, screen: $screen, group: $group, isEnabled: $isEnabled)';
}
