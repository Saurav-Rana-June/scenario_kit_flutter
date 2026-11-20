# ScenarioKit Flutter — UI structure & initialization reference

**Purpose of this document:** Hand this file to a design/UX assistant (e.g. Claude) to propose improved UI/UX while keeping the same widget boundaries, data flow, and Flutter integration points. It describes **where UI lives**, **how widgets nest**, and **what each file does in `initState` / first build**.

**Package version covered:** 0.2.4  
**Primary theme default:** `ScenarioPanelThemeData.light()` (floating trigger + panel unless `ScenarioKit.theme` overrides)

---

## 1. How the developer UI is shown (entry flow)

```
App (MaterialApp)
  └─ MaterialApp.builder (recommended) → ScenarioKit
       ├─ ScenarioScope (controller, screenName, navigation hook)
       ├─ ScenarioKitBindings (screenshot keys, testsRunning, navigatorKey)
       ├─ Stack
       │    ├─ App content / ScenarioViewer (KeyedSubtree + RepaintBoundary)
       │    └─ ScenarioFloatingTrigger (pill, draggable optional)
       └─ On tap pill → showModalBottomSheet → ScenarioPanel
            ├─ Tab: Scenarios (inline in scenario_panel.dart)
            ├─ Tab: Tests → ScenarioTestDashboard
            └─ Tab: Reports → ScenarioReportsTab
```

**Modal host:** `lib/src/utils/scenario_panel_host.dart` — `ScenarioPanelHost.modalContext()` picks a context with a valid `Overlay` (prefers `ScenarioKitBindings.navigatorKey`, then root navigator).

---

## 2. File tree (presentation + UI-related utils)

```
lib/src/presentation/
├── scenario_kit.dart              # Root wrapper: content modes + floating trigger stack
├── scenario_kit_bindings.dart     # InheritedWidget: screenshots, test run flag, navigatorKey
├── scenario_scope.dart            # InheritedWidget: ScenarioController + screen metadata
├── scenario_viewer.dart           # Animated scenario preview (no developer chrome)
├── theme/
│   └── scenario_panel_theme.dart  # ScenarioPanelThemeData (light/dark factories)
└── widgets/
    ├── scenario_floating_trigger.dart   # Pill + opens bottom sheet
    ├── scenario_panel.dart              # Bottom sheet body: header, tabs, Scenarios UI
    ├── scenario_test_dashboard.dart     # Tests tab: filters, run, progress, test cards
    ├── scenario_reports_tab.dart        # Reports tab: run history, expandable results
    └── scenario_report_viewer.dart      # Full-screen dialog for HTML-style report view

lib/src/utils/
└── scenario_panel_host.dart       # Overlay/modal context resolution (not visual, required for sheets)
```

**Exports:** Public API re-exports presentation types from `lib/scenario_kit_flutter.dart`; app integrators usually only import the barrel file.

---

## 3. Design tokens (`ScenarioPanelThemeData`)

| Token | Role in UI |
|--------|------------|
| `backgroundColor` | Sheet/page background behind lists |
| `surfaceColor` | Headers, cards, search fields |
| `primaryColor` | Brand, selected chips, primary buttons |
| `onPrimaryColor` | Text on primary-filled controls |
| `textColor` | Primary labels |
| `subtitleColor` | Descriptions, hints, inactive tabs |
| `borderColor` | Outlines, dividers |
| `chipColor` | Segmented tab track, ID badges, inactive pill backgrounds |
| `activeItemColor` | (Available; scenario cards use primary border/shadow instead) |
| `successColor` / `errorColor` / `warningColor` | Status dots, test badges, report header gradient logic |
| `borderRadius` | Panel corners (sheet top uses `topLeft` / `topRight`) |
| `panelElevation` | Documented for panels; sheet uses hard-coded `BoxShadow` on trigger/sheet |
| `cardColor` / `effectiveCardColor` | Optional card surface override |

**Factories:** `ScenarioPanelThemeData.light()` and `.dark()` — floating trigger and panel default to **light** when `theme` is null.

**Responsive breakpoints used in code:**

| Location | Breakpoint | Behavior |
|----------|------------|----------|
| `scenario_panel.dart` `_buildHeader` | `maxWidth < 820` | Header stacks: title row + tab bar below |
| `scenario_panel.dart` `_buildScenariosGrid` | `maxWidth >= 720` | 2-column grid vs vertical list |
| `scenario_report_viewer.dart` | `maxWidth: 820`, `maxHeight: 720` | Dialog size cap |

---

## 4. Widget-by-widget reference

### 4.1 `scenario_kit.dart` — `ScenarioKit` / `_ScenarioKitState`

**Role:** Top-level developer shell. Owns scenario controller (unless injected), screenshot boundary, and optional floating trigger.

**Constructor highlights:**

- `enabled` (default `kDebugMode`), `showFloatingTrigger`, `floatingTriggerAlignment`
- `contentMode`: `preview` | `overlay` | `hybrid` (inferred from `child` + `scenarios`)
- `navigatorKey`: must match `MaterialApp.navigatorKey` when using `builder` pattern
- `hideOverlayWhileTestsRun` + internal `_testsRunning` hides/fades trigger during tests

**`initState`:**

1. `_screenshotService = ScenarioScreenshotService(boundaryKey: _screenshotBoundaryKey)`
2. `_initController()` — uses `widget.controller`, or builds from `registry`, or `ScenarioController.fromScenarios` (hybrid mode injects `production_child` scenario wrapping `child`)
3. `_restorePersistedScenario()` — async load from `persistence` if owned controller

**State fields:**

- `_controller`, `_ownsController`
- `_screenshotBoundaryKey`, `_appContentKey`
- `_screenshotService`
- `_testsRunning` (`ValueNotifier<bool>`)

**`build` when `enabled`:**

1. Content wrapped in `ScenarioRepaintBoundary` + `KeyedSubtree` (`_appContentKey`)
2. `Stack`: content + `ScenarioFloatingTrigger` (opacity 0 / ignore pointer when tests running)
3. Outer: `ScenarioScope` → `ScenarioKitBindings` → body

**When `!enabled`:** No stack/trigger; still `ScenarioScope` + repaint boundary for adapters/screenshots.

**UX surfaces:** None directly except hosting the floating pill and enabling/disabling it.

---

### 4.2 `scenario_kit_bindings.dart` — `ScenarioKitBindings`

**Role:** `InheritedWidget` — no visual UI.

**Not constructed in `initState`** — passed from `ScenarioKit.build`.

**Provides:** `navigatorKey`, `screenshotBoundaryKey`, `appContentKey`, `screenshotService`, `testsRunning`.

**Used by:** Test executor (`resolveExecutionContext`), `ScenarioPanelHost`, test dashboard execution context.

---

### 4.3 `scenario_scope.dart` — `ScenarioScope`

**Role:** `InheritedWidget` — exposes `ScenarioController`, `screenName`, `onNavigateToScreen`.

**No `initState`.** Children call `ScenarioScope.of(context)` (e.g. floating trigger, panel).

---

### 4.4 `scenario_viewer.dart` — `ScenarioViewer` / `_ScenarioViewerState`

**Role:** End-user/scenario **preview** surface (not the developer panel). Switches scenario widgets with `AnimatedSwitcher`.

**`initState`:** `_initController()` — same ownership pattern as `ScenarioKit` (external vs owned controller).

**`build`:**

- `AnimatedBuilder` on controller → `KeyedSubtree` per scenario id → `AnimatedSwitcher`
- Optional wrap: `ScenarioScope` when `wrapWithScope: true`
- Empty state: custom `emptyBuilder` or default centered icon + copy

**UX:** Empty state uses Material `Theme.of(context)` (app theme), not `ScenarioPanelThemeData`.

---

### 4.5 `scenario_panel_theme.dart` — `ScenarioPanelThemeData`

**Role:** Immutable theme config for **all developer chrome** (panel, tabs, dashboard, reports, dialogs).

**No widgets.** Factories `light()` / `dark()`; `copyWith` for overrides.

---

### 4.6 `scenario_floating_trigger.dart` — `ScenarioFloatingTrigger` / `_ScenarioFloatingTriggerState`

**Role:** Persistent **floating pill** showing active scenario name; opens developer bottom sheet.

**No `initState`** — only `_dragOffset = Offset.zero` as field initializer.

**State:**

- `_dragOffset` — updated in `onPanUpdate` when `isDraggable: true` (default)

**Theme:** `widget.theme ?? ScenarioPanelThemeData.light()`

**Opening the panel (`_openPanel`):**

1. `ScenarioPanelHost.modalContext(context)`
2. `showModalBottomSheet` — `useRootNavigator: true`, transparent background, `isScrollControlled: true`, max height **85%** of screen
3. Sheet container: `panelTheme.backgroundColor`, top corner radius from theme, shadow
4. `SafeArea(top: false)` → `ScenarioPanel` with `testExecutionContext: context` (host under kit, not sheet context)

**Pill visual structure (`build`):**

- `AnimatedBuilder` on `ScenarioController`
- `SafeArea(top: false)` → `Align(initialAlignment)` → `Padding(16)` 
- Pill: `BackdropFilter` blur, semi-transparent `surfaceColor`, border, dual shadow
- Row: status dot (success/error), tune icon in tinted box, ellipsis label (max 160px), optional drag handle icon

**Test keys:** `Key('scenario_floating_trigger_button')`

---

### 4.7 `scenario_panel.dart` — `ScenarioPanel` / `_ScenarioPanelState`

**Role:** Main **bottom sheet content** — header, segmented tabs, three tab bodies.

**Private enum:** `_PanelTab { scenarios, tests, reports }`

**`initState`:**

1. `_reportStore = widget.reportStore ?? ScenarioReportStore.instance`
2. `_reportStore.addListener(_onStoreChanged)` → `setState` on new runs
3. `_searchController.addListener(_onSearchChanged)` → updates `_searchQuery`

**State fields:**

| Field | Purpose |
|--------|---------|
| `_searchController` / `_searchQuery` | Scenario tab search |
| `_selectedGroupFilter` | `null` = All groups |
| `_activeTab` | Current segment |
| `_reportStore` | Report counts on Reports tab badge |

**`dispose`:** Remove listeners; dispose search controller.

**`build`:**

1. Resolve `controller` from widget or `ScenarioScope`
2. Wrap in local `ThemeData` (light Material3 tinted with panel colors)
3. `AnimatedBuilder` on controller
4. `Column`: optional header (`showHeader`) + `Expanded(_buildActiveTabBody)`

**Header (`showHeader: true`, default):**

- `_buildDragHandle` — 36×4 gray bar (`#CBD5E1`)
- `_buildHeader` — logo + “ScenarioKit” + segmented tabs + actions
  - **Compact** (`width < 820`): tabs under title row
  - **Wide:** tabs inline between title and actions
- Actions: **Export** (latest report JSON/HTML/dialog), **Reset** scenario, **Close** (if `onClose`)

**Segmented tabs (`_buildSegmentedTabBar`):**

- Scenarios (count = registry size)
- Tests (count = `testRegistry.totalTestCount`)
- Reports (badge = failure count if any, else run count; warning styling if failures)

**Tab: Scenarios (same file):**

- `_buildSearchBar` — outlined field, clear button, “/” hint suffix when empty
- `_buildGroupFilters` — horizontal chips: All + each `registry.groups`
- `_buildScenariosGrid` — grid (2 col, 200px extent) if wide else list
- `_buildScenarioCard` — name, DEFAULT badge, Active chip, description, id/group/meta chips, Apply / Apply and preview
- `_showMetadataDialog` — `AlertDialog` keyed metadata rows
- Empty: `_buildEmptyResults`

**Tab: Tests:** embeds `ScenarioTestDashboard` (see §4.8)

**Tab: Reports:** embeds `ScenarioReportsTab` (see §4.9)

**Export (`_handleExportReport`):** Snackbar if no runs; else bottom sheet with Copy JSON, Copy HTML, View Full Report Dialog.

**Test keys:** `panel_tab_scenarios`, `panel_tab_tests`, `panel_tab_reports`, `panel_export_button`, `filter_chip_*`

---

### 4.8 `scenario_test_dashboard.dart` — `ScenarioTestDashboard` / `_ScenarioTestDashboardState`

**Role:** **Tests** tab — filter tests, select, run in-app, show progress, expand steps/results.

**`initState`:**

1. `_registry = widget.registry ?? ScenarioTestRegistry.instance`
2. `_runner = widget.runner ?? ScenarioTestRunner(registry: _registry)`
3. `_searchController = TextEditingController()` + listener → `_searchQuery`
4. `_registry.addListener(_onRegistryChanged)`
5. `_applyActiveScreenFilter()` — if `currentScreenName` has tests, set `_selectedScreen`

**State fields (selection & execution):**

| Field | Purpose |
|--------|---------|
| `_selectedScreen`, `_selectedGroup`, `_selectedTag` | Filter dimensions |
| `_searchQuery` | Text filter |
| `_selectedTestIds` | Multi-select for batch run |
| `_expandedTestIds` | Accordion open tests |
| `_latestResults` | Per-test last result map |
| `_lastSummary` | Last screen execution summary |

**`didUpdateWidget`:** Re-apply screen filter when `currentScreenName` changes.

**`build` layout (top → bottom):**

1. `_buildHeader` — “Test Mode” + total count badge + optional close
2. `_buildScreenFilterChips` — All Screens + per-screen chips (highlights active screen)
3. `_buildGroupFilterChips` / `_buildTagFilterChips` — when non-empty
4. `_buildScreenMismatchBanner` — amber warning if selected screen ≠ `currentScreenName` (+ Go to Screen if callback)
5. `_buildSearchBar`
6. `_buildActionControls` — select all, run selected, view report, etc.
7. `ValueListenableBuilder` on `_runner.progressNotifier` → `_buildProgressBanner` while running
8. `Divider`
9. `Expanded` → `_buildTestList` or `_buildEmptyState`

**Test cards (`_buildTestCard`):** Checkbox, status badge, expand for steps, run single test, blocked state when screen mismatch.

**Execution:** `_runSelectedTests` / single run use `_executionContext()` → `ScenarioKitBindings.resolveExecutionContext`; on complete → `ScenarioReportStore.instance.recordSummary`, `onExecutionCompleted`, `onViewReport` navigation to Reports tab from panel.

**File size:** ~1500 lines — most UI is private `_build*` methods in this single state class (no sub-widgets extracted).

---

### 4.9 `scenario_reports_tab.dart` — `ScenarioReportsTab` / `_ScenarioReportsTabState`

**Role:** **Reports** tab — browse stored run summaries, filter pass/fail, expand step details & screenshots.

**Private enum:** `_ReportFilter { all, failed, passed }`

**`initState`:**

1. `_store = widget.reportStore ?? ScenarioReportStore.instance`
2. `_store.addListener(_onStoreChanged)`

**State:**

- `_selectedFilter`
- `_expandedResultIds` — per `TestExecutionResult` id
- `_selectedRunIndex` — when multiple runs in store

**`build`:**

- Empty → `_buildEmptyState` (CTA to switch to Tests via `onSwitchToTests`)
- Else `ListView`: `_buildRunsHeader` (run picker, stats, export actions) → `_buildFilterBar` → list of `_buildTestReportCard`

**Cards:** Expandable sections — `_buildStepsColumn`, `_buildStepRow`, `_buildScreenshotColumn` for failure artifacts.

**Export:** `_copyJson`, `_copyHtml`, `_viewFullReport` → `ScenarioReportViewerDialog.show`

---

### 4.10 `scenario_report_viewer.dart` — `ScenarioReportViewerDialog`

**Role:** Modal **full report** dialog (used from panel export sheet and reports tab).

**Stateless** — no `initState`.

**`show` static:** `showDialog` + `ScenarioPanelHost.modalContext`, `useRootNavigator: true`.

**`build` structure:**

- `Dialog` — max 820×720, clipped radius
- `_buildHeader` — green/red **gradient banner** from `report.isSuccess`
- Scroll body: `_buildKpiGrid`, optional `_buildEnvironmentCard`, list of `_buildTestCard` per result (steps, assertions, screenshots inline)

---

### 4.11 `scenario_panel_host.dart` — `ScenarioPanelHost`

**Role:** Utility only — resolves modal `BuildContext`. No UI.

**Called from:** floating trigger sheet, panel dialogs, export sheets, report viewer.

---

## 5. Cross-cutting UX behaviors (for redesign proposals)

| Behavior | Where implemented |
|----------|-------------------|
| Sheet height cap 85% | `scenario_floating_trigger.dart` |
| Sheet not dismissible by tap outside | `isDismissible: false` on main panel sheet |
| Drag handle on panel | `scenario_panel.dart` |
| Root navigator for all modals | `useRootNavigator: true` + `ScenarioPanelHost` |
| Hide floating pill during tests | `scenario_kit.dart` + `testsRunning` notifier |
| Safe area on pill (not top) | `scenario_floating_trigger.dart` |
| Safe area on sheet content | bottom sheet wrapper in trigger |
| Local Theme override in panel | `scenario_panel.dart` forces light Material3 slice |
| Test / widget keys | See keys listed in §4.6–4.7 (preserve or update tests if renaming) |

---

## 6. Dependencies between UI and non-UI layers

| UI consumer | Core / testing dependency |
|-------------|---------------------------|
| `ScenarioKit`, `ScenarioViewer` | `ScenarioController`, `ScenarioRegistry`, `Scenario` |
| `ScenarioPanel` (Scenarios tab) | `controller.select`, `resetToDefault`, scenario metadata |
| `ScenarioTestDashboard` | `ScenarioTestRegistry`, `ScenarioTestRunner`, `TestExecutionProgress` |
| Reports / Export | `ScenarioReportStore`, `ScenarioTestReport`, JSON/HTML exporters |
| Screenshots in reports | `ScenarioKitBindings.screenshotService` + boundary key |

Redesigns should **not** break: controller listener pattern (`AnimatedBuilder`), `testExecutionContext` passing into panel/dashboard, or `navigatorKey` wiring.

---

## 7. Suggested prompt for a UX assistant

When asking for an improved design, include:

1. This entire document.
2. Target surfaces (e.g. “Scenarios tab cards + header only” or “full bottom sheet”).
3. Constraints: Flutter Material 3, must keep 3 tabs, searchable lists, in-app test execution unchanged.
4. Deliverables wanted: color/type/spacing spec, component breakdown, optional HTML mock, mapping from mock → existing `_build*` methods in `scenario_panel.dart` / `scenario_test_dashboard.dart`.

**Out of scope for pure UI pass:** `scenario_viewer.dart` (app preview), `ScenarioPanelHost`, `ScenarioKitBindings` internals — unless navigation overlay layout changes.

---

## 8. Quick inventory of private UI builders (refactor / redesign map)

**`scenario_panel.dart`**

- `_buildActiveTabBody`, `_buildDragHandle`, `_buildHeader`, `_buildBrandLogo`, `_buildBrandTitle`, `_buildHeaderActions`, `_buildSegmentedTabBar`, `_buildSegmentTab`, `_buildSearchBar`, `_buildGroupFilters`, `_buildFilterChip`, `_buildEmptyResults`, `_buildScenariosGrid`, `_buildScenarioCard`

**`scenario_test_dashboard.dart`**

- `_buildHeader`, `_buildScreenFilterChips`, `_buildScreenMismatchBanner`, `_buildScreenChip`, `_buildTagFilterChips`, `_buildGroupFilterChips`, `_buildFilterPill`, `_buildSearchBar`, `_buildActionControls`, `_buildProgressBanner`, `_buildMetricBadge`, `_buildTestList`, `_buildTestCard`, `_buildStatusBadge`, `_buildEmptyState`

**`scenario_reports_tab.dart`**

- `_buildEmptyState`, `_buildRunsHeader`, `_buildExportActions`, `_buildFilterBar`, `_buildFilterChip`, `_buildNoMatchingFilterState`, `_buildTestReportCard`, `_buildStepsColumn`, `_buildStepRow`, `_buildScreenshotColumn`

**`scenario_report_viewer.dart`**

- `_buildHeader`, `_buildKpiGrid`, `_buildEnvironmentCard`, `_buildTestCard`, plus nested step/assertion row builders in same file

**`scenario_floating_trigger.dart`**

- Inline pill UI in `build`; sheet wrapper in `_openPanel`

---

*Generated for `scenario_kit_flutter` presentation layer documentation. Update this file when adding new widgets or changing `initState` contracts.*