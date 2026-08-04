library;

import '../core/world_model_entity.dart';

part 'belief_status.dart';

/// Represents the agent's current understanding of some aspect of the software system.
///
/// Beliefs may describe which component owns a particular responsibility, which architectural patterns are normally
/// used, which subsystems have important dependencies, which implementation approaches should be avoided, or which
/// areas of the codebase are particularly fragile.
///
/// A belief can be associated with supporting evidence, confidence, timestamps, and relationships to other beliefs or
/// experiences. Because the software system itself continues to evolve, beliefs are not assumed to be permanently
/// correct. New evidence may strengthen a belief, reduce confidence in it, or cause it to be revised or superseded
/// entirely.
class Belief extends WorldModelEntity {
  /// A concise statement of what the agent believes to be true.
  final String claim;

  /// A longer explanation providing context, reasoning, or justification for the belief.
  final String rationale;

  /// The agent's confidence in this belief, from 0.0 (no confidence) to 1.0 (fully confident).
  ///
  /// Confidence may increase as supporting evidence accumulates or decrease when contradictory evidence is encountered.
  final double confidence;

  /// The current lifecycle status of this belief.
  final BeliefStatus status;

  /// Identifiers of episodes that provide evidence for this belief.
  ///
  /// Links the belief back to the concrete experiences from which it was derived, maintaining provenance.
  final List<String> supportingEpisodeIds;

  /// Identifiers of other beliefs that this belief supersedes.
  ///
  /// When the agent revises its understanding, the old belief is marked as [BeliefStatus.superseded] and the new belief
  /// references it here for traceability.
  final List<String> supersededBeliefIds;

  /// File paths or identifiers relevant to this belief.
  ///
  /// Anchors the belief to specific areas of the codebase for retrieval when the agent is working in those areas.
  final List<String> relatedPaths;

  /// Free-form tags for additional categorization and retrieval.
  final List<String> tags;

  const Belief({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.revision,
    required this.claim,
    required this.rationale,
    required this.confidence,
    required this.status,
    this.supportingEpisodeIds = const [],
    this.supersededBeliefIds = const [],
    this.relatedPaths = const [],
    this.tags = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'claim': claim,
    'rationale': rationale,
    'confidence': confidence,
    'status': status.name,
    'supportingEpisodeIds': supportingEpisodeIds,
    'supersededBeliefIds': supersededBeliefIds,
    'relatedPaths': relatedPaths,
    'tags': tags,
  };

  /// Reconstructs a [Belief] from a JSON map.
  factory Belief.fromJson(Map<String, dynamic> json) {
    return Belief(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      revision: json['revision'] as int,
      claim: json['claim'] as String,
      rationale: json['rationale'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      status: BeliefStatus.values.byName(json['status'] as String),
      supportingEpisodeIds: (json['supportingEpisodeIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      supersededBeliefIds: (json['supersededBeliefIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      relatedPaths: (json['relatedPaths'] as List<dynamic>?)?.cast<String>() ?? const [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
