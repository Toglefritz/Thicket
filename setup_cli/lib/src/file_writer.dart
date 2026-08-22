/// File Writer Service
///
/// Handles writing Thicket configuration files to the user's project directory. Creates the `.thicket/` directory
/// structure, writes `project.json` (non-sensitive project metadata) and `credentials.json` (API token), and ensures
/// the credentials file is added to `.gitignore`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'api.dart' as api;

/// Writes both `.thicket/project.json` and `.thicket/credentials.json` for a newly registered project.
///
/// The [result] map must contain `projectId`, `apiToken`, and optionally `agentUrl` and `gcpProjectId` as returned by
/// the Thicket backend. The [projectName] is stored in the config for display purposes. Files are written to the
/// `.thicket/` subdirectory within [projectPath].
///
/// Also updates `.gitignore` to exclude the credentials file from version control.
void writeProjectConfig(
  Map<String, dynamic> result,
  String projectName,
  String projectPath,
) {
  final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));
  if (!thicketDir.existsSync()) {
    thicketDir.createSync(recursive: true);
  }

  final Map<String, dynamic> projectConfig = <String, dynamic>{
    'projectId': result['projectId'],
    'projectName': projectName,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'storageMode': 'cloud',
    'agentUrl': result['agentUrl'] ?? api.defaultBaseUrl,
    'gcpProjectId': result['gcpProjectId'] ?? 'thicket-505111',
  };

  final File projectFile = File(p.join(thicketDir.path, 'project.json'));
  projectFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(projectConfig),
  );

  writeCredentials(result['apiToken'] as String, projectPath);
}

/// Writes `.thicket/credentials.json` containing the API token.
///
/// Creates the `.thicket/` directory if it does not already exist. The credentials file is a simple JSON object with a
/// single `apiToken` field. After writing, ensures the file is gitignored.
///
/// This method is called separately during the join flow where `project.json` already exists and only the credentials
/// need to be written.
void writeCredentials(String apiToken, String projectPath) {
  final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));
  if (!thicketDir.existsSync()) {
    thicketDir.createSync(recursive: true);
  }

  final Map<String, dynamic> credentials = <String, dynamic>{
    'apiToken': apiToken,
  };

  final File credentialsFile = File(
    p.join(thicketDir.path, 'credentials.json'),
  );
  credentialsFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(credentials),
  );

  _ensureGitignore(projectPath);
}

/// Ensures `.thicket/credentials.json` is listed in the project's `.gitignore`.
///
/// If `.gitignore` exists, appends the entry only if it is not already present. If `.gitignore` does not exist, creates
/// it with just the credentials entry.
void _ensureGitignore(String projectPath) {
  const String entry = '.thicket/credentials.json';
  final File gitignore = File(p.join(projectPath, '.gitignore'));

  if (gitignore.existsSync()) {
    final String content = gitignore.readAsStringSync();
    if (content.contains(entry)) return;
    final String prefix = content.endsWith('\n') ? '' : '\n';
    gitignore.writeAsStringSync('$prefix$entry\n', mode: FileMode.append);
  } else {
    gitignore.writeAsStringSync('$entry\n');
  }
}
