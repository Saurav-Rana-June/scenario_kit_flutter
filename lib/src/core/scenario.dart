import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'scenario_exceptions.dart';

/// Function signature for building a scenario widget tree.
typedef ScenarioBuilder = Widget Function(BuildContext context);

/// Represents an individual UI scenario for a screen or component.
///
/// A scenario encapsulates a specific UI state (e.g., Loading, Error, Empty,
/// Success) along with its builder function and optional metadata.
@immutable
class Scenario {
  /// Creates a [Scenario].
  ///
  /// If [id] is omitted, it will be automatically derived from [name].
  /// Throws [InvalidScenarioException] if [name] is empty or whitespace.
  Scenario({
    required this.name,
    required this.builder,
    String? id,
    this.description,
    this.group,
    this.isDefault = false,
    Iterable<String>? tags,
    Map<String, dynamic>? metadata,
  })  : id = _sanitizeId(id, name),
        tags = List<String>.unmodifiable(tags ?? const <String>[]),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (name.trim().isEmpty) {
      throw const InvalidScenarioException('Scenario name cannot be empty.');
    }
  }

  /// Convenience factory for a Loading state scenario.
  factory Scenario.loading({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Loading',
    String? description = 'State when content or data is being fetched',
    String? group,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Convenience factory for a Success state scenario.
  factory Scenario.success({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Success',
    String? description = 'State when data has loaded successfully',
    String? group,
    bool isDefault = true,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Convenience factory for an Empty state scenario.
  factory Scenario.empty({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Empty',
    String? description =
        'State when collection or response contains zero items',
    String? group,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Convenience factory for an Error state scenario.
  factory Scenario.error({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Error',
    String? description = 'State when an operation or network request fails',
    String? group,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Convenience factory for an Offline state scenario.
  factory Scenario.offline({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Offline',
    String? description = 'State when the device has no network connectivity',
    String? group,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Convenience factory for pagination / load-more in progress.
  factory Scenario.paginationLoading({
    required ScenarioBuilder builder,
    String? id,
    String name = 'Pagination Loading',
    String? description = 'Additional page is being fetched',
    String? group,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id,
      name: name,
      builder: builder,
      description: description,
      group: group,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// Unique identifier for this scenario within a registry.
  final String id;

  /// Human-readable title displayed in developer previews and panels.
  final String name;

  /// Optional detailed description explaining the purpose or state represented.
  final String? description;

  /// Optional group or category name used to organize related scenarios.
  final String? group;

  /// Widget builder that produces the UI for this scenario.
  final ScenarioBuilder builder;

  /// Whether this scenario is the default initial scenario for its registry.
  final bool isDefault;

  /// Optional labels for search and organization (e.g. "smoke", "network").
  final List<String> tags;

  /// Arbitrary metadata associated with this scenario (e.g. mock responses, tags).
  final Map<String, dynamic> metadata;

  /// Sanitizes or generates an ID from [id] or [name].
  static String _sanitizeId(String? id, String name) {
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    final sanitized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (sanitized.isEmpty) {
      throw const InvalidScenarioException(
        'Could not generate a valid scenario ID from name. Please specify an explicit id.',
      );
    }
    return sanitized;
  }

  /// Creates a copy of this [Scenario] with specified fields replaced.
  Scenario copyWith({
    String? id,
    String? name,
    String? description,
    String? group,
    ScenarioBuilder? builder,
    bool? isDefault,
    Iterable<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Scenario(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      group: group ?? this.group,
      builder: builder ?? this.builder,
      isDefault: isDefault ?? this.isDefault,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scenario &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.group == group &&
        other.isDefault == isDefault &&
        listEquals(other.tags, tags) &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    var metadataHash = 0;
    for (final entry in metadata.entries) {
      metadataHash ^= Object.hash(entry.key, entry.value);
    }
    return Object.hash(
      id,
      name,
      description,
      group,
      isDefault,
      Object.hashAll(tags),
      metadataHash,
    );
  }

  @override
  String toString() =>
      'Scenario(id: $id, name: $name, group: $group, isDefault: $isDefault)';
}
