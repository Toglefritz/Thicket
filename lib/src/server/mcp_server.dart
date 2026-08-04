import 'dart:convert';

import 'json_rpc_transport.dart';
import 'mcp_tool.dart';

/// A minimal MCP server that handles the protocol lifecycle and dispatches tool calls.
///
/// Supports the following JSON-RPC methods:
/// - `initialize` — capability negotiation
/// - `notifications/initialized` — client ready signal (no response)
/// - `ping` — health check
/// - `tools/list` — enumerates registered tools
/// - `tools/call` — invokes a tool by name
class McpServer {
  /// The protocol version this server supports.
  static const String protocolVersion = '2025-06-18';

  /// The human-readable name of this server, reported during initialization.
  final String _serverName;

  /// The version string of this server, reported during initialization.
  final String _serverVersion;

  /// The JSON-RPC transport used for communication.
  final JsonRpcTransport _transport;

  /// Registry of tools indexed by name for O(1) lookup during `tools/call`.
  final Map<String, McpTool> _tools = {};

  /// Creates an MCP server with the given name and version.
  ///
  /// Optionally accepts a custom [transport] for testing. Defaults to a stdio-based transport.
  McpServer({
    required String serverName,
    required String serverVersion,
    JsonRpcTransport? transport,
  }) : _serverName = serverName, // ignore: prefer_initializing_formals
       _serverVersion = serverVersion, // ignore: prefer_initializing_formals
       _transport = transport ?? JsonRpcTransport();

  /// Registers a tool with the server.
  ///
  /// Must be called before [serve] to ensure the tool appears in `tools/list` responses.
  void registerTool(McpTool tool) {
    _tools[tool.name] = tool;
  }

  /// Starts listening for incoming JSON-RPC messages and dispatching them.
  ///
  /// Returns a future that completes when the input stream closes.
  Future<void> serve() {
    return _transport.listen(_handleMessage);
  }

  /// Routes an incoming JSON-RPC message to the appropriate handler.
  ///
  /// Notifications (messages without an id) are acknowledged silently. Requests are dispatched by method name.
  Future<void> _handleMessage(JsonRpcMessage message) async {
    final String? method = message.method;

    // Notifications have no id and expect no response.
    if (message.isNotification) {
      // We recognize notifications/initialized; others are silently ignored per the spec.
      return;
    }

    // Requests expect a response.
    switch (method) {
      case 'initialize':
        _handleInitialize(message);
      case 'ping':
        _transport.sendResult(message.id, {});
      case 'tools/list':
        _handleToolsList(message);
      case 'tools/call':
        await _handleToolsCall(message);
      default:
        _transport.sendError(
          message.id,
          -32601,
          'Method not found: $method',
        );
    }
  }

  /// Handles the `initialize` method by responding with server capabilities and identity.
  void _handleInitialize(JsonRpcMessage message) {
    _transport.sendResult(message.id, {
      'protocolVersion': protocolVersion,
      'capabilities': {
        'tools': <String, dynamic>{},
      },
      'serverInfo': {
        'name': _serverName,
        'version': _serverVersion,
      },
    });
  }

  /// Handles the `tools/list` method by returning metadata for all registered tools.
  void _handleToolsList(JsonRpcMessage message) {
    _transport.sendResult(message.id, {
      'tools': _tools.values.map((t) => t.toListEntry()).toList(),
    });
  }

  /// Handles the `tools/call` method by looking up and invoking the named tool.
  ///
  /// Returns a JSON-RPC error if params are missing, the tool name is absent, or the tool is not registered. Exceptions
  /// thrown by the tool handler are caught and returned as MCP error content.
  Future<void> _handleToolsCall(JsonRpcMessage message) async {
    final Map<String, dynamic>? params = message.params;
    if (params == null) {
      _transport.sendError(
        message.id,
        -32602,
        'Invalid params: missing params',
      );
      return;
    }

    final String? toolName = params['name'] as String?;
    if (toolName == null) {
      _transport.sendError(
        message.id,
        -32602,
        'Invalid params: missing tool name',
      );
      return;
    }

    final McpTool? tool = _tools[toolName];
    if (tool == null) {
      _transport.sendError(
        message.id,
        -32602,
        'Unknown tool: $toolName',
      );
      return;
    }

    final Map<String, dynamic> arguments = (params['arguments'] as Map<String, dynamic>?) ?? {};

    try {
      final Map<String, dynamic> result = await tool.handler(arguments);
      _transport.sendResult(message.id, {
        'content': [
          {
            'type': 'text',
            'text': jsonEncode(result),
          },
        ],
      });
    } on Exception catch (e) {
      _transport.sendResult(message.id, {
        'content': [
          {
            'type': 'text',
            'text': 'Error: $e',
          },
        ],
        'isError': true,
      });
    }
  }
}
