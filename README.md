# ScenarioKit Flutter

A developer-focused Flutter toolkit to define, preview, test, and switch between different UI scenarios of application screens without modifying production code or business logic.

[![pub points](https://img.shields.io/pub/points/scenario_kit_flutter)](https://pub.dev/packages/scenario_kit_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🎯 Vision

Testing and previewing various UI states (loading, success, empty, error, offline, edge cases) often requires hacking API responses, manually toggling state flags, or running repetitive build cycles.

**ScenarioKit Flutter** makes it effortless to declare UI scenarios and interactively switch between them during development and automated testing.

## ✨ Core Principles

- **Framework Agnostic:** Works seamlessly with `setState`, `Bloc`, `Cubit`, `Riverpod`, `Provider`, `GetX`, or any custom state management.
- **Zero Mandatory Third-Party Dependencies:** Only relies on the Flutter SDK.
- **Clean Developer Experience:** Intuitive API and dedicated debug tooling.
- **Production Safe:** Debug tooling and panels can be completely stripped or disabled in production builds.
- **Test-Friendly:** Seamless integration with Flutter widget tests.

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

## 🚀 Quick Preview (API Preview)

```dart
ScenarioKit(
  scenarios: [
    Scenario(
      id: 'loading',
      name: 'Loading State',
      builder: (context) => const ProductListLoadingView(),
    ),
    Scenario(
      id: 'success',
      name: 'Success State',
      builder: (context) => const ProductListView(),
    ),
    Scenario(
      id: 'empty',
      name: 'Empty State',
      builder: (context) => const ProductListEmptyView(),
    ),
    Scenario(
      id: 'error',
      name: 'Error State',
      builder: (context) => const ProductListErrorView(),
    ),
  ],
  child: const ProductScreen(),
);
```

## 🛠️ Package Structure

```text
lib/
├── scenario_kit_flutter.dart       # Main public entry point
└── src/
    ├── core/                       # Core scenario models and registry
    ├── models/                     # Configuration and metadata data models
    ├── presentation/               # UI previewer widgets, panels, and toolbars
    ├── testing/                    # Widget testing helpers
    └── utils/                      # Internal helpers and constants
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
