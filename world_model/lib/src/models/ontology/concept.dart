library;

import '../core/world_model_entity.dart';

part 'concept_status.dart';

/// A named abstraction used to organize project knowledge in the world model.
///
/// Concepts are the nodes in the project ontology. They represent the important abstractions the agent uses to
/// understand and reason about a software system, things like Component, Pattern, Constraint, or project-specific ideas
/// like Screen, Repository, or Driver.
///
/// The ontology is flexible: the agent can introduce new concepts as it learns what matters for a particular project.
/// However, changes are tracked and require rationale to discourage unnecessary churn.
class Concept extends WorldModelEntity {
  /// Creates a new [Concept] with the given unique identifier, timestamps, name, description, and status.
  const Concept({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.description,
    required this.status,
  });

  /// Reconstructs a [Concept] from a JSON map.
  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      status: ConceptStatus.values.byName(json['status'] as String),
    );
  }

  /// The name of this concept.
  ///
  /// Should be a concise noun or noun phrase (e.g. "Component", "NavigationFlow", "TimingConstraint").
  final String name;

  /// A description of what this concept represents and when it should be applied.
  final String description;

  /// The current lifecycle status of this concept.
  final ConceptStatus status;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'name': name,
    'description': description,
    'status': status.name,
  };
}
