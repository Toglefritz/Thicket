import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';

/// Resolves project configuration and constructs the appropriate entity store.
///
/// First attempts to resolve identity from environment variables (for cloud deployments where no filesystem config is
/// available). Falls back to reading `.thicket/project.json` from the provided project path for local development.
class StoreResolver {
  /// Safely resolves the user's home directory across different operating systems.
  static String getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Platform.environment['APPDATA'] ?? '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Resolves the project identity, preferring environment variables over local files.
  static ProjectIdentity readIdentity(String projectPath) {
    final ProjectIdentity? envIdentity = IdentityResolver.fromEnvironment(Platform.environment);
    if (envIdentity != null) {
      return envIdentity;
    }

    final File identityFile = File(p.join(projectPath, '.thicket', 'project.json'));

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project identity could not be resolved. Set THICKET_PROJECT_ID and GCP_PROJECT_ID environment variables, '
        'or ensure .thicket/project.json exists at: $projectPath',
      );
    }

    final Map<String, dynamic> json = jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
    return ProjectIdentity.fromJson(json);
  }

  /// Creates a [FirestoreEntityStore] for projects using cloud storage.
  static Future<FirestoreEntityStore> createFirestoreStore(ProjectIdentity identity) async {
    final String? gcpProjectId = identity.gcpProjectId ?? Platform.environment['GCP_PROJECT_ID'];

    if (gcpProjectId == null || gcpProjectId.isEmpty) {
      throw StateError(
        'Cloud storage mode requires a GCP project ID. Set gcpProjectId in .thicket/project.json or the '
        'GCP_PROJECT_ID environment variable.',
      );
    }

    String? accessToken = Platform.environment['GOOGLE_ACCESS_TOKEN'];
    final String? apiKey = Platform.environment['FIREBASE_API_KEY'];

    if (accessToken == null && apiKey == null) {
      accessToken = await fetchMetadataAccessToken();
    }

    return FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: identity.projectId,
      accessToken: accessToken,
      apiKey: apiKey,
      databaseId: Platform.environment['FIRESTORE_DATABASE_ID'] ?? 'thicket-world-model',
    );
  }

  /// Creates a local [EntityStore] for projects using centralized or in-repo storage.
  static EntityStore createLocalStore(ProjectIdentity identity, String projectPath) {
    if (identity.storageMode == StorageMode.inRepo) {
      return EntityStore(storagePath: p.join(projectPath, '.thicket', 'world_model'));
    }

    final String home = getHomeDirectory();
    if (home.isEmpty) {
      throw StateError('Home directory environment variable is not set');
    }

    return EntityStore(storagePath: p.join(home, '.thicket', 'projects', identity.projectId));
  }

  /// Fetches an access token from the GCE instance metadata server.
  ///
  /// Available on Cloud Run, Compute Engine, and other GCP managed compute. Returns null if the metadata server is not
  /// reachable (e.g. running locally).
  static Future<String?> fetchMetadataAccessToken() async {
    try {
      final http.Response response = await http.get(
        Uri.parse(
          'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
        ),
        headers: <String, String>{'Metadata-Flavor': 'Google'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['access_token'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
