library;

import '../core/world_model_entity.dart';

part 'concept_origin.dart';
part 'concept_status.dart';

/// A named abstraction used to organize project knowledge in the world model.
///
/// Concepts are the nodes in the project ontology. They represent the important abstractions the agent uses to
/// understand and reason about a software system, things like Component, Pattern, Constraint, or project-specific
/// ideas like Screen, Repository, or Driver.
///
/// The ontology is flexible: the agent can introduce new concepts as it learns what matters for a particular project.
/// However, changes are tracked and require rationale to discourage unnecessary churn.
class Concept extends WorldModelEntity {
  /// The name of this concept.
  ///
  /// Should be a concise noun or noun phrase (e.g. "Component", "NavigationFlow", "TimingConstraint").
  final String name;

  /// A description of what this concept represents and when it should be applied.
  final String description;

  /// Where this concept originated, which determines the level of friction required to modify it.
  final ConceptOrigin origin;

  /// The current lifecycle status of this concept.
  final ConceptStatus status;

  /// The reason this concept was introduced, modified, or moved to its current status.
  ///
  /// Required for all agent-initiated changes. Provides traceability for why the ontology evolved in a particular
  /// direction.
  final String rationale;

  /// Identifiers of concepts that this concept supersedes.
  ///
  /// When the agent refines the ontology by replacing or merging concepts, the old concepts are deprecated and
  /// referenced here.
  final List<String> supersededConceptIds;

  const Concept({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.revision,
    required this.name,
    required this.description,
    required this.origin,
    required this.status,
    required this.rationale,
    this.supersededConceptIds = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'name': name,
    'description': description,
    'origin': origin.name,
    'status': status.name,
    'rationale': rationale,
    'supersededConceptIds': supersededConceptIds,
  };

  /// Reconstructs a [Concept] from a JSON map.
  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      revision: json['revision'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      origin: ConceptOrigin.values.byName(json['origin'] as String),
      status: ConceptStatus.values.byName(json['status'] as String),
      rationale: json['rationale'] as String,
      supersededConceptIds: (json['supersededConceptIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
