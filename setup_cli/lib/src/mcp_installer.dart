/// MCP Server Installer
///
/// Handles activating the Thicket MCP server package globally via `dart pub global activate` and writing the MCP server
/// configuration file for the user's selected IDE. The configuration tells the IDE how to launch the Thicket MCP server
/// process using stdio-based JSON-RPC transport.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ide_type.dart';

/// The GitHub repository URL for the Thicket project.
///
/// Used as the source for `dart pub global activate --source git`.
const String _thicketGitUrl = 'https://github.com/Toglefritz/Thicket.git';

/// The subdirectory within the Thicket repository containing the MCP server package.
///
/// The interface package contains the MCP server executable that communicates with the Thicket world model.
const String _interfaceGitPath = 'interface';

/// Globally activates the Thicket MCP server package from GitHub.
///
/// Runs `dart pub global activate --source git` targeting the `interface` subdirectory of the Thicket repository. This
/// makes the `thicket_interface:thicket` executable available system-wide without requiring a local clone.
///
/// Throws an [Exception] if the activation process exits with a non-zero exit code.
Future<void> activateMcpServer() async {
  final ProcessResult result = await Process.run(
    'dart',
    <String>[
      'pub',
      'global',
      'activate',
      '--source',
      'git',
      _thicketGitUrl,
      '--git-path',
      _interfaceGitPath,
    ],
  );

  if (result.exitCode != 0) {
    throw Exception(
      'Failed to activate Thicket MCP server: '
      '${(result.stderr as String).trim()}',
    );
  }
}

/// Writes the MCP server configuration for [ide] into [projectPath].
///
/// Creates or merges into the IDE-specific MCP configuration file. If the file already exists, the `thicket` server
/// entry is merged into the existing `mcpServers` map without overwriting other server definitions.
///
/// The generated config tells the IDE to launch the Thicket MCP server via `dart pub global run
/// thicket_interface:thicket`.
void installMcpConfig(IdeType ide, String projectPath) {
  final String configPath = p.join(projectPath, ide.configRelativePath);
  final File configFile = File(configPath);

  // Ensure the parent directory exists.
  final Directory configDir = configFile.parent;
  if (!configDir.existsSync()) {
    configDir.createSync(recursive: true);
  }

  // Build the Thicket MCP server entry.
  final Map<String, dynamic> thicketServer = _buildServerEntry();

  // Merge into any existing configuration.
  Map<String, dynamic> config;
  if (configFile.existsSync()) {
    final String existing = configFile.readAsStringSync();
    config = existing.trim().isNotEmpty ? jsonDecode(existing) as Map<String, dynamic> : <String, dynamic>{};
  } else {
    config = <String, dynamic>{};
  }

  final Map<String, dynamic> servers = (config['mcpServers'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  servers['thicket'] = thicketServer;
  config['mcpServers'] = servers;

  configFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(config),
  );
}

/// Constructs the MCP server entry describing how to launch the Thicket process.
///
/// The server is launched via `dart pub global run`, which invokes the globally activated `thicket_interface` package's
/// `thicket` executable. This removes any dependency on a local clone of the Thicket repository.
Map<String, dynamic> _buildServerEntry() {
  return <String, dynamic>{
    'command': 'dart',
    'args': <String>[
      'pub',
      'global',
      'run',
      'thicket_interface:thicket',
    ],
  };
}
