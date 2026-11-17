import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('MockData Model', () {
    test('static value provides direct value and supports getAsync', () async {
      const mock = MockData<List<String>>.value(
        ['apple', 'banana'],
        label: 'Fruits',
        description: 'Standard 2 fruits list',
      );

      expect(mock.label, 'Fruits');
      expect(mock.description, 'Standard 2 fruits list');
      expect(mock.value, ['apple', 'banana']);

      final asyncResult =
          await mock.getAsync(delay: const Duration(milliseconds: 10));
      expect(asyncResult, ['apple', 'banana']);
    });

    test('generator produces fresh values dynamically', () {
      var counter = 0;
      final mock = MockData<int>.generator(
        () => ++counter,
        label: 'Dynamic Counter',
      );

      expect(mock.value, 1);
      expect(mock.value, 2);
      expect(mock.value, 3);
    });

    test('equality and hashCode support', () {
      const m1 = MockData<int>.value(42, label: 'Answer');
      const m2 = MockData<int>.value(42, label: 'Answer');
      const m3 = MockData<int>.value(99, label: 'Answer');

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1, isNot(equals(m3)));
    });
  });
}
