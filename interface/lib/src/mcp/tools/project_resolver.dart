import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';

/// Resolves project configuration and storage paths from the `.thicket/project.json` identity file.
///
/// This logic is shared by all MCP tools that need to read from or write to a project's world model.
class ProjectResolver {
  /// Safely resolves the user's home directory across different operating systems.
  static String getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'] ??
          '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Resolves the project identity, preferring environment variables over local files.
  ///
  /// On cloud deployments, the identity is constructed from environment variables (`THICKET_PROJECT_ID`,
  /// `GCP_PROJECT_ID`, etc.) without reading the filesystem. For local development, falls back to reading
  /// `.thicket/project.json` at [projectPath].
  ///
  /// Throws [StateError] if neither environment variables nor a local identity file can provide the identity.
  static ProjectIdentity readIdentity(String projectPath) {
    // Try environment variables first (works on cloud without any local files).
    final ProjectIdentity? envIdentity = IdentityResolver.fromEnvironment(
      Platform.environment,
    );
    if (envIdentity != null) {
      return envIdentity;
    }

    // Fall back to reading the local identity file.
    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project identity could not be resolved. Set THICKET_PROJECT_ID and GCP_PROJECT_ID environment variables, '
        'or ensure .thicket/project.json exists at: $projectPath',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
    return ProjectIdentity.fromJson(json);
  }

  /// Resolves the local storage path for projects using filesystem-backed storage.
  ///
  /// Returns null for cloud mode since cloud storage does not use a local directory.
  ///
  /// Throws [StateError] if the home environment variable is not set for centralized mode.
  static String? resolveLocalStoragePath(
    ProjectIdentity identity,
    String projectPath,
  ) {
    if (identity.storageMode == StorageMode.cloud) {
      return null;
    }

    if (identity.storageMode == StorageMode.inRepo) {
      return p.join(projectPath, '.thicket', 'world_model');
    }

    final String home = getHomeDirectory();
    if (home.isEmpty) {
      throw StateError('Home directory environment variable is not set');
    }

    return p.join(home, '.thicket', 'projects', identity.projectId);
  }

  /// Creates a [FirestoreEntityStore] for projects using cloud storage.
  ///
  /// Reads the GCP project ID from the identity file and credentials from environment variables.
  ///
  /// Throws [StateError] if the required GCP project ID is missing.
  static FirestoreEntityStore createFirestoreStore(ProjectIdentity identity) {
    final String? gcpProjectId =
        identity.gcpProjectId ?? Platform.environment['GCP_PROJECT_ID'];

    if (gcpProjectId == null || gcpProjectId.isEmpty) {
      throw StateError(
        'Cloud storage mode requires a GCP project ID. Set gcpProjectId in .thicket/project.json or the '
        'GCP_PROJECT_ID environment variable.',
      );
    }

    final String? accessToken = Platform.environment['GOOGLE_ACCESS_TOKEN'];
    final String? apiKey = Platform.environment['FIREBASE_API_KEY'];

    return FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: identity.projectId,
      accessToken: accessToken,
      apiKey: apiKey,
    );
  }
}
