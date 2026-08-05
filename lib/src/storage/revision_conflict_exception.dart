/// Thrown when a save operation fails because the entity's revision number does not match what is currently on disk.
///
/// This indicates a concurrent modification: something else updated the entity between when it was read and when the
/// save was attempted. The caller should re-read the entity, reconcile the changes, and retry.
class RevisionConflictException implements Exception {
  /// The entity ID that experienced the conflict.
  final String entityId;

  /// The revision number found on disk.
  final int currentRevision;

  /// The revision number the caller expected to find.
  final int expectedRevision;

  const RevisionConflictException({
    required this.entityId,
    required this.currentRevision,
    required this.expectedRevision,
  });

  @override
  String toString() =>
      'RevisionConflictException: entity "$entityId" is at revision $currentRevision but expected $expectedRevision';
}
