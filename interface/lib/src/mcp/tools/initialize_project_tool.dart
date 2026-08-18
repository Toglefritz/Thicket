import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `initialize_project` tool which sets up Thicket for a new project.
///
/// This tool performs the project initialization workflow:
/// 1. Generates a human-readable unique identifier for the project
/// 2. Creates `.thicket/project.json` in the project's root directory
/// 3. Creates the storage directory (cloud mode requires no local directory, centralized uses
/// `~/.thicket/projects/<id>/`, inRepo uses `.thicket/world_model/`)
///
/// The tool requires a `projectPath` argument pointing to the root of the project to initialize. It also accepts an
/// optional `projectName` for the human-readable label stored in the identity file.
///
/// If the project has already been initialized (`.thicket/project.json` exists), the tool returns the existing identity
/// without modifying anything.
McpTool initializeProjectTool() {
  return McpTool(
    name: 'initialize_project',
    description:
        'Initializes Thicket for a project by creating a .thicket/project.json identity file and provisioning the '
        'world model storage backend. If the project is already initialized, returns the existing identity.',
    inputSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, Map<String, Object>>{
        'projectPath': <String, String>{
          'type': 'string',
          'description': 'Absolute path to the root directory of the project to initialize.',
        },
        'projectName': <String, String>{
          'type': 'string',
          'description': 'A human-readable name for the project. Defaults to the directory name if not provided.',
        },
        'storageMode': <String, Object>{
          'type': 'string',
          'description':
              'The storage topology for the world model: "cloud", "centralized", or "inRepo". '
              'Defaults to "cloud".',
          'enum': <String>['cloud', 'centralized', 'inRepo'],
        },
        'gcpProjectId': <String, String>{
          'type': 'string',
          'description':
              'The Google Cloud project ID that owns the Firestore database. Required when storageMode is "cloud".',
        },
      },
      'required': <String>['projectPath'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String? projectPath = arguments['projectPath'] as String?;
      if (projectPath == null || projectPath.isEmpty) {
        throw ArgumentError('projectPath is required');
      }

      final Directory projectDir = Directory(projectPath);
      if (!projectDir.existsSync()) {
        throw ArgumentError(
          'Project directory does not exist: $projectPath',
        );
      }

      // Check if already initialized.
      final Directory thicketDir = Directory(p.join(projectPath, '.thicket'));
      final File identityFile = File(p.join(thicketDir.path, 'project.json'));

      if (identityFile.existsSync()) {
        final Map<String, dynamic> existing = jsonDecode(identityFile.readAsStringSync()) as Map<String, dynamic>;
        return <String, dynamic>{
          'status': 'already_initialized',
          'identity': existing,
        };
      }

      // Generate the project identity.
      final IdGenerator generator = IdGenerator();
      final String projectId = generator.generate();
      final String projectName = (arguments['projectName'] as String?) ?? p.basename(projectPath);
      final StorageMode storageMode = StorageMode.fromString(
        arguments['storageMode'] as String? ?? 'cloud',
      );
      final String? gcpProjectId = arguments['gcpProjectId'] as String?;

      if (storageMode == StorageMode.cloud && (gcpProjectId == null || gcpProjectId.isEmpty)) {
        throw ArgumentError(
          'gcpProjectId is required when storageMode is "cloud".',
        );
      }

      final ProjectIdentity identity = ProjectIdentity(
        projectId: projectId,
        projectName: projectName,
        createdAt: DateTime.now().toUtc(),
        storageMode: storageMode,
        gcpProjectId: gcpProjectId,
      );

      // Create .thicket/project.json in the project directory.
      thicketDir.createSync(recursive: true);
      identityFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(identity.toJson()),
      );

      // Create the local storage directory for non-cloud modes.
      String? storagePath;
      if (storageMode == StorageMode.inRepo) {
        storagePath = p.join(projectPath, '.thicket', 'world_model');
      } else if (storageMode == StorageMode.centralized) {
        final String home = ProjectResolver.getHomeDirectory();
        if (home.isEmpty) {
          throw StateError('Home directory environment variable is not set');
        }
        storagePath = p.join(home, '.thicket', 'projects', projectId);
      }

      if (storagePath != null) {
        final Directory storageDir = Directory(storagePath);
        storageDir.createSync(recursive: true);
      }

      return <String, dynamic>{
        'status': 'initialized',
        'identity': identity.toJson(),
        'storagePath': ?storagePath,
      };
    },
  );
}
