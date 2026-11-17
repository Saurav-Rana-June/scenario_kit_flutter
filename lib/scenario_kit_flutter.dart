/// ScenarioKit Flutter
///
/// A developer-focused Flutter toolkit that allows developers to define, preview,
/// test, and switch between different UI scenarios of their application screens
/// without modifying production code or business logic.
library;

export 'src/core/scenario.dart';
export 'src/core/scenario_controller.dart';
export 'src/core/scenario_exceptions.dart';
export 'src/core/scenario_kit_info.dart';
export 'src/core/scenario_registry.dart';
export 'src/integrations/scenario_state_adapter.dart';
export 'src/integrations/scenario_state_builder.dart';
export 'src/models/mock_data.dart';
export 'src/presentation/scenario_kit.dart';
export 'src/presentation/scenario_scope.dart';
export 'src/presentation/scenario_viewer.dart';
export 'src/presentation/theme/scenario_panel_theme.dart';
export 'src/presentation/widgets/scenario_floating_trigger.dart';
export 'src/presentation/widgets/scenario_panel.dart';
export 'src/presentation/widgets/scenario_report_viewer.dart';
export 'src/presentation/widgets/scenario_test_dashboard.dart';
export 'src/testing/assertions/assertion_result.dart';
export 'src/testing/assertions/assertion_steps.dart';
export 'src/testing/definitions/scenario_test.dart';
export 'src/testing/definitions/scenario_test_step.dart';
export 'src/testing/definitions/scenario_test_suite.dart';
export 'src/testing/definitions/screenshot_policy.dart';
export 'src/testing/definitions/step_finder.dart';
export 'src/testing/definitions/test_status.dart';
export 'src/testing/executor/in_app_step_context.dart';
export 'src/testing/executor/scenario_test_executor.dart';
export 'src/testing/executor/test_execution_progress.dart';
export 'src/testing/executor/test_execution_result.dart';
export 'src/testing/harness/scenario_test_harness.dart';
export 'src/testing/harness/scenario_test_matchers.dart';
export 'src/testing/harness/step_finder_extensions.dart';
export 'src/testing/harness/widget_tester_step_context.dart';
export 'src/testing/registry/scenario_test_registry.dart';
export 'src/testing/reporting/html_report_exporter.dart';
export 'src/testing/reporting/json_report_exporter.dart';
export 'src/testing/reporting/scenario_test_report.dart';
export 'src/testing/runner/execution_mode.dart';
export 'src/testing/runner/scenario_test_runner.dart';
export 'src/testing/runner/screen_execution_summary.dart';
export 'src/testing/screenshot/scenario_repaint_boundary.dart';
export 'src/testing/screenshot/scenario_screenshot_service.dart';
export 'src/testing/steps/interaction_steps.dart';
export 'src/testing/steps/scenario_step_context.dart';
export 'src/testing/steps/step_execution_result.dart';
export 'src/utils/scenario_extensions.dart';
export 'src/utils/scenario_logger.dart';
