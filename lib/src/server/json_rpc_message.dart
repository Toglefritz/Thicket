/// A JSON-RPC 2.0 message received from the client.
///
/// This is a thin wrapper around the decoded JSON map, providing convenient accessors for the standard JSON-RPC fields.
class JsonRpcMessage {
  /// The raw decoded JSON map for this message.
  final Map<String, dynamic> raw;

  /// Creates a message wrapping the given decoded JSON map.
  const JsonRpcMessage(this.raw);

  /// The JSON-RPC version string. Always "2.0" for valid messages.
  String get jsonrpc => raw['jsonrpc'] as String;

  /// The method name being invoked. Present on requests and notifications.
  String? get method => raw['method'] as String?;

  /// The request identifier. Present on requests, absent on notifications.
  Object? get id => raw['id'];

  /// The parameters object. May be a map or absent.
  Map<String, dynamic>? get params => raw['params'] as Map<String, dynamic>?;

  /// Whether this message is a notification (no id field).
  bool get isNotification => id == null;

  /// Whether this message is a request (has an id field).
  bool get isRequest => id != null;
}
