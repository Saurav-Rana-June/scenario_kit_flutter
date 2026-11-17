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
  scenario_kit_flutter: ^0.1.0
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
