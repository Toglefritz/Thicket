import '../../models/ontology/concept.dart';
import '../../storage/entity_store.dart';
import '../../utils/id_generator.dart';
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
        'entities, or other concepts that help organize knowledge about the system. Requires a rationale explaining '
        'why this concept is needed.',
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
        'rationale': {
          'type': 'string',
          'description':
              'Why this concept is being introduced. Explains what pattern or abstraction the agent has identified '
              'that warrants a new concept.',
        },
        'supersededConceptIds': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Identifiers of older concepts that this concept replaces. The superseded concepts will be marked as '
              'deprecated.',
        },
      },
      'required': ['projectPath', 'name', 'description', 'rationale'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String name = arguments['name'] as String;
      final String description = arguments['description'] as String;
      final String rationale = arguments['rationale'] as String;
      final List<String> supersededConceptIds =
          (arguments['supersededConceptIds'] as List<dynamic>?)?.cast<String>() ?? [];

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(projectPath);
      final EntityStore store = EntityStore(storagePath: storagePath);

      // Generate a unique ID for this concept.
      final IdGenerator generator = IdGenerator();
      final String conceptId = generator.generateShort();

      // Create the concept entity.
      final DateTime now = DateTime.now().toUtc();
      final Concept concept = Concept(
        id: conceptId,
        createdAt: now,
        updatedAt: now,
        revision: 1,
        name: name,
        description: description,
        origin: ConceptOrigin.projectDefined,
        status: ConceptStatus.proposed,
        rationale: rationale,
        supersededConceptIds: supersededConceptIds,
      );

      // If this concept supersedes others, mark them as deprecated.
      for (final String oldConceptId in supersededConceptIds) {
        final Map<String, dynamic>? existing = await store.load(
          collection: 'concepts',
          id: oldConceptId,
        );
        if (existing != null) {
          final Concept oldConcept = Concept.fromJson(existing);
          final Concept updatedOld = Concept(
            id: oldConcept.id,
            createdAt: oldConcept.createdAt,
            updatedAt: now,
            revision: oldConcept.revision + 1,
            name: oldConcept.name,
            description: oldConcept.description,
            origin: oldConcept.origin,
            status: ConceptStatus.deprecated,
            rationale: 'Superseded by concept "$name" ($conceptId)',
            supersededConceptIds: oldConcept.supersededConceptIds,
          );
          await store.update(
            collection: 'concepts',
            entity: updatedOld,
            expectedRevision: oldConcept.revision,
          );
        }
      }

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
