import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('ScenarioTestHarness', () {
    Widget buildCounterApp({int initialCount = 0}) {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              appBar: AppBar(title: const Text('Counter App')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Count: $initialCount', key: const Key('count_text')),
                    ElevatedButton(
                      key: const Key('increment_btn'),
                      onPressed: () {
                        setState(() {
                          initialCount++;
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    testWidgets('runTest executes passing ScenarioTest with pumpApp',
        (tester) async {
      bool setupRan = false;
      bool teardownRan = false;

      final test = ScenarioTest(
        name: 'Increment counter test',
        group: 'CounterScreen',
        setup: (ctx) async {
          setupRan = true;
        },
        teardown: (ctx) async {
          teardownRan = true;
        },
        steps: [
          AssertTextStep(
            finder: StepFinder.byKey(const Key('count_text')),
            expectedText: 'Count: 0',
          ),
          TapStep(finder: StepFinder.byKey(const Key('increment_btn'))),
          AssertTextStep(
            finder: StepFinder.byKey(const Key('count_text')),
            expectedText: 'Count: 1',
          ),
        ],
      );

      final result = await ScenarioTestHarness.runTest(
        tester,
        test,
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
      );

      expect(result, isTestPassed);
      expect(result, hasPassedSteps(3));
      expect(setupRan, isTrue);
      expect(teardownRan, isTrue);
    });

    testWidgets('runTest handles failing assertions and records failure',
        (tester) async {
      final test = ScenarioTest(
        name: 'Failing counter test',
        steps: [
          AssertTextStep(
            finder: StepFinder.byKey(const Key('count_text')),
            expectedText: 'Count: 999',
          ),
        ],
      );

      final result = await ScenarioTestHarness.runTest(
        tester,
        test,
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
      );

      expect(result, isTestFailed);
      expect(result, hasFailedSteps(1));
      expect(result.errorMessage, contains('Count: 999'));
    });

    testWidgets('runTest captures screenshot callbacks when enabled',
        (tester) async {
      final capturedScreenshots = <String>[];

      final test = ScenarioTest(
        name: 'Screenshot test',
        screenshotPolicy: const ScreenshotPolicy(
          captureBeforeTest: true,
          captureOnSuccess: true,
        ),
        steps: [
          AssertExistsStep(
              finder: StepFinder.byKey(const Key('increment_btn'))),
        ],
      );

      final result = await ScenarioTestHarness.runTest(
        tester,
        test,
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
        onCaptureScreenshot: (name, {stepDescription, stepId}) async {
          capturedScreenshots.add(name);
          return ScenarioScreenshot(
            name: name,
            stepId: stepId,
            stepDescription: stepDescription,
            timestamp: DateTime.now(),
            bytes: Uint8List.fromList([1, 2, 3]),
          );
        },
      );

      expect(result, isTestPassed);
      expect(capturedScreenshots.length, 2);
      expect(result.screenshots.length, 2);
    });

    testWidgets(
        'runTest returns failed result when target widget is not mounted',
        (tester) async {
      final test = ScenarioTest(
        name: 'Unmounted test',
        steps: [
          AssertExistsStep(finder: StepFinder.byKey(const Key('anything'))),
        ],
      );

      final result = await ScenarioTestHarness.runTest(tester, test);
      expect(result, isTestFailed);
    });

    testWidgets('runSuite executes all tests in suite and resets with pumpApp',
        (tester) async {
      int pumpAppCalls = 0;

      final suite = ScenarioTestSuite(
        screenName: 'CounterScreen',
        tests: [
          ScenarioTest(
            name: 'First increment test',
            steps: [
              TapStep(finder: StepFinder.byKey(const Key('increment_btn'))),
              AssertTextStep(
                finder: StepFinder.byKey(const Key('count_text')),
                expectedText: 'Count: 1',
              ),
            ],
          ),
          ScenarioTest(
            name: 'Second isolated test starting fresh',
            steps: [
              AssertTextStep(
                finder: StepFinder.byKey(const Key('count_text')),
                expectedText: 'Count: 0',
              ),
              TapStep(finder: StepFinder.byKey(const Key('increment_btn'))),
              AssertTextStep(
                finder: StepFinder.byKey(const Key('count_text')),
                expectedText: 'Count: 1',
              ),
            ],
          ),
        ],
      );

      final summary = await ScenarioTestHarness.runSuite(
        tester,
        suite,
        pumpApp: () {
          pumpAppCalls++;
          return tester.pumpWidget(buildCounterApp());
        },
      );

      expect(summary, isExecutionSuccess);
      expect(summary, hasPassCount(2));
      expect(summary, hasFailCount(0));
      expect(pumpAppCalls, 2);
    });

    testWidgets('runSuite respects stopOnFirstFailure', (tester) async {
      final suite = ScenarioTestSuite(
        screenName: 'CounterScreen',
        tests: [
          ScenarioTest(
            name: 'Failing test',
            steps: [
              AssertTextStep(
                finder: StepFinder.byKey(const Key('count_text')),
                expectedText: 'Wrong Count',
              ),
            ],
          ),
          ScenarioTest(
            name: 'Unreached test',
            steps: [
              AssertExistsStep(
                  finder: StepFinder.byKey(const Key('increment_btn'))),
            ],
          ),
        ],
      );

      final summary = await ScenarioTestHarness.runSuite(
        tester,
        suite,
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
        stopOnFirstFailure: true,
      );

      expect(summary.totalTests, 1);
      expect(summary.failedCount, 1);
    });

    testWidgets('runSelectedTests executes only specified tests',
        (tester) async {
      final t1 = ScenarioTest(
        name: 'T1',
        steps: [
          AssertExistsStep(finder: StepFinder.byKey(const Key('count_text'))),
        ],
      );
      final t2 = ScenarioTest(
        name: 'T2',
        steps: [
          AssertExistsStep(
              finder: StepFinder.byKey(const Key('increment_btn'))),
        ],
      );

      final summary = await ScenarioTestHarness.runSelectedTests(
        tester,
        [t1, t2],
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
      );

      expect(summary, isExecutionSuccess);
      expect(summary.executionMode, ExecutionMode.functionality);
      expect(summary.totalTests, 2);
    });

    testWidgets('runAll executes all registered suites and generates report',
        (tester) async {
      final registry = ScenarioTestRegistry();
      registry.registerSuite(
        ScenarioTestSuite(
          screenName: 'Screen A',
          tests: [
            ScenarioTest(
              name: 'Test A1',
              steps: [
                AssertExistsStep(
                    finder: StepFinder.byKey(const Key('count_text'))),
              ],
            ),
          ],
        ),
      );
      registry.registerSuite(
        ScenarioTestSuite(
          screenName: 'Screen B',
          tests: [
            ScenarioTest(
              name: 'Test B1',
              steps: [
                AssertExistsStep(
                    finder: StepFinder.byKey(const Key('increment_btn'))),
              ],
            ),
          ],
        ),
      );

      final summaries = await ScenarioTestHarness.runAll(
        tester,
        registry,
        pumpApp: () => tester.pumpWidget(buildCounterApp()),
      );

      expect(summaries.length, 2);
      expect(summaries[0].screenName, 'Screen A');
      expect(summaries[1].screenName, 'Screen B');

      final report = ScenarioTestHarness.generateReport(
        summaries: summaries,
        title: 'CI Test Execution',
        environment: {'flutter_version': '3.x', 'platform': 'test'},
      );

      expect(report.title, 'CI Test Execution');
      expect(report.totalTests, 2);
      expect(report.passedCount, 2);
      expect(report.failedCount, 0);
      expect(report.successRate, 100.0);
      expect(report.environment['flutter_version'], '3.x');
    });
  });
}
