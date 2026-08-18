/// Represents an agentic IDE that Thicket can integrate with via MCP.
///
/// Each value corresponds to a specific IDE and its MCP configuration format and file location. The order of values
/// reflects the preferred presentation order in the setup wizard (Antigravity first as the hackathon's primary IDE).
enum IdeType {
  /// Google Antigravity IDE.
  ///
  /// Workspace-level MCP config lives at `.agents/mcp_config.json` relative to the project root.
  antigravity(
    displayName: 'Antigravity',
    configRelativePath: '.agents/mcp_config.json',
  ),

  /// Amazon Kiro IDE, based on VS Code with MCP support.
  kiro(
    displayName: 'Kiro',
    configRelativePath: '.kiro/settings/mcp.json',
  );

  const IdeType({
    required this.displayName,
    required this.configRelativePath,
  });

  /// The human-readable name shown in the setup wizard.
  final String displayName;

  /// The path (relative to the project root) where this IDE expects its MCP server configuration file.
  final String configRelativePath;
}
