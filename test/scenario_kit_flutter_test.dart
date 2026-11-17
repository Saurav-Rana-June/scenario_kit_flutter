import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioKit Flutter Foundation', () {
    test('provides accurate package metadata', () {
      expect(ScenarioKitInfo.packageName, 'scenario_kit_flutter');
      expect(ScenarioKitInfo.version, '0.1.0');
    });
  });
}
