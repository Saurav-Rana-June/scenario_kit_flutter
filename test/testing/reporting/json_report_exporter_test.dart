import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('JsonReportExporter', () {
    test('exports formatted and minified JSON accurately', () {
      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Login Test',
        screen: 'LoginScreen',
        duration: const Duration(milliseconds: 100),
      );

      final report = ScenarioTestReport.fromResults(
        results: [r1],
        title: 'Smoke Test Report',
      );

      const exporter = JsonReportExporter();

      // Pretty JSON
      final prettyJson = exporter.export(report, pretty: true);
      expect(prettyJson, contains('\n'));
      expect(prettyJson, contains('Smoke Test Report'));
      final decodedPretty = jsonDecode(prettyJson) as Map<String, dynamic>;
      expect(decodedPretty['title'], 'Smoke Test Report');
      expect(decodedPretty['totalTests'], 1);

      // Minified JSON
      final minifiedJson = exporter.export(report, pretty: false);
      expect(minifiedJson, isNot(contains('\n')));
      final decodedMin = jsonDecode(minifiedJson) as Map<String, dynamic>;
      expect(decodedMin['title'], 'Smoke Test Report');
    });
  });
}
