import '../models/project/project_identity.dart';
import '../models/project/storage_mode.dart';

/// Resolves project identity from environment variables for cloud deployments.
///
/// When the Thicket agent runs on Cloud Run or other cloud infrastructure, no local `.thicket/project.json` file is
/// available. This resolver constructs a [ProjectIdentity] from environment variables instead, allowing the agent to
/// operate without any filesystem-based configuration.
///
/// Environment variables used:
/// - `THICKET_PROJECT_ID` (required): The Thicket project identifier used to scope Firestore documents.
/// - `GCP_PROJECT_ID` (required): The Google Cloud project that owns the Firestore database.
/// - `THICKET_PROJECT_NAME` (optional): A human-readable name for the project. Defaults to the project ID.
/// - `THICKET_STORAGE_MODE` (optional): The storage mode. Defaults to "cloud".
class IdentityResolver {
  /// Attempts to construct a [ProjectIdentity] from the provided environment map.
  ///
  /// Returns null if the required environment variables (`THICKET_PROJECT_ID` and `GCP_PROJECT_ID`) are not set. This
  /// signals to callers that they should fall back to reading a local file.
  static ProjectIdentity? fromEnvironment(Map<String, String> environment) {
    final String? thicketProjectId = environment['THICKET_PROJECT_ID'];
    final String? gcpProjectId = environment['GCP_PROJECT_ID'];

    if (thicketProjectId == null || thicketProjectId.isEmpty) {
      return null;
    }

    if (gcpProjectId == null || gcpProjectId.isEmpty) {
      return null;
    }

    final String projectName = environment['THICKET_PROJECT_NAME'] ?? thicketProjectId;
    final StorageMode storageMode = StorageMode.fromString(
      environment['THICKET_STORAGE_MODE'] ?? 'cloud',
    );

    return ProjectIdentity(
      projectId: thicketProjectId,
      projectName: projectName,
      createdAt: DateTime.utc(1970),
      storageMode: storageMode,
      gcpProjectId: gcpProjectId,
    );
  }
}
