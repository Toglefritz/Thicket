import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/ide_type.dart';

/// Writes the MCP server configuration for the selected IDE into the target project directory.
///
/// This service generates the JSON configuration that tells the IDE how to launch the Thicket MCP server process. The
/// configuration file location and format vary by IDE, but all use the stdio-based JSON-RPC transport.
class McpInstallerService {
  const McpInstallerService._();

  /// Installs the Thicket MCP server configuration for [ide] in [projectPath].
  ///
  /// The [thicketRootPath] is the absolute path to the Thicket repository root, used to construct the command that
  /// launches the MCP server binary.
  ///
  /// If the configuration file already exists, the `thicket` server entry is merged into the existing file without
  /// overwriting other server definitions.
  ///
  /// Returns the absolute path to the configuration file that was written.
  static String install({
    required IdeType ide,
    required String projectPath,
    required String thicketRootPath,
  }) {
    final String configPath = p.join(projectPath, ide.configRelativePath);
    final File configFile = File(configPath);

    // Ensure the parent directory exists.
    final Directory configDir = configFile.parent;
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }

    // Build the Thicket MCP server entry.
    final Map<String, dynamic> thicketServer = _buildServerEntry(
      thicketRootPath: thicketRootPath,
    );

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
  /// The server is started with `dart run` targeting the interface package's binary. The working directory is set to
  /// the interface package so that `dart run` resolves dependencies correctly.
  static Map<String, dynamic> _buildServerEntry({
    required String thicketRootPath,
  }) {
    final String interfacePath = p.join(thicketRootPath, 'interface');

    return <String, dynamic>{
      'command': 'dart',
      'args': <String>[
        'run',
        p.join(interfacePath, 'bin', 'thicket.dart'),
      ],
    };
  }
}
