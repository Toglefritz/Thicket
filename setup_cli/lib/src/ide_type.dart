/// IDE Type Definitions
///
/// Defines the supported IDEs that Thicket can integrate with via MCP. Each IDE has its own configuration file format
/// and location within a project directory. The enum values determine where the MCP server config and agent hooks are
/// written during setup.
library;

/// Represents an agentic IDE that Thicket can integrate with via MCP.
///
/// Each value corresponds to a specific IDE and its MCP configuration format and file location. The order of values
/// reflects the preferred presentation order in the setup wizard (Antigravity first as the hackathon's primary IDE).
enum IdeType {
  /// Google Antigravity IDE.
  ///
  /// Workspace-level MCP config lives at `.agents/mcp_config.json` relative to the project root. Agent hooks use shell
  /// scripts in `.agents/scripts/` referenced from `.agents/hooks.json`.
  antigravity(
    displayName: 'Antigravity',
    configRelativePath: '.agents/mcp_config.json',
  ),

  /// Amazon Kiro IDE, based on VS Code with MCP support.
  ///
  /// Workspace-level MCP config lives at `.kiro/settings/mcp.json` relative to the project root. Agent hooks are
  /// individual JSON files in `.kiro/hooks/`.
  kiro(
    displayName: 'Kiro',
    configRelativePath: '.kiro/settings/mcp.json',
  );

  /// Creates an IDE type with its display name and configuration path.
  const IdeType({
    required this.displayName,
    required this.configRelativePath,
  });

  /// The human-readable name shown in the setup wizard.
  final String displayName;

  /// The path (relative to the project root) where this IDE expects its MCP server configuration file.
  final String configRelativePath;
}
