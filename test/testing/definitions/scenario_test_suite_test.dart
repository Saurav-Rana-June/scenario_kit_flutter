import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestSuite', () {
    test('creates suite and backfills screenName to contained tests', () {
      final t1 = ScenarioTest(id: 't1', name: 'Test 1', group: 'Auth');
      final t2 = ScenarioTest(id: 't2', name: 'Test 2', group: 'Auth');
      final t3 = ScenarioTest(
        id: 't3',
        name: 'Test 3',
        screen: 'CustomScreen',
        group: 'Settings',
      );

      final suite = ScenarioTestSuite(
        screenName: 'LoginScreen',
        description: 'Suite for login flow',
        tests: [t1, t2, t3],
        metadata: const {'flow': 'onboarding'},
      );

      expect(suite.screenName, 'LoginScreen');
      expect(suite.description, 'Suite for login flow');
      expect(suite.length, 3);
      expect(suite.isNotEmpty, isTrue);

      // t1 and t2 should have been backfilled with 'LoginScreen'
      expect(suite.getTestById('t1')?.screen, 'LoginScreen');
      expect(suite.getTestById('t2')?.screen, 'LoginScreen');
      // t3 preserves its explicit screen
      expect(suite.getTestById('t3')?.screen, 'CustomScreen');

      expect(suite.hasTest('t1'), isTrue);
      expect(suite.hasTest('t99'), isFalse);
    });

    test('throws DuplicateScenarioException when duplicate test IDs are added',
        () {
      final t1 = ScenarioTest(id: 'duplicate_id', name: 'Test 1');
      final t2 = ScenarioTest(id: 'duplicate_id', name: 'Test 2');

      expect(
        () => ScenarioTestSuite(
          screenName: 'LoginScreen',
          tests: [t1, t2],
        ),
        throwsA(isA<DuplicateScenarioException>()),
      );
    });

    test('throws InvalidScenarioException on empty screenName', () {
      expect(
        () => ScenarioTestSuite(
          screenName: '   ',
          tests: const [],
        ),
        throwsA(isA<InvalidScenarioException>()),
      );
    });

    test('groups tests and provides grouped queries', () {
      final t1 = ScenarioTest(
          id: 't1', name: 'T1', group: 'Auth', screen: 'AccountScreen');
      final t2 = ScenarioTest(
          id: 't2', name: 'T2', group: 'Auth', screen: 'AccountScreen');
      final t3 = ScenarioTest(
          id: 't3', name: 'T3', group: 'Profile', screen: 'AccountScreen');
      final t4 = ScenarioTest(
          id: 't4', name: 'T4', screen: 'AccountScreen'); // ungrouped

      final suite = ScenarioTestSuite(
        screenName: 'AccountScreen',
        tests: [t1, t2, t3, t4],
      );

      expect(suite.groups, ['Auth', 'Profile']);
      expect(suite.getByGroup('Auth'), [t1, t2]);
      expect(suite.getByGroup('Profile'), [t3]);
      expect(suite.getByGroup(null), [t4]);

      final groupedMap = suite.testsByGroup;
      expect(groupedMap['Auth'], [t1, t2]);
      expect(groupedMap['Profile'], [t3]);
      expect(groupedMap[null], [t4]);
    });
  });
}
