import 'storage_mode.dart';

/// Represents the identity link between a coding project and its persistent world model.
///
/// This corresponds to the `.thicket/project.json` file placed in a project's root directory. It contains a stable
/// identifier that points to the world model, whether stored locally or in Google Cloud Firestore.
///
/// The identifier remains the same even if the project is moved or renamed, allowing the world model to survive
/// directory relocations.
class ProjectIdentity {
  /// Creates a new [ProjectIdentity] linked to a target project and its world model storage configuration.
  const ProjectIdentity({
    required this.projectId,
    required this.projectName,
    required this.createdAt,
    this.storageMode = StorageMode.cloud,
    this.gcpProjectId,
  });

  /// Deserializes a project identity from the contents of a `.thicket/project.json` file.
  factory ProjectIdentity.fromJson(Map<String, dynamic> json) {
    return ProjectIdentity(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      storageMode: StorageMode.fromString(json['storageMode'] as String?),
      gcpProjectId: json['gcpProjectId'] as String?,
    );
  }

  /// A stable unique identifier for this project's world model.
  ///
  /// Generated once when Thicket is first initialized for a project. In cloud mode, this is used as the scoping key
  /// within Firestore (e.g. `thicket_projects/{projectId}/`). In local modes, it determines the directory name under
  /// `~/.thicket/projects/`.
  final String projectId;

  /// A human-readable name for the project.
  ///
  /// Informational only; not used for lookup. Can be updated freely without affecting the world model linkage.
  final String projectName;

  /// When this project identity was first created.
  final DateTime createdAt;

  /// The storage topology used for this project's world model.
  final StorageMode storageMode;

  /// The Google Cloud project ID that owns the Firestore database.
  ///
  /// Required when [storageMode] is [StorageMode.cloud]. This identifies which GCP project's Firestore instance holds
  /// the world model data. Ignored for local storage modes.
  final String? gcpProjectId;

  /// Serializes this identity to JSON for writing to `.thicket/project.json`.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'projectId': projectId,
      'projectName': projectName,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'storageMode': storageMode.toJson(),
    };

    if (gcpProjectId != null) {
      json['gcpProjectId'] = gcpProjectId;
    }

    return json;
  }
}
