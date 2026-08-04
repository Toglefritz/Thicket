part of 'belief.dart';

/// The lifecycle status of a belief.
///
/// Beliefs are not assumed to be permanently correct. As the software system evolves and new evidence is encountered, a
/// belief may transition through these states.
enum BeliefStatus {
  /// The belief is considered current and reliable.
  active,

  /// The belief's accuracy is uncertain due to conflicting or insufficient evidence.
  uncertain,

  /// The belief has been replaced by a newer, more accurate belief.
  superseded,

  /// The belief has been explicitly determined to be incorrect.
  refuted,
}
