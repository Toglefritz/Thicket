import '../models/ide_type.dart';

/// No-op implementation of [McpInstallerService] for web.
///
/// The MCP server installation requires running shell commands and writing files, which are not possible on web. The
/// controller skips the IDE selection step entirely on web, so these methods should not be called.
class McpInstallerService {
  const McpInstallerService._();

  /// No-op on web.
  static Future<void> activateFromGitHub() async {}

  /// No-op on web. Returns an empty string.
  static String install({
    required IdeType ide,
    required String projectPath,
  }) {
    return '';
  }
}
