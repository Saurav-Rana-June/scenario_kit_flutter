# Changelog

All notable changes to `scenario_kit_flutter` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Active screen awareness**: `ScenarioKit.screenName` and `onNavigateToScreen`; Test Mode auto-filters to the mounted screen, marks the active chip, and shows a mismatch warning with optional **Go to Screen** navigation.
- `ScenarioScope.maybeActiveScreenNameOf` / `maybeNavigateToScreenOf` for host apps.

### Fixed
- Test Mode **Run All** from the bottom sheet now runs against the live app UI (via `appContentKey` / `executionContext`) instead of the modal route, and the sheet stays open while tests run.
- In-app taps no longer inject pointer id `0` (fixes Chrome `PointerHoverEvent` gesture assertions and bottom sheet dismissals); uses `InAppPointerEvents` with hit-test and non-mouse pointer ids.
- Widget search during in-app runs is scoped to app content under test (not the whole element tree including the modal).

## [0.2.1] - 2026-11-18

### Added
- `ScenarioKitContentMode`, `ScenarioSelectionPersistence`, and `Scenario.paginationLoading` factory.
- `Scenario.tags` for panel search; `ScenarioTest.requiredScenarioId` and `SelectScenarioStep`.
- `StepFinder.bySemanticsLabel`; test registry `replaceSuite`, `unregisterSuite`, `getTestsByTag`, and `DuplicateTestException`.
- In-app screenshot capture via `ScenarioKitBindings`; dashboard tag filters and copy JSON/HTML report actions.
- Example `integration_test/` sample; harness `resetBetweenTests`.

### Changed
- `flutter_test` moved to package `dev_dependencies`; harness utilities export only from `testing.dart`.
- `ScenarioScope` is now a plain `InheritedWidget` (fixes scenario switching under test harness).
- Assertion results and logs propagate into `TestExecutionResult`; runner wires default screenshots.

### Fixed
- Single-default validation on `ScenarioRegistry`; nested `ScenarioScope` in `ScenarioKit`/`ScenarioViewer`.
- Example network tests align scenarios via `requiredScenarioId` / `SelectScenarioStep`.

## [0.2.0] - 2026-11-17

### Added - ScenarioKit Test Mode
- **Test Mode Capability**: Introduced screen-level automated functional testing, screenshot capture, interactive execution dashboard, in-app report viewer, and standalone report generation for Flutter applications.
- **Declarative Test Definitions**:
  - `ScenarioTest`: Immutable test case model supporting unique IDs, auto-generated slugs, descriptions, screen/group association, setup/teardown callbacks, custom timeouts, tags, metadata, and configurable screenshot policies.
  - `ScenarioTestSuite`: Screen-level test suite container with automatic screen backfilling and group-based queries.
  - `ScenarioTestRegistry`: Reactive registry extending `ChangeNotifier` with ambient singleton instance, suite grouping, and live listener notifications.
  - `StepFinder`: Universal widget locator abstraction supporting `byKey`, `byKeyString`, `byText`, `byWidgetType`, `byTooltip`, `byIcon`, and `custom` element predicates.
  - `TestStatus` and `StepStatus` enums with state evaluation helpers.
- **Interaction & Assertion Steps Engine**:
  - `ScenarioStepContext`: Abstract execution contract defining 15 interaction, assertion, frame pumping, and polling primitives.
  - Interaction steps: `TapStep`, `LongPressStep`, `EnterTextStep`, `ClearTextStep`, `ScrollStep`, `DragStep`, `WaitStep`, `WaitForWidgetStep`, and `CustomStep`.
  - Assertion steps: `AssertExistsStep`, `AssertNotExistsStep`, `AssertTextStep` (exact, contains, regex), `AssertVisibleStep`, and `AssertCustomStep`.
  - `AssertionResult` diagnostic model and `AssertionException`.
  - `StepExecutionResult` capturing status, duration, error messages, and step-level screenshots.
- **In-App Execution Engine & Two Execution Modes**:
  - `InAppStepContext`: Dispatches test steps directly against live widget trees using root context element traversal, `GestureBinding` pointer simulation, and `EditableText` synchronization.
  - `ScenarioTestExecutor`: Orchestrates test execution with timeouts, cancellation tokens, setup/teardown isolation, step delay, live progress streams, and screenshot capture triggers.
  - `ScenarioTestRunner`:
    - **Mode A (Functionality-wise Execution)**: Execute an individual test or an arbitrary selected subset of tests.
    - **Mode B (Complete Screen Execution)**: Execute all registered tests for a screen in predictable order with consolidated summary reporting.
  - `ScreenExecutionSummary`: Aggregate execution results with duration, passed/failed/skipped counts, and serialization.
- **Screenshot Capture System**:
  - `ScenarioRepaintBoundary`: Repaint boundary widget anchoring screen-level rasterization.
  - `ScenarioScreenshotService`: High-fidelity PNG rasterizer via `RenderRepaintBoundary.toImage()`, optional device capture hooks for integration tests, memory buffer FIFO eviction (`maxInMemoryScreenshots`), and Base64 data URL formatting.
  - `ScreenshotPolicy`: Configurable capture checkpoints (`captureBeforeTest`, `captureOnSuccess`, `captureOnFailure`, `captureAfterSteps`).
- **Reporting & Exporters**:
  - `ScenarioTestReport`: Comprehensive report model aggregating multiple screen summaries with KPI metrics (success rate, passed, failed, skipped, duration, environment diagnostics).
  - `JsonReportExporter`: Minified and pretty-printed JSON test report serializer.
  - `HtmlReportExporter`: Standalone, interactive HTML report generator with embedded Base64 screenshots, expandable test steps, assertion logs, environment metadata badges, and zero external CDN or internet dependencies.
- **Test Mode UI**:
  - `ScenarioTestDashboard`: In-app test control center featuring screen/group filter chips, search input, multi-selection, progress bar, execution controls (`Run All`, `Run Selected`, `Cancel`), and status badges.
  - `ScenarioReportViewerDialog`: In-app modal report viewer displaying KPI cards, step execution breakdowns, diagnostic logs, and full-resolution screenshot zoom lightbox.
  - Mode Switcher: Integrated `Scenarios` vs `Test Mode` tab switcher in `ScenarioPanel` and `ScenarioFloatingTrigger`.
- **Automated Integration Test Harness**:
  - `WidgetTesterStepContext`: Concrete `ScenarioStepContext` implementation delegating to `WidgetTester`.
  - `StepFinderWidgetTesterExtension`: Automatic conversion from `StepFinder` to `flutter_test.Finder`.
  - `ScenarioTestHarness`: Automated test runner bridge (`runTest`, `runSuite`, `runSelectedTests`, `runAll`, `generateReport`) executing `ScenarioTest` definitions seamlessly in headless `testWidgets` or real-device `integration_test`.
  - `ScenarioTestMatchers`: Expressive test matchers (`isTestPassed`, `isTestFailed`, `isTestSkipped`, `isExecutionSuccess`, `hasPassedSteps`, `hasFailedSteps`, `hasPassCount`, `hasFailCount`).
- **Testing Entry Point**:
  - Dedicated `package:scenario_kit_flutter/testing.dart` library re-exporting all test definitions, harness utilities, matchers, runner, and reporters while preserving complete backward compatibility with scenario preview test utilities.

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
