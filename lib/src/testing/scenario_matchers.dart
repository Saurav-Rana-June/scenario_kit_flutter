import 'package:flutter_test/flutter_test.dart';

import '../core/scenario.dart';
import '../core/scenario_registry.dart';

/// Returns a matcher that matches if a [ScenarioRegistry] or `Iterable<Scenario>`
/// contains a scenario with [id].
Matcher containsScenario(String id) => _ContainsScenarioMatcher(id);

/// Returns a matcher that matches if a [ScenarioRegistry]'s default scenario has [id].
Matcher hasDefaultScenario(String id) => _HasDefaultScenarioMatcher(id);

/// Returns a matcher that matches if a [ScenarioRegistry] contains the specified [group].
Matcher containsScenarioGroup(String group) =>
    _ContainsScenarioGroupMatcher(group);

class _ContainsScenarioMatcher extends Matcher {
  const _ContainsScenarioMatcher(this.id);
  final String id;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is ScenarioRegistry) {
      return item.hasScenario(id);
    }
    if (item is Iterable<Scenario>) {
      return item.any((s) => s.id == id);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('contains scenario with id "$id"');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ScenarioRegistry && item is! Iterable<Scenario>) {
      return mismatchDescription
          .add('is not a ScenarioRegistry or Iterable<Scenario>');
    }
    return mismatchDescription.add('did not find scenario with id "$id"');
  }
}

class _HasDefaultScenarioMatcher extends Matcher {
  const _HasDefaultScenarioMatcher(this.id);
  final String id;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is ScenarioRegistry) {
      return item.defaultScenario?.id == id;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has default scenario with id "$id"');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ScenarioRegistry) {
      return mismatchDescription.add('is not a ScenarioRegistry');
    }
    final actual = item.defaultScenario?.id;
    return mismatchDescription.add('had default scenario with id "$actual"');
  }
}

class _ContainsScenarioGroupMatcher extends Matcher {
  const _ContainsScenarioGroupMatcher(this.group);
  final String group;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is ScenarioRegistry) {
      return item.groups.contains(group);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('contains scenario group "$group"');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ScenarioRegistry) {
      return mismatchDescription.add('is not a ScenarioRegistry');
    }
    return mismatchDescription.add('available groups were: ${item.groups}');
  }
}
