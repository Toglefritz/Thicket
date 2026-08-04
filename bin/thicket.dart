import 'package:thicket/src/server/mcp_server.dart';
import 'package:thicket/src/server/tools/get_version_tool.dart';

const String version = '0.1.0';

Future<void> main(List<String> arguments) async {
  final server = McpServer(
    serverName: 'thicket',
    serverVersion: version,
  );

  server.registerTool(getVersionTool(version: version));

  await server.serve();
}
