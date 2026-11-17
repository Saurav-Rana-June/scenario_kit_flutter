import 'dart:convert';

import 'scenario_test_report.dart';

/// Exporter that serializes a [ScenarioTestReport] into structured JSON.
class JsonReportExporter {
  /// Creates a [JsonReportExporter].
  const JsonReportExporter();

  /// Exports [report] as a JSON string.
  ///
  /// Set [pretty] to `true` to format with indentation.
  String export(ScenarioTestReport report, {bool pretty = true}) {
    final map = report.toJson();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }
}
