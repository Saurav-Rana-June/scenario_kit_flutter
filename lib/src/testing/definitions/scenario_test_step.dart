import 'dart:async';

import 'package:flutter/widgets.dart';

import '../assertions/assertion_steps.dart';
import '../steps/interaction_steps.dart';
import '../steps/scenario_step_context.dart';
import 'step_finder.dart';

/// Abstract base class for all test steps executed within a [ScenarioTest].
@immutable
abstract class ScenarioTestStep {
  /// Creates a [ScenarioTestStep].
  const ScenarioTestStep({
    required this.id,
    required this.description,
    this.captureScreenshot = false,
    this.timeout,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? const {};

  /// Factory constructor creating a [TapStep].
  static ScenarioTestStep tap(
    StepFinder finder, {
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return TapStep(
      finder: finder,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating a [LongPressStep].
  static ScenarioTestStep longPress(
    StepFinder finder, {
    Duration pressDuration = const Duration(milliseconds: 500),
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return LongPressStep(
      finder: finder,
      pressDuration: pressDuration,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating an [EnterTextStep].
  static ScenarioTestStep enterText(
    StepFinder finder,
    String text, {
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return EnterTextStep(
      finder: finder,
      text: text,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating a [ClearTextStep].
  static ScenarioTestStep clearText(
    StepFinder finder, {
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return ClearTextStep(
      finder: finder,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating a [ScrollStep].
  static ScenarioTestStep scroll(
    StepFinder finder, {
    required Offset offset,
    Duration scrollDuration = const Duration(milliseconds: 300),
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return ScrollStep(
      finder: finder,
      offset: offset,
      scrollDuration: scrollDuration,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating a [DragStep].
  static ScenarioTestStep drag(
    StepFinder finder, {
    required Offset offset,
    Duration dragDuration = const Duration(milliseconds: 300),
    String? id,
    String? description,
    bool captureScreenshot = false,
    bool settle = true,
  }) {
    return DragStep(
      finder: finder,
      offset: offset,
      dragDuration: dragDuration,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
      settle: settle,
    );
  }

  /// Factory constructor creating a [WaitStep].
  static ScenarioTestStep wait(
    Duration duration, {
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return WaitStep(
      duration: duration,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating a [WaitForWidgetStep].
  static ScenarioTestStep waitFor(
    StepFinder finder, {
    Duration timeout = const Duration(seconds: 5),
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return WaitForWidgetStep(
      finder: finder,
      waitTimeout: timeout,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating a [CustomStep].
  static ScenarioTestStep custom({
    required String id,
    required String description,
    required FutureOr<void> Function(ScenarioStepContext context) action,
    bool captureScreenshot = false,
    Duration? timeout,
  }) {
    return CustomStep(
      id: id,
      description: description,
      action: action,
      captureScreenshot: captureScreenshot,
      timeout: timeout,
    );
  }

  /// Factory constructor creating an [AssertExistsStep].
  static ScenarioTestStep assertExists(
    StepFinder finder, {
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return AssertExistsStep(
      finder: finder,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating an [AssertNotExistsStep].
  static ScenarioTestStep assertNotExists(
    StepFinder finder, {
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return AssertNotExistsStep(
      finder: finder,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating an [AssertTextStep].
  static ScenarioTestStep assertText(
    StepFinder finder,
    String expectedText, {
    TextMatchType matchType = TextMatchType.exact,
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return AssertTextStep(
      finder: finder,
      expectedText: expectedText,
      matchType: matchType,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating an [AssertVisibleStep].
  static ScenarioTestStep assertVisible(
    StepFinder finder, {
    String? id,
    String? description,
    bool captureScreenshot = false,
  }) {
    return AssertVisibleStep(
      finder: finder,
      id: id,
      description: description,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Factory constructor creating an [AssertCustomStep].
  static ScenarioTestStep assertCustom({
    required String id,
    required String description,
    required FutureOr<dynamic> Function(ScenarioStepContext context) assertion,
    dynamic expectedValue = true,
    bool captureScreenshot = false,
  }) {
    return AssertCustomStep(
      id: id,
      description: description,
      assertion: assertion,
      expectedValue: expectedValue,
      captureScreenshot: captureScreenshot,
    );
  }

  /// Unique identifier for this step within its parent [ScenarioTest].
  final String id;

  /// Clear, human-readable description of what this step does.
  final String description;

  /// Whether to capture a screenshot immediately after this step executes.
  final bool captureScreenshot;

  /// Maximum time allowed for this individual step to complete.
  final Duration? timeout;

  /// Arbitrary metadata associated with this step.
  final Map<String, dynamic> metadata;

  /// Executes this step within the provided [ScenarioStepContext].
  Future<void> execute(ScenarioStepContext context);

  @override
  String toString() => '$runtimeType(id: $id, description: $description)';
}
