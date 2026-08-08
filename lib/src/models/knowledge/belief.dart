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

  const Belief({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.claim,
    required this.rationale,
    required this.confidence,
    required this.status,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'claim': claim,
    'rationale': rationale,
    'confidence': confidence,
    'status': status.name,
  };

  /// Reconstructs a [Belief] from a JSON map.
  factory Belief.fromJson(Map<String, dynamic> json) {
    return Belief(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      claim: json['claim'] as String,
      rationale: json['rationale'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      status: BeliefStatus.values.byName(json['status'] as String),
    );
  }
}
