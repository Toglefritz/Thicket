/// Represents the identity link between a coding project and its persistent world model.
///
/// This corresponds to the `.thicket/project.json` file placed in a project's root directory. It contains a stable
/// identifier that points to the world model stored at a centralized location (e.g.
/// `~/.thicket/projects/<projectId>/`).
///
/// The identifier remains the same even if the project is moved or renamed, allowing the world model to survive
/// directory relocations.
class ProjectIdentity {
  /// A stable unique identifier for this project's world model.
  ///
  /// Generated once when Thicket is first initialized for a project. Used as the directory name under
  /// `~/.thicket/projects/` to locate the world model data.
  final String projectId;

  /// A human-readable name for the project.
  ///
  /// Informational only; not used for lookup. Can be updated freely without affecting the world model linkage.
  final String projectName;

  /// When this project identity was first created.
  final DateTime createdAt;

  const ProjectIdentity({
    required this.projectId,
    required this.projectName,
    required this.createdAt,
  });

  /// Serializes this identity to JSON for writing to `.thicket/project.json`.
  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'projectName': projectName,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// Deserializes a project identity from the contents of a `.thicket/project.json` file.
  factory ProjectIdentity.fromJson(Map<String, dynamic> json) {
    return ProjectIdentity(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
