import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioLogger', () {
    late List<String> logs;

    setUp(() {
      logs = [];
      ScenarioLogger.enabled = true;
      ScenarioLogger.printer = (msg) => logs.add(msg);
    });

    tearDown(() {
      ScenarioLogger.enabled = false;
      ScenarioLogger.printer = debugPrint;
    });

    test('logs formatted message when enabled', () {
      ScenarioLogger.log('Custom test message');
      expect(logs, ['[ScenarioKit] Custom test message']);
    });

    test('does not log when enabled is false', () {
      ScenarioLogger.enabled = false;
      ScenarioLogger.log('Should not appear');
      expect(logs, isEmpty);
    });

    test('attach logs scenario switches on controller', () {
      final s1 = Scenario(
          id: 's1', name: 'Scenario 1', builder: (c) => const SizedBox());
      final s2 = Scenario(
          id: 's2', name: 'Scenario 2', builder: (c) => const SizedBox());
      final controller = ScenarioController.fromScenarios([s1, s2]);

      final detach = ScenarioLogger.attach(controller);

      controller.selectById('s2');
      expect(logs.length, 1);
      expect(logs.first, contains('Scenario 2'));

      detach();
      controller.selectById('s1');
      // No more logs after detach
      expect(logs.length, 1);

      controller.dispose();
    });
  });
}
