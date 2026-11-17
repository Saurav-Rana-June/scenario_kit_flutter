import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('Scenario Model', () {
    test('creates scenario with explicit id', () {
      final scenario = Scenario(
        id: 'custom_id',
        name: 'Loading State',
        description: 'Displays loading spinner',
        group: 'Auth',
        isDefault: true,
        metadata: const {'timeout': 5000},
        builder: (context) => const SizedBox(),
      );

      expect(scenario.id, 'custom_id');
      expect(scenario.name, 'Loading State');
      expect(scenario.description, 'Displays loading spinner');
      expect(scenario.group, 'Auth');
      expect(scenario.isDefault, isTrue);
      expect(scenario.metadata, {'timeout': 5000});
      expect(scenario.builder, isNotNull);
    });

    test('auto-derives sanitized ID when omitted', () {
      final scenario = Scenario(
        name: 'Product Details / Error State!',
        builder: (context) => const SizedBox(),
      );

      expect(scenario.id, 'product_details_error_state');
    });

    test('throws InvalidScenarioException on empty or whitespace name', () {
      expect(
        () => Scenario(
          name: '',
          builder: (context) => const SizedBox(),
        ),
        throwsA(isA<InvalidScenarioException>()),
      );

      expect(
        () => Scenario(
          name: '   ',
          builder: (context) => const SizedBox(),
        ),
        throwsA(isA<InvalidScenarioException>()),
      );
    });

    test(
        'throws InvalidScenarioException when id cannot be derived from special chars only',
        () {
      expect(
        () => Scenario(
          name: '???***',
          builder: (context) => const SizedBox(),
        ),
        throwsA(isA<InvalidScenarioException>()),
      );
    });

    test('copyWith updates specified fields only', () {
      final original = Scenario(
        id: 'initial_id',
        name: 'Initial Name',
        builder: (context) => const SizedBox(),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        group: 'Checkout',
        isDefault: true,
      );

      expect(updated.id, 'initial_id');
      expect(updated.name, 'Updated Name');
      expect(updated.group, 'Checkout');
      expect(updated.isDefault, isTrue);
    });

    test('supports equality and hash code comparison', () {
      final s1 = Scenario(
        id: 'same',
        name: 'Same Name',
        description: 'Desc',
        group: 'GroupA',
        isDefault: false,
        metadata: const {'key': 'val'},
        builder: (context) => const SizedBox(),
      );

      final s2 = Scenario(
        id: 'same',
        name: 'Same Name',
        description: 'Desc',
        group: 'GroupA',
        isDefault: false,
        metadata: const {'key': 'val'},
        builder: (context) => const SizedBox(),
      );

      final s3 = Scenario(
        id: 'different',
        name: 'Same Name',
        builder: (context) => const SizedBox(),
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });

    test('metadata map is unmodifiable', () {
      final scenario = Scenario(
        name: 'Test',
        metadata: const {'editable': true},
        builder: (context) => const SizedBox(),
      );

      expect(
        () => scenario.metadata['newKey'] = 'fail',
        throwsUnsupportedError,
      );
    });

    test('named factory constructors produce expected scenario templates', () {
      final loading = Scenario.loading(builder: (c) => const SizedBox());
      final success = Scenario.success(builder: (c) => const SizedBox());
      final empty = Scenario.empty(builder: (c) => const SizedBox());
      final error = Scenario.error(builder: (c) => const SizedBox());
      final offline = Scenario.offline(builder: (c) => const SizedBox());

      expect(loading.id, 'loading');
      expect(loading.name, 'Loading');
      expect(loading.isDefault, isFalse);

      expect(success.id, 'success');
      expect(success.name, 'Success');
      expect(success.isDefault, isTrue);

      expect(empty.id, 'empty');
      expect(error.id, 'error');
      expect(offline.id, 'offline');
    });
  });
}
