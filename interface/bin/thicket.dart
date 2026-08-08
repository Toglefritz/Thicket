import 'package:thicket_interface/src/mcp/mcp_server.dart';
import 'package:thicket_interface/src/mcp/tools/define_concept_tool.dart';
import 'package:thicket_interface/src/mcp/tools/get_version_tool.dart';
import 'package:thicket_interface/src/mcp/tools/initialize_project_tool.dart';
import 'package:thicket_interface/src/mcp/tools/learn_tool.dart';
import 'package:thicket_interface/src/mcp/tools/recall_tool.dart';
import 'package:thicket_interface/src/mcp/tools/remember_tool.dart';

/// The current version of the Thicket server.
///
/// This value is reported during MCP initialization and returned by the `get_version` tool. It should stay in sync with
/// the version declared in `pubspec.yaml`.
const String version = '0.1.0';

/// Entry point for the Thicket MCP server.
///
/// Starts a stdio-based MCP server that exposes world model tools to AI coding agents. The server reads JSON-RPC
/// messages from stdin and writes responses to stdout, following the Model Context Protocol specification.
///
/// This process is intended to be launched by an MCP client (such as Kiro or another compatible IDE) rather than
/// invoked directly by a user.
Future<void> main(List<String> arguments) async {
  final McpServer server = McpServer(
    serverName: 'thicket',
    serverVersion: version,
  );

  server.registerTool(getVersionTool(version: version));
  server.registerTool(initializeProjectTool());
  server.registerTool(rememberTool());
  server.registerTool(recallTool());
  server.registerTool(learnTool());
  server.registerTool(defineConceptTool());

  await server.serve();
}
