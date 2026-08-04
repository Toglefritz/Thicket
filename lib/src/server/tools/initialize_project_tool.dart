import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../models/project/project_identity.dart';
import '../../utils/id_generator.dart';
import '../mcp_tool.dart';

/// Creates the `initialize_project` tool which sets up Thicket for a new project.
///
/// This tool performs the project initialization workflow:
/// 1. Generates a human-readable unique identifier for the project
/// 2. Creates `.thicket/project.json` in the project's root directory
/// 3. Creates the centralized storage directory at
/// `~/.thicket/projects/<id>/`
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
        'Initializes Thicket for a project by creating a .thicket/project.json identity file and the centralized world '
        'model storage directory. If the project is already initialized, returns the existing identity.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'projectPath': {
          'type': 'string',
          'description': 'Absolute path to the root directory of the project to initialize.',
        },
        'projectName': {
          'type': 'string',
          'description': 'A human-readable name for the project. Defaults to the directory name if not provided.',
        },
      },
      'required': ['projectPath'],
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
        return {
          'status': 'already_initialized',
          'identity': existing,
        };
      }

      // Generate the project identity.
      final IdGenerator generator = IdGenerator();
      final String projectId = generator.generate();
      final String projectName = (arguments['projectName'] as String?) ?? p.basename(projectPath);

      final ProjectIdentity identity = ProjectIdentity(
        projectId: projectId,
        projectName: projectName,
        createdAt: DateTime.now().toUtc(),
      );

      // Create .thicket/project.json in the project directory.
      thicketDir.createSync(recursive: true);
      identityFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(identity.toJson()),
      );

      // Create the centralized storage directory.
      final String home = Platform.environment['HOME'] ?? '';
      final Directory storageDir = Directory(
        p.join(home, '.thicket', 'projects', projectId),
      );
      storageDir.createSync(recursive: true);

      return {
        'status': 'initialized',
        'identity': identity.toJson(),
        'storagePath': storageDir.path,
      };
    },
  );
}
