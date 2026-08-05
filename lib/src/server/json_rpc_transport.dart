import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'json_rpc_message.dart';

/// Handles newline-delimited JSON-RPC 2.0 transport over stdio.
///
/// Reads JSON messages from stdin (one per line) and writes JSON responses to stdout (one per line). This is the
/// standard stdio transport for MCP servers.
class JsonRpcTransport {
  /// The line-based input stream to read JSON-RPC messages from.
  final Stream<String> _input;

  /// The output sink to write JSON-RPC responses to.
  final IOSink _output;

  /// Creates a transport using the given input and output streams.
  ///
  /// Defaults to stdin and stdout when not provided, which is the standard MCP stdio transport.
  JsonRpcTransport({
    Stream<String>? input,
    IOSink? output,
  }) : _input = input ?? _defaultInput(),
       _output = output ?? stdout;

  /// Creates the default line-split UTF-8 stdin stream.
  static Stream<String> _defaultInput() {
    return stdin.transform(utf8.decoder).transform(const LineSplitter());
  }

  /// Listens for incoming JSON-RPC messages and invokes [onMessage] for each one.
  ///
  /// Returns a future that completes when the input stream closes.
  Future<void> listen(
    Future<void> Function(JsonRpcMessage message) onMessage,
  ) async {
    await for (final String line in _input) {
      if (line.trim().isEmpty) {
        continue;
      }

      try {
        final Map<String, dynamic> json = jsonDecode(line) as Map<String, dynamic>;
        await onMessage(JsonRpcMessage(json));
      } on FormatException {
        sendError(null, -32700, 'Parse error');
      }
    }
  }

  /// Sends a successful JSON-RPC response.
  void sendResult(Object? id, Map<String, dynamic> result) {
    _send({
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });
  }

  /// Sends a JSON-RPC error response.
  void sendError(
    Object? id,
    int code,
    String message, {
    Object? data,
  }) {
    final Map<String, dynamic> error = <String, dynamic>{
      'code': code,
      'message': message,
    };

    if (data != null) {
      error['data'] = data;
    }

    _send({
      'jsonrpc': '2.0',
      'id': id,
      'error': error,
    });
  }

  /// Serializes and writes a JSON-RPC message to the output stream.
  void _send(Map<String, dynamic> message) {
    _output.writeln(jsonEncode(message));
  }
}
