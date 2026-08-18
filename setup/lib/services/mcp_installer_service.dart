import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/ide_type.dart';

/// The GitHub repository URL for the Thicket project.
const String _thicketGitUrl = 'https://github.com/Toglefritz/Thicket.git';

/// The subdirectory within the Thicket repository containing the MCP server package.
const String _interfaceGitPath = 'interface';

/// Writes the MCP server configuration for the selected IDE into the target project directory.
///
/// This service globally activates the Thicket MCP server package from GitHub, then generates the JSON configuration
/// that tells the IDE how to launch it. The configuration file location and format vary by IDE, but all use the
/// stdio-based JSON-RPC transport.
class McpInstallerService {
  const McpInstallerService._();

  /// Globally activates the Thicket MCP server package from GitHub.
  ///
  /// Runs `dart pub global activate --source git` targeting the `interface` subdirectory of the Thicket repository.
  /// This makes the `thicket_interface:thicket` executable available system-wide without requiring a local clone of the
  /// repository.
  ///
  /// Throws a [ProcessException] or [Exception] if activation fails.
  static Future<void> activateFromGitHub() async {
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
      final String stderr = (result.stderr as String).trim();
      throw Exception(
        'Failed to activate Thicket MCP server from GitHub: $stderr',
      );
    }
  }

  /// Installs the Thicket MCP server configuration for [ide] in [projectPath].
  ///
  /// If the configuration file already exists, the `thicket` server entry is merged into the existing file without
  /// overwriting other server definitions.
  ///
  /// Returns the absolute path to the configuration file that was written.
  static String install({
    required IdeType ide,
    required String projectPath,
  }) {
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
      final String existingContent = configFile.readAsStringSync();
      config =
          existingContent.trim().isNotEmpty ? jsonDecode(existingContent) as Map<String, dynamic> : <String, dynamic>{};
    } else {
      config = <String, dynamic>{};
    }

    final Map<String, dynamic> servers = (config['mcpServers'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    servers['thicket'] = thicketServer;
    config['mcpServers'] = servers;

    configFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(config),
    );

    return configPath;
  }

  /// Constructs the MCP server entry describing how to launch the Thicket process.
  ///
  /// The server is launched via `dart pub global run`, which invokes the globally activated `thicket_interface`
  /// package's `thicket` executable. This removes any dependency on a local clone of the Thicket repository.
  static Map<String, dynamic> _buildServerEntry() {
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
}
