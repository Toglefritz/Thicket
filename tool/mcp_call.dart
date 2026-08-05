import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A command-line client for testing Thicket MCP tool calls.
///
/// Spawns the Thicket MCP server as a subprocess, performs the initialization handshake, invokes the specified tool,
/// prints the formatted result, and exits.
///
/// Usage: dart run tool/mcp_call.dart `<tool_name>` [--key value ...]
///
/// Examples: 
/// - dart run tool/mcp_call.dart get_version 
/// - dart run tool/mcp_call.dart initialize_project --projectPath /tmp/new-project 
/// - dart run tool/mcp_call.dart initialize_project --projectPath /tmp/new-project --projectName "New Project"
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printUsage();
    exit(1);
  }

  final String toolName = arguments.first;
  final Map<String, dynamic> toolArguments = _parseArguments(
    arguments.skip(1).toList(),
  );

  // Spawn the MCP server as a subprocess.
  final Process server = await Process.start(
    'dart',
    ['run', 'bin/thicket.dart'],
    workingDirectory: Directory.current.path,
  );

  // Set up a single stream subscription that feeds lines into a queue. This avoids re-listening to stdout multiple
  // times.
  final StreamController<String> lineController = StreamController<String>();
  server.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(lineController.add);
  final StreamQueue lineQueue = StreamQueue(lineController.stream);

  int requestId = 0;

  /// Sends a JSON-RPC request and reads the next response line.
  Future<Map<String, dynamic>> sendRequest(
    String method, {
    Map<String, dynamic>? params,
  }) async {
    requestId++;
    final Map<String, dynamic> request = {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
    };
    if (params != null) {
      request['params'] = params;
    }

    server.stdin.writeln(jsonEncode(request));
    final String line = await lineQueue.next;
    return jsonDecode(line) as Map<String, dynamic>;
  }

  /// Sends a JSON-RPC notification (no response expected).
  void sendNotification(String method) {
    final Map<String, dynamic> notification = {
      'jsonrpc': '2.0',
      'method': method,
    };
    server.stdin.writeln(jsonEncode(notification));
  }

  try {
    // Step 1: Initialize handshake.
    final Map<String, dynamic> initResult = await sendRequest(
      'initialize',
      params: {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'mcp_call', 'version': '1.0.0'},
      },
    );

    final Map<String, dynamic>? initError = initResult['error'] as Map<String, dynamic>?;
    if (initError != null) {
      stderr.writeln('Initialize failed: ${initError['message']}');
      server.kill();
      exit(1);
    }

    // Step 2: Send initialized notification.
    sendNotification('notifications/initialized');

    // Step 3: Call the requested tool.
    final Map<String, dynamic> callResult = await sendRequest(
      'tools/call',
      params: {
        'name': toolName,
        'arguments': toolArguments,
      },
    );

    // Step 4: Print the result.
    final Map<String, dynamic>? callError = callResult['error'] as Map<String, dynamic>?;
    if (callError != null) {
      stderr.writeln('Error: ${callError['message']}');
      server.kill();
      exit(1);
    }

    final Map<String, dynamic> result = callResult['result'] as Map<String, dynamic>;
    final bool isError = (result['isError'] as bool?) ?? false;

    if (isError) {
      stderr.writeln('Tool error:');
    }

    // Extract and pretty-print the content.
    final List<dynamic> content = result['content'] as List<dynamic>;
    for (final dynamic block in content) {
      final Map<String, dynamic> contentBlock = block as Map<String, dynamic>;
      final String text = contentBlock['text'] as String;

      // Attempt to parse as JSON for pretty-printing.
      try {
        final Object? parsed = jsonDecode(text);
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(parsed),
        );
      } on FormatException {
        stdout.writeln(text);
      }
    }

    if (isError) {
      server.kill();
      exit(1);
    }
  } finally {
    server.kill();
  }
}

/// A minimal async queue that yields values from a stream one at a time, allowing sequential awaits on a
/// broadcast-style source.
class StreamQueue {
  final Stream<String> _stream;
  final List<String> _buffer = [];
  final List<Completer<String>> _waiters = [];
  late final StreamSubscription<String> _subscription;

  StreamQueue(this._stream) {
    _subscription = _stream.listen(
      (String line) {
        if (_waiters.isNotEmpty) {
          _waiters.removeAt(0).complete(line);
        } else {
          _buffer.add(line);
        }
      },
      onDone: () {
        for (final Completer<String> waiter in _waiters) {
          waiter.completeError(StateError('Stream closed'));
        }
        _waiters.clear();
      },
    );
  }

  /// Returns the next line from the stream, waiting if necessary.
  Future<String> get next {
    if (_buffer.isNotEmpty) {
      return Future<String>.value(_buffer.removeAt(0));
    }
    final Completer<String> completer = Completer<String>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Cancels the underlying stream subscription.
  Future<void> cancel() => _subscription.cancel();
}

/// Parses `--key value` pairs from the argument list into a map.
///
/// Keys must be prefixed with `--`. The following argument is treated as the value unless it also starts with `--`, in
/// which case the key is treated as a boolean flag.
Map<String, dynamic> _parseArguments(List<String> args) {
  final Map<String, dynamic> result = {};
  int i = 0;

  while (i < args.length) {
    final String arg = args[i];

    if (arg.startsWith('--')) {
      final String key = arg.substring(2);

      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        result[key] = args[i + 1];
        i += 2;
      } else {
        result[key] = true;
        i++;
      }
    } else {
      stderr.writeln('Unexpected argument: $arg');
      exit(1);
    }
  }

  return result;
}

/// Prints usage information to stderr.
void _printUsage() {
  stderr.writeln(
    'Usage: dart run tool/mcp_call.dart <tool_name> [--key value ...]',
  );
  stderr.writeln('');
  stderr.writeln('Examples:');
  stderr.writeln('  dart run tool/mcp_call.dart get_version');
  stderr.writeln(
    '  dart run tool/mcp_call.dart initialize_project --projectPath /tmp/my-project',
  );
}
