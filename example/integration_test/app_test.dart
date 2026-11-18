import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runs catalog functional suite on device', (tester) async {
    registerExampleFunctionalTests();
    await tester.pumpWidget(const ScenarioKitExampleApp());
    await tester.pumpAndSettle();

    final suite = ScenarioTestRegistry.instance.getSuite('Product Catalog')!;
    final summary = await ScenarioTestHarness.runSuite(
      tester,
      suite,
      resetBetweenTests: true,
    );

    expect(summary, isExecutionSuccess);
  });
}
