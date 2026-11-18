import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestRegistry', () {
    late ScenarioTestRegistry registry;

    setUp(() {
      registry = ScenarioTestRegistry();
    });

    tearDown(() {
      ScenarioTestRegistry.resetInstance();
    });

    test('initial state is empty', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
      expect(registry.totalTestCount, 0);
      expect(registry.suites, isEmpty);
      expect(registry.screens, isEmpty);
      expect(registry.allTests, isEmpty);
    });

    test('initializes with initial suites', () {
      final suite = ScenarioTestSuite(
        screenName: 'ProfileScreen',
        tests: [
          ScenarioTest(name: 'Edit avatar'),
        ],
      );
      final custom = ScenarioTestRegistry([suite]);
      expect(custom.screens, ['ProfileScreen']);
      expect(custom.totalTestCount, 1);
    });

    test('global ambient singleton works and can be reset', () {
      final first = ScenarioTestRegistry.instance;
      final second = ScenarioTestRegistry.instance;
      expect(identical(first, second), isTrue);

      ScenarioTestRegistry.resetInstance();
      final third = ScenarioTestRegistry.instance;
      expect(identical(first, third), isFalse);
    });

    test('registers a suite and notifies listeners', () {
      var notified = false;
      registry.addListener(() => notified = true);

      final suite = ScenarioTestSuite(
        screenName: 'HomeScreen',
        tests: [
          ScenarioTest(name: 'Load feeds'),
        ],
      );

      registry.registerSuite(suite);
      expect(notified, isTrue);
      expect(registry.hasSuite('HomeScreen'), isTrue);
      expect(registry.getSuite('HomeScreen'), equals(suite));
      expect(registry.requireSuite('HomeScreen'), equals(suite));
      expect(registry.screens, ['HomeScreen']);
      expect(registry.totalTestCount, 1);
    });

    test('throws DuplicateTestException on duplicate suite registration',
        () {
      final suite1 =
          ScenarioTestSuite(screenName: 'LoginScreen', tests: const []);
      final suite2 =
          ScenarioTestSuite(screenName: 'LoginScreen', tests: const []);

      registry.registerSuite(suite1);
      expect(
        () => registry.registerSuite(suite2),
        throwsA(isA<DuplicateTestException>()),
      );
    });

    test('requireSuite throws ScenarioNotFoundException if missing', () {
      expect(
        () => registry.requireSuite('UnknownScreen'),
        throwsA(isA<ScenarioNotFoundException>()),
      );
    });

    test('registers standalone test without screen', () {
      final testItem = ScenarioTest(name: 'Global Ping Test');
      registry.registerTest(testItem);

      expect(registry.hasTest(testItem.id), isTrue);
      expect(registry.getTestById(testItem.id), equals(testItem));
      expect(registry.requireTestById(testItem.id), equals(testItem));
      expect(registry.allTests, contains(testItem));
      expect(registry.screens, isEmpty);
    });

    test('registers test with screen creates or updates suite', () {
      final test1 = ScenarioTest(name: 'Enter Email', screen: 'LoginScreen');
      registry.registerTest(test1);

      expect(registry.hasSuite('LoginScreen'), isTrue);
      expect(registry.getTestsForScreen('LoginScreen'), [test1]);

      final test2 = ScenarioTest(name: 'Enter Password', screen: 'LoginScreen');
      registry.registerTest(test2);

      expect(registry.getTestsForScreen('LoginScreen').length, 2);
      expect(registry.getTestsForScreen('LoginScreen'),
          containsAll([test1, test2]));
    });

    test(
        'throws DuplicateScenarioException when registering test with duplicate ID',
        () {
      final test1 = ScenarioTest(id: 'auth_test_1', name: 'Test 1');
      final test2 = ScenarioTest(id: 'auth_test_1', name: 'Test 2');

      registry.registerTest(test1);
      expect(
        () => registry.registerTest(test2),
        throwsA(isA<DuplicateTestException>()),
      );
    });

    test('registerAllTests registers multiple tests', () {
      final tests = [
        ScenarioTest(name: 'Test A', screen: 'Screen 1'),
        ScenarioTest(name: 'Test B', screen: 'Screen 2'),
      ];
      registry.registerAllTests(tests);

      expect(registry.totalTestCount, 2);
      expect(registry.screens, ['Screen 1', 'Screen 2']);
    });

    test('requireTestById throws ScenarioNotFoundException if missing', () {
      expect(
        () => registry.requireTestById('non_existent_id'),
        throwsA(isA<ScenarioNotFoundException>()),
      );
    });

    test('getTestsByGroup filters correctly across screens', () {
      final t1 = ScenarioTest(name: 'T1', group: 'Auth', screen: 'S1');
      final t2 = ScenarioTest(name: 'T2', group: 'Settings', screen: 'S1');
      final t3 = ScenarioTest(name: 'T3', group: 'Auth', screen: 'S2');

      registry.registerAllTests([t1, t2, t3]);

      final authTests = registry.getTestsByGroup('Auth');
      expect(authTests.length, 2);
      expect(authTests, containsAll([t1, t3]));

      final settingsTests = registry.getTestsByGroup('Settings');
      expect(settingsTests.length, 1);
      expect(settingsTests, contains(t2));

      expect(registry.getTestsByGroup('NonExistent'), isEmpty);
    });

    test('clear resets all suites and standalone tests and notifies listeners',
        () {
      registry.registerTest(ScenarioTest(name: 'Test 1', screen: 'Screen 1'));
      registry.registerTest(ScenarioTest(name: 'Standalone Test'));

      expect(registry.totalTestCount, 2);

      var notified = false;
      registry.addListener(() => notified = true);

      registry.clear();
      expect(notified, isTrue);
      expect(registry.isEmpty, isTrue);
      expect(registry.totalTestCount, 0);

      // Calling clear again on empty registry should not notify
      notified = false;
      registry.clear();
      expect(notified, isFalse);
    });
  });
}
