# Changelog

All notable changes to `scenario_kit_flutter` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-17

### Added
- Initial project scaffolding and package architecture.
- Package metadata and SDK constraints configuration (`>=3.0.0 <4.0.0`).
- Strict linting configuration with `flutter_lints` and custom analyzer rules.
- Foundational package entry point and metadata definitions.
- `Scenario` model with automatic ID slugging, metadata immutability, copyWith, and value equality.
- `ScenarioRegistry` supporting single/batch registration, atomic duplicate validation, grouping, default scenario fallback, and reactive `ChangeNotifier` notifications.
- Typed scenario exceptions (`DuplicateScenarioException`, `ScenarioNotFoundException`, `InvalidScenarioException`).
- `ScenarioController` managing active scenario state, selection logic, auto-registration, and fallback transitions.
- `ScenarioScope` InheritedWidget enabling zero-boilerplate controller discovery across the widget tree without external state managers.
- `ScenarioViewer` widget supporting inline scenarios, external registries, smooth animated state switching, and developer fallback empty states.
- `ScenarioPanelThemeData` with tailored developer-tool light and dark themes.
- `ScenarioPanel` developer debug panel with real-time fuzzy search, group filtering, active scenario indicators, and metadata viewer dialogs.
- `ScenarioFloatingTrigger` draggable and positionable floating badge displaying the current scenario and launching the bottom sheet panel.
- `ScenarioKit` top-level wrapper supporting inline previewing, application wrapping, and release-mode auto-exclusion (`enabled: kDebugMode`).
- Generic, strongly-typed `MockData<T>` container supporting static values, dynamic generators, and simulated network delays.
- Standard UI state factory constructors on `Scenario` (`Scenario.loading`, `Scenario.success`, `Scenario.empty`, `Scenario.error`, `Scenario.offline`).
- Context and scenario extensions (`getMock<T>()`, `hasMock()`, `simulatedDelay`, `context.scenarioController`, `context.currentScenario`).
- `ScenarioLogger` utility for opt-in developer console tracking of active scenario transitions.
- `ScenarioStateAdapter<T>` reactive bridge implementing `ValueListenable<T?>` to plug scenarios into Bloc, Cubit, Riverpod, Provider, or GetX with zero third-party dependencies.
- `ScenarioStateBuilder<T>` widget bridging scenario changes directly into UI state without external state-management dependencies.
- Dedicated `package:scenario_kit_flutter/testing.dart` test library entry point protecting production bundles from test harness dependencies.
- `ScenarioWidgetTesterExtensions` with `pumpScenario`, `pumpScenarioById`, `pumpScenarioKit`, and `switchScenario` test helpers.
- Custom scenario matchers (`containsScenario`, `hasDefaultScenario`, `containsScenarioGroup`) for unit and widget test assertions.
- Complete, runnable reference application in `example/` demonstrating realistic product listing scenarios (Loading, Success, Empty, Error 500, Offline, and Pagination Loading).
- Example widget tests verifying scenario testing practices with `package:scenario_kit_flutter/testing.dart`.
- Full quality assurance audit: 100% doc comment coverage, 0 analyzer issues under strict mode, 0 formatting issues, and 63/63 passing tests.
