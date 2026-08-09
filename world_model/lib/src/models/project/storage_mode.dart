/// The storage topology used for a Thicket project's world model.
///
/// Determines where entity data is persisted and how the agent and dashboard resolve storage backends.
enum StorageMode {
  /// Entities are stored in Google Cloud Firestore, accessible from any machine.
  ///
  /// Requires a valid `ProjectIdentity.gcpProjectId` and appropriate credentials (access token or API key).
  cloud,

  /// Entities are stored locally at `~/.thicket/projects/<projectId>/`.
  ///
  /// Only accessible from the machine where the data resides.
  centralized,

  /// Entities are stored inside the repository at `.thicket/world_model/`.
  ///
  /// Keeps the world model co-located with the source code, useful for version-controlled experiments.
  inRepo;

  /// Parses a storage mode from its JSON string representation.
  ///
  /// Defaults to [StorageMode.cloud] if the value is null or unrecognized.
  static StorageMode fromString(String? value) {
    switch (value) {
      case 'cloud':
        return StorageMode.cloud;
      case 'centralized':
        return StorageMode.centralized;
      case 'inRepo':
        return StorageMode.inRepo;
      default:
        return StorageMode.cloud;
    }
  }

  /// Returns the JSON-serializable string representation of this mode.
  String toJson() => name;
}
