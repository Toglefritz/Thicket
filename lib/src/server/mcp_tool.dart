/// Describes a tool that can be invoked through the MCP interface.
///
/// Each tool has a name, description, input schema, and a handler that produces a result when called.
class McpTool {
  /// The unique name of this tool.
  final String name;

  /// A human-readable description of what this tool does.
  final String description;

  /// JSON Schema describing the expected input arguments.
  ///
  /// Must be an object schema with `type: "object"` at the top level.
  final Map<String, dynamic> inputSchema;

  /// The handler that executes this tool and returns a result.
  ///
  /// Receives the `arguments` map from the `tools/call` request. Returns a map that will be wrapped in the MCP content
  /// response.
  final Future<Map<String, dynamic>> Function(
    Map<String, dynamic> arguments,
  )
  handler;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });

  /// Serializes this tool's metadata for a `tools/list` response.
  Map<String, dynamic> toListEntry() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };
}
