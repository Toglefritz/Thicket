part of 'episode.dart';

/// The type of experience an episode records.
///
/// Each variant represents a different category of significant experience that an agent may encounter during
/// development work.
enum EpisodeKind {
  /// A development task that was performed.
  taskPerformed,

  /// An architectural constraint that was discovered.
  constraintDiscovered,

  /// An approach that was attempted and failed.
  approachFailed,

  /// The reason an implementation was rejected.
  implementationRejected,

  /// An unexpected interaction between subsystems.
  unexpectedInteraction,

  /// The outcome of a debugging investigation.
  debuggingOutcome,

  /// A general observation that does not fit other categories.
  observation,
}
