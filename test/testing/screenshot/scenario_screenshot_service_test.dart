import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioScreenshotService', () {
    testWidgets('captures valid PNG screenshot from ScenarioRepaintBoundary',
        (tester) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioRepaintBoundary(
              boundaryKey: boundaryKey,
              child: Container(
                width: 200,
                height: 200,
                color: Colors.blue,
                child: const Text('Captured Screen'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final service = ScenarioScreenshotService(boundaryKey: boundaryKey);
      ScenarioScreenshot? screenshot;

      await tester.runAsync(() async {
        screenshot = await service.capture(
          name: 'test_screen',
          stepId: 'step_1',
          stepDescription: 'Verify UI',
        );
      });

      expect(screenshot, isNotNull);
      expect(screenshot!.name, 'test_screen');
      expect(screenshot!.stepId, 'step_1');
      expect(screenshot!.stepDescription, 'Verify UI');
      expect(screenshot!.deviceWidth, 200);
      expect(screenshot!.deviceHeight, 200);
      expect(screenshot!.bytes.length, greaterThan(0));

      // Validate PNG magic bytes (0x89, 0x50, 0x4E, 0x47)
      expect(screenshot!.bytes[0], 0x89);
      expect(screenshot!.bytes[1], 0x50);
      expect(screenshot!.bytes[2], 0x4E);
      expect(screenshot!.bytes[3], 0x47);
    });

    testWidgets('captures via deviceCaptureAdapter when configured',
        (tester) async {
      final customBytes = Uint8List.fromList([10, 20, 30, 40]);
      var adapterCalled = false;

      final service = ScenarioScreenshotService(
        deviceCaptureAdapter: (name) async {
          adapterCalled = true;
          return customBytes;
        },
      );

      final screenshot = await service.capture(name: 'device_screen');

      expect(adapterCalled, isTrue);
      expect(screenshot, isNotNull);
      expect(screenshot!.bytes, customBytes);
      expect(screenshot.name, 'device_screen');
    });

    test('evicts oldest screenshot when maxInMemoryScreenshots is exceeded',
        () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final service = ScenarioScreenshotService(
        deviceCaptureAdapter: (name) async => dummyBytes,
        maxInMemoryScreenshots: 2,
      );

      await service.capture(name: 's1');
      await service.capture(name: 's2');
      expect(service.capturedScreenshots.map((s) => s.name).toList(),
          ['s1', 's2']);

      // Capturing 3rd evicts s1
      await service.capture(name: 's3');
      expect(service.capturedScreenshots.map((s) => s.name).toList(),
          ['s2', 's3']);

      service.clear();
      expect(service.capturedScreenshots, isEmpty);
    });

    test('toBase64DataUrl produces compliant data URL', () {
      final bytes = Uint8List.fromList(utf8.encode('image_data'));
      final dataUrl = ScenarioScreenshotService.toBase64DataUrl(bytes);

      expect(dataUrl, startsWith('data:image/png;base64,'));
      final encoded = dataUrl.replaceFirst('data:image/png;base64,', '');
      expect(utf8.decode(base64Decode(encoded)), 'image_data');
    });

    testWidgets('integrates with ScenarioTestExecutor for failure checkpoint',
        (tester) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioRepaintBoundary(
              boundaryKey: boundaryKey,
              child: const Center(
                child: Text('Login Screen'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final service = ScenarioScreenshotService(boundaryKey: boundaryKey);
      final executor = ScenarioTestExecutor(
        onCaptureScreenshot: (name, {stepId, stepDescription}) {
          return service.capture(
            name: name,
            stepId: stepId,
            stepDescription: stepDescription,
          );
        },
      );

      final failingTest = ScenarioTest(
        name: 'Failing Test with Screenshot',
        screenshotPolicy: const ScreenshotPolicy.onFailureOnly(),
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('missing_element')),
        ],
      );

      final element = tester.element(find.byType(Scaffold));
      late TestExecutionResult result;

      await tester.runAsync(() async {
        result = await executor.executeTest(failingTest, context: element);
      });

      expect(result.isFailed, isTrue);
      expect(result.screenshots.length, 1);
      expect(result.screenshots.first.name, contains('failure'));
      expect(service.capturedScreenshots.length, 1);
    });
  });
}
