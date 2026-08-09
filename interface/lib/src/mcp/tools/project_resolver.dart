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

  /// Reads and parses the project identity file from the given project path.
  ///
  /// Throws [StateError] if the project has not been initialized (no `.thicket/project.json` found).
  static ProjectIdentity readIdentity(String projectPath) {
    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project has not been initialized with Thicket. Run initialize_project first. No .thicket/project.json found '
        'at: $projectPath',
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
