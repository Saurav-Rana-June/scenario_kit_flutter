import 'package:flutter/foundation.dart';

/// Generic container for mock datasets used in scenarios.
///
/// Keeps mock data flexible, strongly typed, and decoupled from any specific model structure.
@immutable
class MockData<T> {
  /// Creates a static [MockData] instance with [value].
  const MockData.value(
    T value, {
    this.label,
    this.description,
  })  : _value = value,
        _generator = null;

  /// Creates a dynamic [MockData] instance whose value is produced by [generator].
  const MockData.generator(
    T Function() generator, {
    this.label,
    this.description,
  })  : _generator = generator,
        _value = null;

  final T? _value;
  final T Function()? _generator;

  /// Optional human-readable label identifying this dataset (e.g. "Empty", "50 items").
  final String? label;

  /// Optional description providing context about the dataset (e.g. "Simulates corrupted schema").
  final String? description;

  /// Returns the resolved mock data.
  T get value {
    final generator = _generator;
    if (generator != null) {
      return generator();
    }
    return _value as T;
  }

  /// Simulates an asynchronous fetch returning [value] after [delay].
  Future<T> getAsync(
      {Duration delay = const Duration(milliseconds: 300)}) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MockData<T> &&
        other.label == label &&
        other.description == description &&
        other._value == _value;
  }

  @override
  int get hashCode => Object.hash(label, description, _value);

  @override
  String toString() => 'MockData<$T>(label: $label, value: $_value)';
}
