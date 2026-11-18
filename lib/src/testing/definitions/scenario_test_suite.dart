import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/scenario_exceptions.dart';
import 'scenario_test.dart';

/// Represents a collection of automated functionality tests associated with
/// a specific application screen or flow.
@immutable
class ScenarioTestSuite {
  /// Creates a [ScenarioTestSuite].
  ///
  /// Throws [InvalidScenarioException] if [screenName] is empty or if [tests]
  /// contain duplicate test IDs.
  ScenarioTestSuite({
    required this.screenName,
    required Iterable<ScenarioTest> tests,
    this.description,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (screenName.trim().isEmpty) {
      throw const InvalidScenarioException(
          'TestSuite screenName cannot be empty.');
    }

    final validatedTests = <ScenarioTest>[];
    final seenIds = <String>{};

    for (final test in tests) {
      if (!seenIds.add(test.id)) {
        throw DuplicateTestException(test.id);
      }
      // Associate with screen if not already set
      if (test.screen == null) {
        validatedTests.add(test.copyWith(screen: screenName));
      } else {
        validatedTests.add(test);
      }
    }

    _tests = UnmodifiableListView<ScenarioTest>(validatedTests);
  }

  /// Target screen name (e.g. "LoginScreen", "ProductCatalogScreen").
  final String screenName;

  /// Optional description explaining the scope of this test suite.
  final String? description;

  /// Arbitrary custom metadata associated with this suite.
  final Map<String, dynamic> metadata;

  late final List<ScenarioTest> _tests;

  /// Unmodifiable list of registered tests in registration order.
  List<ScenarioTest> get tests => _tests;

  /// Total number of tests in this suite.
  int get length => _tests.length;

  /// Whether the suite contains zero tests.
  bool get isEmpty => _tests.isEmpty;

  /// Whether the suite contains at least one test.
  bool get isNotEmpty => _tests.isNotEmpty;

  /// Returns sorted list of unique group names present in this suite.
  List<String> get groups {
    final groupSet = <String>{};
    for (final test in _tests) {
      if (test.group != null && test.group!.trim().isNotEmpty) {
        groupSet.add(test.group!.trim());
      }
    }
    final list = groupSet.toList()..sort();
    return UnmodifiableListView<String>(list);
  }

  /// Returns a map grouping tests by group name (`null` for ungrouped).
  Map<String?, List<ScenarioTest>> get testsByGroup {
    final map = <String?, List<ScenarioTest>>{};
    for (final test in _tests) {
      final key = test.group?.trim();
      map.putIfAbsent(key, () => <ScenarioTest>[]).add(test);
    }
    return Map<String?, List<ScenarioTest>>.unmodifiable(
      map.map((k, v) => MapEntry(k, UnmodifiableListView<ScenarioTest>(v))),
    );
  }

  /// Returns the test with [id], or `null` if not found.
  ScenarioTest? getTestById(String id) {
    for (final test in _tests) {
      if (test.id == id) return test;
    }
    return null;
  }

  /// Returns `true` if a test with [id] is present.
  bool hasTest(String id) => getTestById(id) != null;

  /// Returns all tests belonging to [group].
  List<ScenarioTest> getByGroup(String? group) {
    final target = group?.trim();
    final matches = _tests.where((t) => t.group?.trim() == target);
    return UnmodifiableListView<ScenarioTest>(matches.toList());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScenarioTestSuite &&
        other.screenName == screenName &&
        other.description == description &&
        listEquals(other.tests, _tests) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        screenName,
        description,
        Object.hashAll(_tests),
        Object.hashAll(metadata.entries),
      );

  @override
  String toString() =>
      'ScenarioTestSuite(screenName: $screenName, testsCount: ${_tests.length})';
}
