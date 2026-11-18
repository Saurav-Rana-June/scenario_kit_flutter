# ScenarioKit Flutter

A developer-focused Flutter toolkit to define, preview, test, and switch between different UI scenarios of application screens without altering production code or business logic.

[![pub package](https://img.shields.io/pub/v/scenario_kit_flutter.svg)](https://pub.dev/packages/scenario_kit_flutter)
[![pub points](https://img.shields.io/pub/points/scenario_kit_flutter?color=blue)](https://pub.dev/packages/scenario_kit_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue)](https://pub.dev/packages/scenario_kit_flutter)

---

## 🎯 The Problem

Developers frequently need to preview and test diverse UI states:
- **Loading:** Shimmers, progress spinners, skeleton loaders.
- **Success:** Normal data lists, populated grids.
- **Empty:** Zero search results, first-time user empty states.
- **Error:** HTTP 500, invalid inputs, connection timeouts.
- **Offline:** Cached offline data, network warning banners.
- **Pagination:** Multi-page lists with bottom loaders.

Traditionally, previewing these requires hacking API responses, manually toggling state flags, disconnecting Wi-Fi, or running repetitive app rebuilds.

**ScenarioKit Flutter makes testing and switching between UI states effortless and interactive.**

---

## ✨ Features

- **🚀 Zero Mandatory Third-Party Dependencies:** Pure Flutter SDK only. Zero bloat, zero version conflicts.
- **🎨 Modern Developer Tool Aesthetic:** Includes sleek dark and light developer panels with search, group tabs, and metadata inspectors.
- **⚡ Interactive Floating Trigger:** Draggable badge on your screen displaying active scenario info; tap to open the switcher sheet.
- **🛡️ Production Safe:** Automatically disabled in release builds (`enabled: kDebugMode`), leaving zero UI overhead in production binaries.
- **🧩 Framework Agnostic:** Works seamlessly with `setState`, `Bloc`/`Cubit`, `Riverpod`, `Provider`, `GetX`, or any custom state management.
- **📦 Typed Mock Data Support:** Generic `MockData<T>` container for static datasets, dynamic generators, and simulated network delays.
- **🧪 Dedicated Testing Toolkit:** First-class widget test helpers (`pumpScenario`, `switchScenario`, custom matchers) via `package:scenario_kit_flutter/testing.dart`.

---

## 📦 Installation

Add `scenario_kit_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  scenario_kit_flutter: ^0.2.0
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

Wrap your screen or application with `ScenarioKit`:

```dart
import 'package:flutter/material.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScenarioKit(
        scenarios: [
          // 1. Success State (Default)
          Scenario.success(
            id: 'catalog_success',
            name: 'Success (5 Items)',
            description: 'Populated product catalog view',
            group: 'Catalog',
            isDefault: true,
            builder: (context) => const ProductListView(products: mockProducts),
          ),

          // 2. Loading State
          Scenario.loading(
            id: 'catalog_loading',
            name: 'Loading State',
            group: 'Catalog',
            builder: (context) => const ProductLoadingSkeleton(),
          ),

          // 3. Empty State
          Scenario.empty(
            id: 'catalog_empty',
            name: 'Empty State',
            group: 'Catalog',
            builder: (context) => const ProductEmptyView(),
          ),

          // 4. Server Error State
          Scenario.error(
            id: 'catalog_error',
            name: 'Error 500',
            group: 'Network',
            builder: (context) => const ProductErrorView(message: 'Server Error'),
          ),

          // 5. Offline State
          Scenario.offline(
            id: 'catalog_offline',
            name: 'Offline Mode',
            group: 'Network',
            builder: (context) => const ProductListView(
              products: cachedProducts,
              isOffline: true,
            ),
          ),
        ],
      ),
    );
  }
}
```

When you launch your app, a draggable floating pill (`⚡ Scenario: Success`) appears. Tap it to search, inspect metadata, and switch scenarios instantly!

---

## 📖 Core Concepts

### 1. `Scenario` Model
Scenarios represent isolated UI states. You can use standard factory constructors or custom definitions:

```dart
// Custom definition
final customScenario = Scenario(
  id: 'custom_promo',
  name: 'Special Promo Banner',
  description: 'Displays Black Friday campaign banner',
  group: 'Campaigns',
  isDefault: false,
  metadata: const {'discount': 25, 'campaign_id': 'bf_2026'},
  builder: (context) => const PromoScreen(),
);

// Built-in factories with standard defaults
Scenario.loading(builder: (context) => const LoadingScreen());
Scenario.success(builder: (context) => const ProductScreen());
Scenario.empty(builder: (context) => const EmptyScreen());
Scenario.error(builder: (context) => const ErrorScreen());
Scenario.offline(builder: (context) => const OfflineScreen());
```

### 2. Standalone `ScenarioViewer`
If you want to render scenarios without the floating trigger (e.g. inside an internal admin/storybook screen):

```dart
ScenarioViewer(
  scenarios: [
    Scenario.loading(builder: (c) => const LoadingView()),
    Scenario.success(builder: (c) => const SuccessView()),
  ],
  animationDuration: const Duration(milliseconds: 250),
)
```

### 3. Programmatic Scenario Switching (`ScenarioController`)
Access the active controller anywhere down the widget tree using `ScenarioScope`:

```dart
// Access via extension on BuildContext
final controller = context.scenarioController;

// Switch scenario by ID
controller.selectById('catalog_loading');

// Reset to default scenario
controller.resetToDefault();

// Inspect active scenario
final activeScenario = context.currentScenario;
```

---

## 🗄️ Mock Data Utilities

Use `MockData<T>` to decouple your mock datasets from screen logic:

```dart
// Static value
final staticMock = MockData<List<String>>.value(
  ['Apple', 'Banana', 'Cherry'],
  label: 'Fruit Catalog',
);

// Dynamic generator
final dynamicMock = MockData<int>.generator(
  () => Random().nextInt(100),
  label: 'Random Score',
);

// Simulated async network delay
final products = await staticMock.getAsync(
  delay: const Duration(milliseconds: 800),
);

// Attach to scenario and retrieve typed data
final scenario = Scenario(
  name: 'Product List',
  metadata: {'mock_data': staticMock},
  builder: (context) {
    final items = context.currentScenario?.getMock<List<String>>();
    return ListView(children: items?.map(Text.new).toList() ?? []);
  },
);
```

---

## 🔌 Framework Integrations

ScenarioKit includes zero-dependency adapters that connect seamlessly with any state-management library.

### With BLoC / Cubit

```dart
final adapter = ScenarioStateAdapter<ProductState>(
  controller: context.scenarioController,
  stateMapper: (scenario) => scenario?.getMock<ProductState>(),
);

adapter.addListener(() {
  if (adapter.value != null) {
    productCubit.emit(adapter.value!);
  }
});
```

### With `ScenarioStateBuilder` (Universal Reactive Builder)

```dart
ScenarioStateBuilder<ProductState>(
  builder: (context, state) {
    if (state is ProductLoading) return const LoadingSpinner();
    if (state is ProductSuccess) return ProductList(products: state.products);
    if (state is ProductError) return ErrorBanner(error: state.message);
    return const EmptyPlaceholder();
  },
)
```

---

## 🧪 Widget Testing Utilities

Import the dedicated testing library in your widget tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  testWidgets('renders loading state properly', (tester) async {
    final loadingScenario = Scenario.loading(
      builder: (context) => const ProductLoadingSkeleton(),
    );

    // Pump scenario directly in test harness
    await tester.pumpScenario(loadingScenario);

    expect(find.byType(ProductLoadingSkeleton), findsOneWidget);
  });

  testWidgets('tests scenario switching with controller', (tester) async {
    final controller = ScenarioController.fromScenarios([
      Scenario.loading(builder: (c) => const Text('Loading...')),
      Scenario.success(builder: (c) => const Text('Done!')),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: ScenarioViewer(controller: controller),
    ));

    expect(find.text('Done!'), findsOneWidget);

    // Programmatically switch scenario and settle animations
    await tester.switchScenario(controller, 'loading');

    expect(find.text('Loading...'), findsOneWidget);
  });

  test('verifies scenario registry configuration', () {
    final registry = ScenarioRegistry([
      Scenario.success(id: 'home_success', builder: (c) => const SizedBox()),
    ]);

    // Fluent matchers
    expect(registry, containsScenario('home_success'));
    expect(registry, hasDefaultScenario('home_success'));
  });
}
```

---

## 🧪 ScenarioKit Test Mode — Automated Functional Testing

ScenarioKit includes a screen-level automated functional testing, screenshot capture, and reporting engine. It allows Flutter developers to register, organize, execute, and review functional tests directly within the running application or in CI/headless integration tests.

### 1. Registering Screen Test Cases

Define screen-level test cases using intuitive interaction and assertion steps:

```dart
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void registerScreenTests() {
  ScenarioTestRegistry.instance.registerSuite(
    ScenarioTestSuite(
      screenName: 'Login Screen',
      tests: [
        ScenarioTest(
          name: 'Valid Credentials Login',
          group: 'Authentication',
          description: 'Enters valid email and password, taps login, and verifies dashboard navigation',
          steps: [
            // Assert form fields are visible
            AssertExistsStep(finder: StepFinder.byKeyString('email_field')),
            AssertExistsStep(finder: StepFinder.byKeyString('password_field')),

            // Fill in credentials
            EnterTextStep(
              finder: StepFinder.byKeyString('email_field'),
              text: 'user@example.com',
            ),
            EnterTextStep(
              finder: StepFinder.byKeyString('password_field'),
              text: 'secret123',
            ),

            // Tap submit and verify outcome
            TapStep(finder: StepFinder.byKeyString('login_button')),
            WaitForWidgetStep(finder: StepFinder.byText('Welcome Back')),
            AssertTextStep(
              finder: StepFinder.byKeyString('welcome_banner'),
              expectedText: 'Welcome Back',
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 2. Available Step Primitives

#### Interaction Steps
- `TapStep(finder: StepFinder)`
- `LongPressStep(finder: StepFinder, duration: Duration)`
- `EnterTextStep(finder: StepFinder, text: String)`
- `ClearTextStep(finder: StepFinder)`
- `ScrollStep(finder: StepFinder, offset: Offset)`
- `DragStep(finder: StepFinder, offset: Offset)`
- `WaitStep(duration: Duration)`
- `WaitForWidgetStep(finder: StepFinder, timeout: Duration)`
- `CustomStep(description: String, callback: (context) => ...)`

#### Assertion Steps
- `AssertExistsStep(finder: StepFinder)`
- `AssertNotExistsStep(finder: StepFinder)`
- `AssertTextStep(finder: StepFinder, expectedText: String, matchType: TextMatchType)` (exact, contains, regex)
- `AssertVisibleStep(finder: StepFinder)`
- `AssertCustomStep(description: String, assertion: (context) => ...)`

#### Universal StepFinder Locators
- `StepFinder.byKey(Key)`
- `StepFinder.byKeyString(String)`
- `StepFinder.byText(String)`
- `StepFinder.byWidgetType(Type)`
- `StepFinder.byTooltip(String)`
- `StepFinder.byIcon(IconData)`
- `StepFinder.custom((element) => bool)`

---

### 3. In-App Interactive Test Dashboard & Report Viewer

When running your app in debug mode with `ScenarioKit`:
1. Tap the floating trigger badge to open the developer bottom sheet.
2. Switch tabs from **Scenarios** to **Test Mode**.
3. Select an individual test, multiple tests, or all tests for a particular screen.
   - Set `ScenarioKit.screenName` to match your suite's `screenName` / `ScenarioTestSuite.screenName` so Test Mode auto-filters to the mounted screen and warns when you pick another screen's tests.
   - Optionally wire `onNavigateToScreen` so **Go to Screen** in the warning banner navigates your app.
4. Tap **Run Selected** or **Run All** to watch real-time step execution with live progress indicators.
5. Tap **View Report** to launch the comprehensive in-app report viewer featuring:
   - Success rate, pass/fail counters, and execution duration.
   - Expandable test step cards with individual timestamps and error diagnostics.
   - Embedded screenshot gallery with full-screen lightbox zoom.

---

### 4. Automated CI & Integration Test Harness

The exact same test cases registered for in-app testing can be executed headlessly in CI or on real devices using Flutter's official testing frameworks (`flutter test` or `integration_test`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('Executes login screen functional test', (tester) async {
    final test = ScenarioTest(
      name: 'Valid Login',
      steps: [
        EnterTextStep(finder: StepFinder.byKeyString('email'), text: 'test@mail.com'),
        TapStep(finder: StepFinder.byKeyString('submit_btn')),
        AssertExistsStep(finder: StepFinder.byText('Welcome')),
      ],
    );

    final result = await ScenarioTestHarness.runTest(
      tester,
      test,
      pumpApp: () => tester.pumpWidget(const MyApp()),
    );

    // Custom ScenarioKit matchers
    expect(result, isTestPassed);
    expect(result, hasPassedSteps(3));
  });

  testWidgets('Executes entire screen test suite', (tester) async {
    final suite = ScenarioTestRegistry.instance.findSuite('Login Screen')!;

    final summary = await ScenarioTestHarness.runSuite(
      tester,
      suite,
      pumpApp: () => tester.pumpWidget(const MyApp()),
      stopOnFirstFailure: false,
    );

    expect(summary, isExecutionSuccess);
    expect(summary, hasPassCount(suite.tests.length));
  });
}
```

---

### 5. Screenshot Capture & Standalone HTML Reports

ScenarioKit captures rasterized screenshots at configurable checkpoints (`captureBeforeTest`, `captureAfterSteps`, `captureOnFailure`, `captureOnSuccess`).

Export complete, standalone HTML dashboards with zero external CDN dependencies:

```dart
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void exportResults(ScenarioTestReport report) {
  // Standalone HTML report with embedded Base64 screenshots
  final html = const HtmlReportExporter().export(report);

  // Machine-readable JSON report for CI pipelines
  final json = const JsonReportExporter().export(report);
}
```

---

## 🎨 Theming & Customization

Customize the developer panel theme to match your brand or preferences:

```dart
ScenarioKit(
  theme: ScenarioPanelThemeData.dark().copyWith(
    primaryColor: Colors.deepPurpleAccent,
    borderRadius: BorderRadius.circular(12),
  ),
  floatingTriggerAlignment: Alignment.bottomLeft,
  scenarios: [ ... ],
  child: const HomeScreen(),
)
```

---

## 📱 Example Application

A complete showcase application is available in the [`example/`](example/) directory, demonstrating realistic e-commerce states (Loading, Success, Empty, Server Error 500, Offline, and Pagination Loading).

To run the example:

```bash
cd example
flutter run
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
