part of 'concept.dart';

/// Indicates where a concept came from and implicitly how much friction is required to modify it.
///
/// The origin tier determines the stability expectations for a concept:
/// - [builtin] concepts are part of Thicket's fixed infrastructure
/// and cannot be modified through MCP tools.
/// - [recommended] concepts ship as sensible defaults and require
/// strong rationale to modify.
/// - [projectDefined] concepts are created by the agent as it learns
/// what abstractions matter for a particular project.
enum ConceptOrigin {
  /// A structural concept that is part of Thicket itself.
  ///
  /// Cannot be modified or retired through the MCP interface.
  builtin,

  /// A concept from the recommended starter set.
  ///
  /// Modifiable through MCP, but the system expects stronger justification proportional to usage.
  recommended,

  /// A concept introduced by the agent for this specific project.
  ///
  /// Created and managed through the normal MCP workflow with required rationale.
  projectDefined,
}
