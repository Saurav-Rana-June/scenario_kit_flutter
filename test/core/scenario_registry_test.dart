import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioRegistry', () {
    late ScenarioRegistry registry;

    setUp(() {
      registry = ScenarioRegistry();
    });

    tearDown(() {
      registry.dispose();
      ScenarioRegistry.resetInstance();
    });

    test('initializes empty or with initial scenarios', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.length, 0);

      final populatedRegistry = ScenarioRegistry([
        Scenario(
            id: 's1', name: 'Scenario 1', builder: (c) => const SizedBox()),
        Scenario(
            id: 's2', name: 'Scenario 2', builder: (c) => const SizedBox()),
      ]);

      expect(populatedRegistry.length, 2);
      expect(populatedRegistry.isNotEmpty, isTrue);
      populatedRegistry.dispose();
    });

    test('registers scenarios and notifies listeners', () {
      var notifications = 0;
      registry.addListener(() => notifications++);

      final scenario = Scenario(
        id: 'loading',
        name: 'Loading',
        builder: (c) => const SizedBox(),
      );

      registry.register(scenario);

      expect(registry.length, 1);
      expect(registry.hasScenario('loading'), isTrue);
      expect(registry.getById('loading'), scenario);
      expect(registry.requireById('loading'), scenario);
      expect(notifications, 1);
    });

    test('throws DuplicateScenarioException on duplicate register', () {
      final s1 = Scenario(
          id: 'duplicate', name: 'S1', builder: (c) => const SizedBox());
      final s2 = Scenario(
          id: 'duplicate', name: 'S2', builder: (c) => const SizedBox());

      registry.register(s1);

      expect(
        () => registry.register(s2),
        throwsA(isA<DuplicateScenarioException>()),
      );
    });

    test(
        'registerAll registers multiple scenarios and checks for duplicates atomically',
        () {
      final s1 =
          Scenario(id: 's1', name: 'S1', builder: (c) => const SizedBox());
      final s2 =
          Scenario(id: 's2', name: 'S2', builder: (c) => const SizedBox());

      registry.registerAll([s1, s2]);
      expect(registry.length, 2);

      // Attempting to register list containing duplicate or conflicting id
      final s3 =
          Scenario(id: 's3', name: 'S3', builder: (c) => const SizedBox());
      final sConflict = Scenario(
          id: 's1', name: 'Conflict', builder: (c) => const SizedBox());

      expect(
        () => registry.registerAll([s3, sConflict]),
        throwsA(isA<DuplicateScenarioException>()),
      );

      // s3 was not registered because the operation is atomic
      expect(registry.hasScenario('s3'), isFalse);
    });

    test('unregisters scenario and notifies listeners', () {
      var notifications = 0;
      final scenario =
          Scenario(id: 'item', name: 'Item', builder: (c) => const SizedBox());
      registry.register(scenario);

      registry.addListener(() => notifications++);
      final result = registry.unregister('item');

      expect(result, isTrue);
      expect(registry.hasScenario('item'), isFalse);
      expect(notifications, 1);

      // Unregistering nonexistent returns false and does not notify
      final resultNonexistent = registry.unregister('item');
      expect(resultNonexistent, isFalse);
      expect(notifications, 1);
    });

    test('clears all scenarios and notifies listeners', () {
      registry.register(
          Scenario(id: '1', name: '1', builder: (c) => const SizedBox()));
      registry.register(
          Scenario(id: '2', name: '2', builder: (c) => const SizedBox()));

      var notifications = 0;
      registry.addListener(() => notifications++);

      registry.clear();
      expect(registry.isEmpty, isTrue);
      expect(notifications, 1);

      // Clearing already empty does not notify
      registry.clear();
      expect(notifications, 1);
    });

    test('requireById throws ScenarioNotFoundException for missing id', () {
      expect(
        () => registry.requireById('unknown'),
        throwsA(isA<ScenarioNotFoundException>()),
      );
    });

    test('resolves defaultScenario correctly', () {
      expect(registry.defaultScenario, isNull);

      final s1 = Scenario(
          id: 'first', name: 'First', builder: (c) => const SizedBox());
      final s2 = Scenario(
        id: 'second_default',
        name: 'Second',
        isDefault: true,
        builder: (c) => const SizedBox(),
      );
      final s3 = Scenario(
          id: 'third', name: 'Third', builder: (c) => const SizedBox());

      registry.registerAll([s1, s2, s3]);
      expect(registry.defaultScenario, s2);

      // When no scenario is explicitly default, defaults to first
      final registryNoDefault = ScenarioRegistry([s1, s3]);
      expect(registryNoDefault.defaultScenario, s1);
      registryNoDefault.dispose();
    });

    test('groups scenarios and provides grouped lookup', () {
      final s1 = Scenario(
        id: 'auth_login',
        name: 'Login',
        group: 'Auth',
        builder: (c) => const SizedBox(),
      );
      final s2 = Scenario(
        id: 'auth_signup',
        name: 'Signup',
        group: 'Auth',
        builder: (c) => const SizedBox(),
      );
      final s3 = Scenario(
        id: 'home_feed',
        name: 'Feed',
        group: 'Home',
        builder: (c) => const SizedBox(),
      );
      final s4 = Scenario(
        id: 'settings',
        name: 'Settings',
        builder: (c) => const SizedBox(),
      );

      registry.registerAll([s1, s2, s3, s4]);

      expect(registry.groups, ['Auth', 'Home']);
      expect(registry.getByGroup('Auth'), [s1, s2]);
      expect(registry.getByGroup('Home'), [s3]);
      expect(registry.getByGroup(null), [s4]);

      final groupedMap = registry.scenariosByGroup;
      expect(groupedMap['Auth'], [s1, s2]);
      expect(groupedMap['Home'], [s3]);
      expect(groupedMap[null], [s4]);
    });

    test('global ambient instance operates as singleton and can be reset', () {
      final instance1 = ScenarioRegistry.instance;
      final instance2 = ScenarioRegistry.instance;
      expect(identical(instance1, instance2), isTrue);

      ScenarioRegistry.resetInstance();
      final instance3 = ScenarioRegistry.instance;
      expect(identical(instance1, instance3), isFalse);
    });
  });
}
