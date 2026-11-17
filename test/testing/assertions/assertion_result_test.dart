import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('AssertionResult', () {
    test('creates success assertion result with proper fields', () {
      final now = DateTime.now();
      final result = AssertionResult.success(
        description: 'Check login button visible',
        expectedValue: 'visible',
        actualValue: 'visible',
        testId: 'test_123',
        duration: const Duration(milliseconds: 15),
      );

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.description, 'Check login button visible');
      expect(result.expectedValue, 'visible');
      expect(result.actualValue, 'visible');
      expect(result.testId, 'test_123');
      expect(result.failureMessage, isNull);
      expect(result.duration, const Duration(milliseconds: 15));
      expect(result.timestamp.isAfter(now.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('creates failure assertion result with failureMessage', () {
      final result = AssertionResult.failure(
        description: 'Verify error text',
        failureMessage: 'Found "Hello" instead of "Error"',
        expectedValue: 'Error',
        actualValue: 'Hello',
        testId: 'test_456',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.description, 'Verify error text');
      expect(result.failureMessage, 'Found "Hello" instead of "Error"');
      expect(result.expectedValue, 'Error');
      expect(result.actualValue, 'Hello');
      expect(result.testId, 'test_456');
    });

    test('serializes to JSON correctly', () {
      final result = AssertionResult.failure(
        description: 'Check badge count',
        failureMessage: 'Count mismatch',
        expectedValue: 5,
        actualValue: 2,
        testId: 'cart_test',
        duration: const Duration(milliseconds: 25),
      );

      final json = result.toJson();
      expect(json['description'], 'Check badge count');
      expect(json['isSuccess'], isFalse);
      expect(json['expectedValue'], '5');
      expect(json['actualValue'], '2');
      expect(json['failureMessage'], 'Count mismatch');
      expect(json['testId'], 'cart_test');
      expect(json['durationMs'], 25);
      expect(json['timestamp'], isNotNull);
    });

    test('equality and hashCode compare field values correctly', () {
      final r1 = AssertionResult.success(
        description: 'D1',
        expectedValue: 'E',
        actualValue: 'E',
        testId: 'T1',
      );
      final r2 = AssertionResult.success(
        description: 'D1',
        expectedValue: 'E',
        actualValue: 'E',
        testId: 'T1',
      );
      final r3 = AssertionResult.failure(
        description: 'D1',
        failureMessage: 'Failed',
        expectedValue: 'E',
        actualValue: 'F',
        testId: 'T1',
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('toString formats correctly for success and failure', () {
      final s = AssertionResult.success(description: 'Widget present');
      expect(s.toString(), contains('AssertionResult.success(Widget present)'));

      final f = AssertionResult.failure(
        description: 'Widget absent',
        failureMessage: 'Not found',
      );
      expect(f.toString(), contains('AssertionResult.failure'));
      expect(f.toString(), contains('Not found'));
    });
  });

  group('AssertionException', () {
    test('wraps AssertionResult and formats message', () {
      final result = AssertionResult.failure(
        description: 'Check banner',
        failureMessage: 'Banner missing from screen',
      );
      final exception = AssertionException(result);

      expect(exception.result, equals(result));
      expect(exception.message, 'Banner missing from screen');
      expect(exception.toString(),
          'AssertionException: Banner missing from screen');
    });
  });
}
