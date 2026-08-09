import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';

/// Resolves project configuration and constructs the appropriate entity store for the dashboard.
///
/// On desktop, reads the `.thicket/project.json` identity file to determine the storage mode. For cloud mode, returns
/// a [FirestoreEntityStore]. For local modes, returns the legacy filesystem path.
///
/// On web, the dashboard always uses [FirestoreEntityStore] with configuration provided at build time or via
/// environment constants.
class ProjectResolver {
  /// The GCP project ID used for Firestore access.
  ///
  /// Set via the `GCP_PROJECT_ID` compile-time constant (passed with `--dart-define`) or detected from the project
  /// identity file on desktop.
  static const String _defaultGcpProjectId = String.fromEnvironment(
    'GCP_PROJECT_ID',
  );

  /// The Thicket project ID used to scope Firestore documents.
  ///
  /// Set via the `THICKET_PROJECT_ID` compile-time constant or detected from the project identity file on desktop.
  static const String _defaultThicketProjectId = String.fromEnvironment(
    'THICKET_PROJECT_ID',
  );

  /// Firebase API key for authenticating Firestore REST requests from the dashboard.
  ///
  /// Set via the `FIREBASE_API_KEY` compile-time constant.
  static const String _defaultFirebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );

  /// Safely resolves the user's home directory across different operating systems.
  ///
  /// Returns an empty string if running on the web or if the home directory cannot be resolved.
  static String getHomeDirectory() {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'] ??
          '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Resolves the project identity, preferring compile-time constants and environment variables over local files.
  ///
  /// On web, constructs identity from the `--dart-define` constants. On desktop, first tries the compile-time
  /// constants, then falls back to reading the local `.thicket/project.json` file.
  ///
  /// Returns null if identity cannot be resolved from any source.
  static ProjectIdentity? readIdentity(String projectPath) {
    // Try compile-time constants first (works on both web and desktop).
    if (_defaultThicketProjectId.isNotEmpty &&
        _defaultGcpProjectId.isNotEmpty) {
      return ProjectIdentity(
        projectId: _defaultThicketProjectId,
        projectName: _defaultThicketProjectId,
        createdAt: DateTime.utc(1970),
        storageMode: StorageMode.cloud,
        gcpProjectId: _defaultGcpProjectId,
      );
    }

    if (kIsWeb) {
      return null;
    }

    // On desktop, try platform environment variables via IdentityResolver.
    final ProjectIdentity? envIdentity = IdentityResolver.fromEnvironment(
      Platform.environment,
    );
    if (envIdentity != null) {
      return envIdentity;
    }

    // Final fallback: read the local identity file.
    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      return null;
    }

    final Map<String, dynamic> json =
        jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
    return ProjectIdentity.fromJson(json);
  }

  /// Creates a [FirestoreEntityStore] using the project identity or compile-time constants.
  ///
  /// On desktop, reads configuration from the project identity file. On web, uses the compile-time constants passed
  /// via `--dart-define`.
  ///
  /// Returns null if the required GCP project ID or Thicket project ID cannot be determined.
  static FirestoreEntityStore? createFirestoreStore({
    ProjectIdentity? identity,
  }) {
    final String gcpProjectId = identity?.gcpProjectId ?? _defaultGcpProjectId;
    final String thicketProjectId =
        identity?.projectId ?? _defaultThicketProjectId;

    if (gcpProjectId.isEmpty || thicketProjectId.isEmpty) {
      return null;
    }

    const String apiKey = _defaultFirebaseApiKey;

    return FirestoreEntityStore(
      gcpProjectId: gcpProjectId,
      thicketProjectId: thicketProjectId,
      apiKey: apiKey.isNotEmpty ? apiKey : null,
    );
  }

  /// Resolves the local storage path for projects using filesystem-backed storage.
  ///
  /// Only meaningful on desktop with 'centralized' or 'inRepo' storage modes.
  static String? resolveLocalStoragePath(
    ProjectIdentity identity,
    String projectPath,
  ) {
    if (kIsWeb) {
      return null;
    }

    if (identity.storageMode == StorageMode.inRepo) {
      return p.join(projectPath, '.thicket', 'world_model');
    }

    final String home = getHomeDirectory();
    if (home.isEmpty) {
      return null;
    }

    return p.join(home, '.thicket', 'projects', identity.projectId);
  }
}
