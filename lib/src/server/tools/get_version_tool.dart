import '../mcp_tool.dart';

/// Creates the `get_version` tool which returns the current Thicket server version.
///
/// This is a simple, deterministic tool useful for verifying that the MCP server is running and responding correctly.
/// It takes no arguments and always returns the version string it was configured with.
McpTool getVersionTool({required String version}) {
  return McpTool(
    name: 'get_version',
    description: 'Returns the current version of the Thicket server.',
    inputSchema: {
      'type': 'object',
      'properties': <String, dynamic>{},
    },
    handler: (_) async => {'version': version},
  );
}
