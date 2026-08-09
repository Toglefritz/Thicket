import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Resolves a project's centralized storage path from its root directory.
///
/// This class handles checking the project identity file (`.thicket/project.json`) and constructs the appropriate
/// storage path depending on whether the project uses centralized or in-repo storage.
class ProjectResolver {
  /// Safely resolves the user's home directory across different operating systems.
  ///
  /// Returns an empty string if running on the web or if the home directory cannot be resolved.
  static String getHomeDirectory() {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Platform.environment['APPDATA'] ?? '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Resolves the storage path for the given project directory.
  ///
  /// Throws [StateError] if the project identity file is missing or if the home environment variable is not set.
  static String resolveStoragePath(String projectPath) {
    if (kIsWeb) {
      return '';
    }

    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project has not been initialized with Thicket. No .thicket/project.json found at: $projectPath',
      );
    }

    final Map<String, dynamic> identity = jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
    final String projectId = identity['projectId'] as String;
    final String storageMode = identity['storageMode'] as String? ?? 'centralized';

    if (storageMode == 'inRepo') {
      return p.join(projectPath, '.thicket', 'world_model');
    }

    final String home = getHomeDirectory();
    if (home.isEmpty) {
      throw StateError('Home directory environment variable is not set');
    }

    return p.join(home, '.thicket', 'projects', projectId);
  }
}
