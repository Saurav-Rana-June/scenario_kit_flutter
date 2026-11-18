import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/scenario_exceptions.dart';
import '../definitions/scenario_test.dart';
import '../definitions/scenario_test_suite.dart';

/// Registry responsible for managing, organizing, and querying [ScenarioTestSuite]
/// and [ScenarioTest] instances across screens.
class ScenarioTestRegistry extends ChangeNotifier {
  /// Creates a [ScenarioTestRegistry].
  ///
  /// Optionally populates the registry with [initialSuites].
  ScenarioTestRegistry([Iterable<ScenarioTestSuite>? initialSuites]) {
    if (initialSuites != null) {
      for (final suite in initialSuites) {
        registerSuite(suite);
      }
    }
  }

  static ScenarioTestRegistry? _instance;

  /// Global ambient instance for simple or single-registry applications.
  static ScenarioTestRegistry get instance =>
      _instance ??= ScenarioTestRegistry();

  /// Resets the global ambient instance. Mainly useful in testing environments.
  @visibleForTesting
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  final Map<String, ScenarioTestSuite> _suites = <String, ScenarioTestSuite>{};
  final Map<String, ScenarioTest> _standaloneTests = <String, ScenarioTest>{};

  /// Unmodifiable list of all registered suites.
  List<ScenarioTestSuite> get suites =>
      UnmodifiableListView<ScenarioTestSuite>(_suites.values);

  /// Sorted list of all screen names with registered tests.
  List<String> get screens {
    final list = _suites.keys.toList()..sort();
    return UnmodifiableListView<String>(list);
  }

  /// Returns all registered tests across all screens and suites.
  List<ScenarioTest> get allTests {
    final list = <ScenarioTest>[];
    for (final suite in _suites.values) {
      list.addAll(suite.tests);
    }
    list.addAll(_standaloneTests.values);
    return UnmodifiableListView<ScenarioTest>(list);
  }

  /// Total number of unique tests registered.
  int get totalTestCount => allTests.length;

  /// Whether the registry contains zero tests.
  bool get isEmpty => allTests.isEmpty;

  /// Whether the registry contains at least one test.
  bool get isNotEmpty => allTests.isNotEmpty;

  /// Registers a [ScenarioTestSuite] for its [ScenarioTestSuite.screenName].
  ///
  /// Throws [DuplicateTestException] if a suite for the same screen is already
  /// registered unless [replace] is `true`.
  void registerSuite(ScenarioTestSuite suite, {bool replace = false}) {
    if (_suites.containsKey(suite.screenName) && !replace) {
      throw DuplicateTestException(suite.screenName);
    }
    _suites[suite.screenName] = suite;
    notifyListeners();
  }

  /// Replaces or registers a suite for [suite.screenName].
  void replaceSuite(ScenarioTestSuite suite) =>
      registerSuite(suite, replace: true);

  /// Removes the suite for [screenName]. Returns `true` if removed.
  bool unregisterSuite(String screenName) {
    final removed = _suites.remove(screenName);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Registers an individual [ScenarioTest].
  ///
  /// If [ScenarioTest.screen] is defined on [test], it is added to the screen's suite; otherwise,
  /// it is registered under the standalone collection.
  /// Throws [DuplicateScenarioException] if a test with the same ID already exists.
  void registerTest(ScenarioTest test) {
    if (hasTest(test.id)) {
      throw DuplicateTestException(test.id);
    }

    final screen = test.screen;
    if (screen != null && screen.trim().isNotEmpty) {
      final existingSuite = _suites[screen];
      if (existingSuite != null) {
        final updatedTests = [...existingSuite.tests, test];
        _suites[screen] = ScenarioTestSuite(
          screenName: screen,
          tests: updatedTests,
          description: existingSuite.description,
          metadata: existingSuite.metadata,
        );
      } else {
        _suites[screen] = ScenarioTestSuite(
          screenName: screen,
          tests: [test],
        );
      }
    } else {
      _standaloneTests[test.id] = test;
    }

    notifyListeners();
  }

  /// Registers multiple tests atomically.
  void registerAllTests(Iterable<ScenarioTest> tests) {
    for (final test in tests) {
      registerTest(test);
    }
  }

  /// Returns the suite registered for [screenName], or `null` if not found.
  ScenarioTestSuite? getSuite(String screenName) => _suites[screenName];

  /// Alias for [getSuite] locating suite by [screenName].
  ScenarioTestSuite? findSuite(String screenName) => getSuite(screenName);

  /// Returns the suite registered for [screenName], or throws [ScenarioNotFoundException].
  ScenarioTestSuite requireSuite(String screenName) {
    final suite = _suites[screenName];
    if (suite == null) {
      throw ScenarioNotFoundException(screenName);
    }
    return suite;
  }

  /// Returns `true` if a suite for [screenName] is registered.
  bool hasSuite(String screenName) => _suites.containsKey(screenName);

  /// Returns the test with [id], or `null` if not found anywhere in the registry.
  ScenarioTest? getTestById(String id) {
    for (final suite in _suites.values) {
      final test = suite.getTestById(id);
      if (test != null) return test;
    }
    return _standaloneTests[id];
  }

  /// Returns the test with [id], or throws [ScenarioNotFoundException].
  ScenarioTest requireTestById(String id) {
    final test = getTestById(id);
    if (test == null) {
      throw ScenarioNotFoundException(id);
    }
    return test;
  }

  /// Returns `true` if a test with [id] is registered in any suite.
  bool hasTest(String id) => getTestById(id) != null;

  /// Returns all tests associated with [screenName].
  List<ScenarioTest> getTestsForScreen(String screenName) {
    return _suites[screenName]?.tests ?? const [];
  }

  /// Returns all tests matching [group] across all registered screens.
  List<ScenarioTest> getTestsByGroup(String? group) {
    final target = group?.trim();
    final matches = allTests.where((t) => t.group?.trim() == target);
    return UnmodifiableListView<ScenarioTest>(matches.toList());
  }

  /// Returns tests that include [tag] in [ScenarioTest.tags].
  List<ScenarioTest> getTestsByTag(String tag) {
    final normalized = tag.trim();
    if (normalized.isEmpty) return const [];
    final matches =
        allTests.where((t) => t.tags.map((e) => e.trim()).contains(normalized));
    return UnmodifiableListView<ScenarioTest>(matches.toList());
  }

  /// Sorted unique tags across all tests.
  List<String> get allTags {
    final set = <String>{};
    for (final test in allTests) {
      for (final tag in test.tags) {
        if (tag.trim().isNotEmpty) set.add(tag.trim());
      }
    }
    final list = set.toList()..sort();
    return UnmodifiableListView<String>(list);
  }

  /// Clears all suites and tests from this registry.
  void clear() {
    if (_suites.isEmpty && _standaloneTests.isEmpty) return;
    _suites.clear();
    _standaloneTests.clear();
    notifyListeners();
  }
}
