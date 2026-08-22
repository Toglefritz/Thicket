import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'thicket_api_service.dart';

/// Handles file-system operations for the Thicket setup wizard.
///
/// This service encapsulates all `dart:io` file and directory operations needed during project registration and
/// configuration. On web, the noop variant is imported instead via conditional imports in the controller.
class FileWriterService {
  const FileWriterService._();

  /// Returns whether the given directory path exists on the local file system.
  static bool directoryExists(String path) {
    return Directory(path).existsSync();
  }

  /// Reads an existing `.thicket/project.json` from the given project directory.
  ///
  /// Returns the parsed JSON map if the file exists and is valid, or null otherwise.
  static Map<String, dynamic>? readExistingConfig(String projectPath) {
    final File existingConfig = File(
      p.join(projectPath, '.thicket', 'project.json'),
    );

    if (!existingConfig.existsSync()) return null;

    try {
      final String content = existingConfig.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Writes `.thicket/project.json` and `.thicket/credentials.json` in the specified project directory.
  ///
  /// The project config contains non-sensitive metadata (project ID, name, agent URL) and is safe to commit. The
  /// credentials file contains the API token and is automatically added to `.gitignore`.
  static void writeProjectConfig({
    required RegistrationResult result,
    required String projectName,
    required String projectPath,
  }) {
    final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));

    if (!thicketDir.existsSync()) {
      thicketDir.createSync(recursive: true);
    }

    // Write the non-sensitive project configuration.
    final Map<String, dynamic> projectConfig = <String, dynamic>{
      'projectId': result.projectId,
      'projectName': projectName,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'storageMode': 'cloud',
      'agentUrl': result.agentUrl,
      'gcpProjectId': result.gcpProjectId ?? 'thicket-505111',
    };

    final File projectFile = File(p.join(thicketDir.path, 'project.json'));
    projectFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(projectConfig),
    );

    // Write credentials and update .gitignore.
    writeCredentials(apiToken: result.apiToken, projectPath: projectPath);
  }

  /// Writes `.thicket/credentials.json` with the given API token and ensures it is gitignored.
  static void writeCredentials({
    required String apiToken,
    required String projectPath,
  }) {
    final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));

    if (!thicketDir.existsSync()) {
      thicketDir.createSync(recursive: true);
    }

    final Map<String, dynamic> credentials = <String, dynamic>{
      'apiToken': apiToken,
    };

    final File credentialsFile = File(p.join(thicketDir.path, 'credentials.json'));
    credentialsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(credentials),
    );

    _ensureGitignore(projectPath);
  }

  /// Appends `.thicket/credentials.json` to the project's `.gitignore` if not already present.
  static void _ensureGitignore(String projectPath) {
    const String entry = '.thicket/credentials.json';
    final File gitignore = File(p.join(projectPath, '.gitignore'));

    if (gitignore.existsSync()) {
      final String content = gitignore.readAsStringSync();
      if (content.contains(entry)) {
        return;
      }
      // Append with a preceding newline if the file doesn't end with one.
      final String prefix = content.endsWith('\n') ? '' : '\n';
      gitignore.writeAsStringSync('$prefix$entry\n', mode: FileMode.append);
    } else {
      gitignore.writeAsStringSync('$entry\n');
    }
  }
}
