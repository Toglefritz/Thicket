import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `define_concept` tool which introduces or refines a concept in the project's ontology.
///
/// This is the write path for the ontology layer. When an agent identifies a recurring abstraction that is important
/// for understanding the project (e.g. "Screen", "Repository", "TimingConstraint"), it calls this tool to formalize
/// that concept in the world model.
///
/// All concepts created through this tool receive the origin `projectDefined` and start with status `proposed`. A
/// concept transitions to `active` once it is referenced by beliefs or episodes.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `name`: concise noun or noun phrase for the concept
/// - `description`: what the concept represents and when to apply it
/// - `rationale`: why this concept is being introduced
///
/// Optional arguments:
/// - `supersededConceptIds`: concept IDs this concept replaces
McpTool defineConceptTool() {
  return McpTool(
    name: 'define_concept',
    description:
        'Introduces or refines a concept in the project ontology. Use this when you identify a recurring abstraction '
        'that is important for understanding the project: architectural layers, component types, patterns, domain '
        'entities, or other concepts that help organize knowledge about the system.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'projectPath': {
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'name': {
          'type': 'string',
          'description':
              'A concise noun or noun phrase for the concept '
              '(e.g. "Screen", "Repository", "TimingConstraint").',
        },
        'description': {
          'type': 'string',
          'description': 'What this concept represents and when it should be applied.',
        },
      },
      'required': ['projectPath', 'name', 'description'],
    },
    handler: (arguments) async {
      final projectPath = arguments['projectPath'] as String;
      final name = arguments['name'] as String;
      final description = arguments['description'] as String;

      // Resolve the project's storage directory.
      final storagePath = ProjectResolver.resolveStoragePath(projectPath);
      final store = EntityStore(storagePath: storagePath);

      // Generate a unique ID for this concept.
      final generator = IdGenerator();
      final conceptId = generator.generateShort();

      // Create the concept entity.
      final now = DateTime.now().toUtc();
      final concept = Concept(
        id: conceptId,
        createdAt: now,
        updatedAt: now,
        name: name,
        description: description,
        status: ConceptStatus.proposed,
      );

      // Persist the new concept.
      await store.save(collection: 'concepts', entity: concept);

      return {
        'status': 'defined',
        'conceptId': conceptId,
        'concept': concept.toJson(),
      };
    },
  );
}
