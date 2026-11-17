import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('TestExecutionProgress', () {
    test('initializes with idle state', () {
      final progress = TestExecutionProgress.idle();

      expect(progress.totalTests, 0);
      expect(progress.currentTestIndex, 0);
      expect(progress.passedCount, 0);
      expect(progress.failedCount, 0);
      expect(progress.skippedCount, 0);
      expect(progress.elapsed, Duration.zero);
      expect(progress.isRunning, isFalse);
      expect(progress.percentage, 0.0);
      expect(progress.completedCount, 0);
    });

    test('calculates completion percentage and counts accurately', () {
      const progress = TestExecutionProgress(
        totalTests: 10,
        currentTestIndex: 4,
        passedCount: 3,
        failedCount: 1,
        skippedCount: 1,
        elapsed: Duration(seconds: 5),
        isRunning: true,
      );

      expect(progress.completedCount, 5);
      expect(progress.percentage, 0.5);
      expect(progress.toString(), contains('50.0%'));
    });

    test('copyWith updates specified fields', () {
      final initial = TestExecutionProgress.idle();
      final updated = initial.copyWith(
        totalTests: 5,
        passedCount: 2,
        isRunning: true,
      );

      expect(updated.totalTests, 5);
      expect(updated.passedCount, 2);
      expect(updated.isRunning, isTrue);
      expect(updated.failedCount, 0);
    });
  });
}
