# ScenarioKit Flutter

**ScenarioKit Flutter** is a developer-focused toolkit to define, preview, switch, and test UI scenarios (loading, success, empty, error, offline, and more) without touching production code. It ships a draggable debug panel, in-app **Test Mode**, step-based functional tests, screenshot capture, and JSON/HTML report export—all on the Flutter SDK only.

**Pub:** [pub.dev/packages/scenario_kit_flutter](https://pub.dev/packages/scenario_kit_flutter)

[![pub package](https://img.shields.io/pub/v/scenario_kit_flutter.svg)](https://pub.dev/packages/scenario_kit_flutter)
[![pub points](https://img.shields.io/pub/points/scenario_kit_flutter?color=blue)](https://pub.dev/packages/scenario_kit_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue)](https://pub.dev/packages/scenario_kit_flutter)

---

## 🎯 The Problem

### Previewing UI states

Developers constantly need to see how a screen looks in every meaningful state:

- **Loading:** shimmers, spinners, skeleton loaders.
- **Success:** populated lists and grids.
- **Empty:** zero results, first-time user states.
- **Error:** HTTP 500, validation failures, timeouts.
- **Offline:** cached data, connectivity banners.
- **Pagination:** “load more” and tail loaders.

Usually that means mocking APIs, flipping debug flags, killing the network, or rebuilding the app—slow, fragile, and easy to forget edge cases.

### Exercising flows on a real build

The same team also needs to **run functional checks** (tap fields, submit forms, assert copy and navigation) without maintaining two separate systems:

- Widget tests live in `test/` and rarely feel like the running app.
- Integration tests are powerful but heavy to wire up for every screen iteration.
- QA scripts in spreadsheets don’t run inside the debug build designers and PMs already have on device.

Failures are hard to share: no single place for step traces, screenshots, and exportable reports during day-to-day development.

### What ScenarioKit changes

**ScenarioKit Flutter** connects both problems in one debug-only toolkit:

1. **Scenarios** — register UI states once and switch between them from a floating panel (search, groups, apply & preview).
2. **Test Mode** — define reusable **interaction + assertion steps** per screen, run **Run Selected** / **Run All** against the **live app UI**, and review results in the **Report** tab with JSON/HTML export and screenshots.
3. **Same tests in CI** — import `package:scenario_kit_flutter/testing.dart` and run the identical suites with `ScenarioTestHarness` in `flutter test` or integration tests.

Previewing states and validating flows stop being separate hacks—they share one registry, one mental model, and one report format.

---

## ✨ Features

### Scenario modeling & preview

- **`Scenario` model** with IDs, names, descriptions, **groups**, **tags**, metadata, and `isDefault`.
- **Built-in factories:** `Scenario.loading`, `.success`, `.empty`, `.error`, `.offline`, `.paginationLoading`, and custom `builder`s.
- **`ScenarioRegistry`** & **`ScenarioController`** — register, filter by group, select by ID, reset to default, reactive updates.
- **`ScenarioViewer`** — render scenarios without the floating trigger (storybook/admin screens).
- **`ScenarioKitContentMode`** — preview scenarios layered on your live app or as isolated viewers.
- **`ScenarioSelectionPersistence`** — optional remember-last-scenario across hot restarts (debug).

### Developer UI (debug bottom sheet)

- **`ScenarioFloatingTrigger`** — draggable pill showing the active scenario; opens the panel.
- **`ScenarioPanel`** — three-tab console: **Scenarios**, **Tests**, **Report**.
- **Scenarios tab:** search (name, ID, group, tag), horizontal **group filter chips** with counts, responsive **scenario cards** (`DEFAULT` / **✓ Active**), **Apply scenario** / **Apply and preview**, metadata inspector dialog.
- **Tests tab:** `ScenarioTestDashboard` — screen/group/tag filters, search, select-all, **Run Selected** / **Run All**, per-test status and live execution against the **live app UI** (not the modal route).
- **Report tab:** `ScenarioReportsTab` — session history, pass/fail filters, expandable step traces, screenshot lightbox, **Copy JSON** / **Copy HTML** / full report viewer.
- **Header actions:** export last run, reset to default scenario, close sheet.
- **`ScenarioPanelThemeData`** — light (default panel chrome) and dark themes; customizable colors and radius.
- **Screen awareness:** `ScenarioKit.screenName` + `onNavigateToScreen` — Test Mode filters to the mounted screen and warns on mismatch.

### In-app functional testing

- **`ScenarioTest`** / **`ScenarioTestSuite`** — declarative tests with groups, tags, timeouts, setup/teardown, **`requiredScenarioId`**, screenshot policies.
- **`ScenarioTestRegistry`** — register suites, lookup by screen, filter by tag, replace/unregister suites.
- **Interaction steps:** tap, long-press, enter/clear text, scroll, drag, wait, wait-for-widget, custom steps, **`SelectScenarioStep`**.
- **Assertion steps:** exists / not exists, text (exact, contains, regex), visible, custom assertions.
- **`StepFinder`** — by key, text, type, tooltip, icon, semantics label, custom predicates; extensions for `WidgetTester`.
- **Dual execution:** in-app executor (`InAppStepContext`, real pointer events) and **`ScenarioTestHarness`** for `flutter test` / integration tests.
- **`ScenarioReportStore`** — reactive session store feeding the Reports tab.

### Reports, screenshots & export

- **`ScenarioScreenshotService`** & **`ScenarioRepaintBoundary`** — PNG capture with configurable policies per test.
- **`ScenarioTestReport`**, **`HtmlReportExporter`**, **`JsonReportExporter`** — standalone HTML (embedded screenshots) and CI-friendly JSON.
- **`ScenarioReportViewerDialog`** — KPIs, environment info, step timeline, failures.

### Widget & CI testing (`testing.dart`)

Separate entry point for test packages:

- **`pumpScenario`**, **`switchScenario`**, **`ScenarioTestHarness.runTest`** / **`runSuite`**.
- **Matchers:** `containsScenario`, `hasDefaultScenario`, `isTestPassed`, `hasPassedSteps`, execution summaries, and more.
- Same step definitions and registry as in-app Test Mode — one test catalog, two runtimes.

### Data, integrations & ergonomics

- **`MockData<T>`** — static values, generators, async delay simulation; attach to scenario metadata and read via extensions.
- **`ScenarioStateAdapter`** & **`ScenarioStateBuilder`** — map active scenarios into Bloc/Cubit/Riverpod/Provider-style state without extra deps.
- **`BuildContext` extensions** — `scenarioController`, `currentScenario`, scoped lookup helpers.
- **`ScenarioLogger`** — opt-in debug logging.

### Production safety & platform support

- **`ScenarioKit.enabled`** — typically `kDebugMode`; no floating UI or panel overhead in release builds.
- **Zero mandatory third-party packages** (Flutter SDK + `flutter_test` for exported harness APIs).
- Runs on **Android, iOS, Web, macOS, Windows, and Linux** (any Flutter target).

---

## 📦 Installation

Add `scenario_kit_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  scenario_kit_flutter: ^0.2.5
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Integration guide

ScenarioKit needs a **Material** navigator **Overlay** to open the bottom sheet (tap the floating pill). On mobile, use **`MaterialApp.builder`** so the kit wraps every route and the pill sits above system navigation (SafeArea bottom inset).

### Step 1 — Pick a content mode

| Mode | When to use | What you see |
|------|-------------|--------------|
| **Preview** (`home: ScenarioKit(scenarios: …)` only) | Storybook / design QA | [ScenarioViewer] swaps scenario `builder` UIs |
| **Overlay** (`MaterialApp.builder` + `child`) | **Production apps** | Your real screen stays visible; scenarios drive mocks/adapters |
| **Hybrid** | Demo apps | Production widget registered as a scenario + full viewer |

Set overlay explicitly when you pass both `child` and `scenarios`:

```dart
contentMode: ScenarioKitContentMode.overlay,
```

### Step 2 — Recommended setup (mobile / nested navigation)

Use one root `navigatorKey`, wrap routes in `MaterialApp.builder`, and pass the same key to `ScenarioKit`:

```dart
import 'package:flutter/material.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  registerMyTests(); // optional: ScenarioTestRegistry suites
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScenarioKit(
          navigatorKey: rootNavigatorKey,
          contentMode: ScenarioKitContentMode.overlay,
          screenName: 'Product Catalog',
          scenarios: catalogScenarios,
          onNavigateToScreen: (name) {
            // Optional: map Test Mode "Go to Screen" to your router
          },
          child: child,
        );
      },
      home: const ProductCatalogScreen(),
    );
  }
}

final catalogScenarios = <Scenario>[
  Scenario.success(
    id: 'catalog_success',
    name: 'Success',
    group: 'Catalog',
    isDefault: true,
    builder: (context) => const ProductCatalogScreen(),
  ),
  Scenario.loading(
    id: 'catalog_loading',
    name: 'Loading',
    group: 'Catalog',
    builder: (context) => const ProductLoadingSkeleton(),
  ),
  // empty / error / offline ...
];
```

- The floating pill respects **system navigation bars** (`SafeArea`, top disabled).
- Bottom sheets use the **root navigator** (`useRootNavigator: true`) so nested `Navigator` widgets do not trigger **No Overlay found**.
- In **overlay** mode, wire scenario changes into your state (Bloc/Riverpod/setState) via [`ScenarioStateBuilder`](#with-scenariostatebuilder-universal-reactive-builder) or [`ScenarioStateAdapter`](#with-bloc--cubit).

### Step 3 — Preview-only quick start (no production `child`)

For a standalone scenario switcher (no live app underneath):

```dart
MaterialApp(
  home: ScenarioKit(
    scenarios: catalogScenarios,
  ),
)
```

Tap the pill → search scenarios → **Apply scenario** or **Apply and preview**.

### Step 4 — Register tests (optional)

```dart
void registerMyTests() {
  ScenarioTestRegistry.instance.registerSuite(
    ScenarioTestSuite(
      screenName: 'Product Catalog', // must match ScenarioKit.screenName
      tests: [ /* ScenarioTest(…) */ ],
    ),
  );
}
```

### Troubleshooting

| Issue | Fix |
|-------|-----|
| **`No Overlay widget found`** | Put `ScenarioKit` **inside** `MaterialApp.builder` (not above `MaterialApp`). Pass `navigatorKey` to both `MaterialApp` and `ScenarioKit`. |
| Pill under Android nav buttons | Fixed by default (`SafeArea(top: false)` on the trigger). Avoid extra bottom `Padding` on the root `Scaffold`. |
| Tests run against the sheet, not the app | Use `MaterialApp.builder` so `ScenarioKit` wraps `child`; do not open the kit as an isolated `home` route without `child`. |
| Release build shows debug UI | Keep `enabled: kDebugMode` (default). |

See the [`example/`](example/) app for a full catalog + Test Mode demo.

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
  theme: ScenarioPanelThemeData.light().copyWith(
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
