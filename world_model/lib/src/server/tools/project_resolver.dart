import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves a project's centralized storage path from its root directory.
///
/// Reads the `.thicket/project.json` identity file to determine the project ID, then constructs the path to the storage
/// directory at `~/.thicket/projects/<projectId>/`.
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

  /// Resolves the storage path for the given project directory.
  ///
  /// Throws [StateError] if the project has not been initialized (no `.thicket/project.json` found).
  ///
  /// Throws [StateError] if the home environment variables are not set for centralized storage mode.
  static String resolveStoragePath(String projectPath) {
    final File identityFile = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!identityFile.existsSync()) {
      throw StateError(
        'Project has not been initialized with Thicket. Run initialize_project first. No .thicket/project.json found '
        'at: $projectPath',
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
