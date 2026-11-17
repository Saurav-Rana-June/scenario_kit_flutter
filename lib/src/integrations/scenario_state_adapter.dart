import 'package:flutter/foundation.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../utils/scenario_extensions.dart';

/// Function that maps an active [Scenario] into a framework-specific state object [T].
typedef ScenarioStateMapper<T> = T? Function(Scenario? scenario);

/// Adapts [ScenarioController] changes into a reactive [ValueListenable] state stream.
///
/// This provides a universal, dependency-free bridge between ScenarioKit and any
/// state-management library (such as Bloc/Cubit, Riverpod, Provider, GetX, or ValueNotifier).
///
/// Example with Cubit / Bloc:
/// ```dart
/// final adapter = ScenarioStateAdapter<ProductState>(
///   controller: scenarioController,
///   stateMapper: (scenario) => scenario?.getMock<ProductState>(),
/// );
/// adapter.addListener(() {
///   if (adapter.value != null) myCubit.emit(adapter.value!);
/// });
/// ```
class ScenarioStateAdapter<T> extends ValueNotifier<T?> {
  /// Creates a [ScenarioStateAdapter].
  ///
  /// If [stateMapper] is omitted, attempts to extract mock data of type [T]
  /// via [ScenarioMockExtensions.getMock].
  ScenarioStateAdapter({
    required ScenarioController controller,
    ScenarioStateMapper<T>? stateMapper,
  })  : _controller = controller,
        _stateMapper = stateMapper ?? _defaultMapper<T>,
        super(null) {
    _controller.addListener(_handleScenarioChanged);
    _handleScenarioChanged();
  }

  final ScenarioController _controller;
  final ScenarioStateMapper<T> _stateMapper;
  bool _isDisposed = false;

  static T? _defaultMapper<T>(Scenario? scenario) {
    if (scenario == null) return null;
    return scenario.getMock<T>();
  }

  void _handleScenarioChanged() {
    if (_isDisposed) return;
    final newState = _stateMapper(_controller.selectedScenario);
    if (value != newState) {
      value = newState;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller.removeListener(_handleScenarioChanged);
    super.dispose();
  }
}
