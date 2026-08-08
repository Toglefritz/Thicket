part of 'concept.dart';

/// The lifecycle status of a concept in the project ontology.
///
/// Concepts move through these states rather than being hard-deleted, preserving history and allowing beliefs that
/// reference them to remain coherent.
enum ConceptStatus {
  /// The concept has been introduced but not yet used by any belief or relationship.
  ///
  /// Newly agent-created concepts start here and transition to [active] once referenced.
  proposed,

  /// The concept is in active use within the world model.
  active,

  /// The concept has been marked as no longer preferred but is retained for historical reference.
  deprecated,

  /// The concept is fully retired and should not be used in new beliefs or relationships.
  retired,
}
