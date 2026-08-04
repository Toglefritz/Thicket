part of 'relationship.dart';

/// The lifecycle status of a relationship in the project ontology.
///
/// Mirrors [ConceptStatus] semantics but applies to edges rather than nodes in the ontology graph.
enum RelationshipStatus {
  /// The relationship has been introduced but not yet referenced by any belief.
  proposed,

  /// The relationship is in active use within the world model.
  active,

  /// The relationship has been marked as no longer preferred but is retained for historical reference.
  deprecated,

  /// The relationship is fully retired and should not be used in new beliefs.
  retired,
}
