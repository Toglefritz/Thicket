library;

import '../core/world_model_entity.dart';
import 'concept.dart';

part 'relationship_status.dart';

/// A typed, directed edge between two concepts in the project ontology.
///
/// Relationships give the ontology its graph structure. They describe how concepts relate to each other, for example,
/// "Screen uses StateManager", "Driver controls HardwarePeripheral", or "Feature implemented_by Screen".
///
/// Like concepts, relationships carry origin and status metadata to support the same tiered stability model. The agent
/// can define new relationship types as it discovers meaningful connections between concepts in a project.
class Relationship extends WorldModelEntity {
  /// The name of this relationship type.
  ///
  /// Should be a concise verb or verb phrase describing the directed connection (e.g. "uses", "depends_on",
  /// "implements", "controls", "owns").
  final String name;

  /// A description of what this relationship means and when it should be applied.
  final String description;

  /// The identifier of the source concept (the "from" end of the directed edge).
  final String fromConceptId;

  /// The identifier of the target concept (the "to" end of the directed edge).
  final String toConceptId;

  /// Where this relationship originated, which determines the level of friction required to modify it.
  final ConceptOrigin origin;

  /// The current lifecycle status of this relationship.
  final RelationshipStatus status;

  /// The reason this relationship was introduced, modified, or moved to its current status.
  ///
  /// Required for all agent-initiated changes.
  final String rationale;

  const Relationship({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.revision,
    required this.name,
    required this.description,
    required this.fromConceptId,
    required this.toConceptId,
    required this.origin,
    required this.status,
    required this.rationale,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'name': name,
    'description': description,
    'fromConceptId': fromConceptId,
    'toConceptId': toConceptId,
    'origin': origin.name,
    'status': status.name,
    'rationale': rationale,
  };

  /// Reconstructs a [Relationship] from a JSON map.
  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      revision: json['revision'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      fromConceptId: json['fromConceptId'] as String,
      toConceptId: json['toConceptId'] as String,
      origin: ConceptOrigin.values.byName(json['origin'] as String),
      status: RelationshipStatus.values.byName(json['status'] as String),
      rationale: json['rationale'] as String,
    );
  }
}
