import '../../models/knowledge/belief.dart';
import '../../storage/entity_store.dart';
import '../../utils/id_generator.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `learn` tool which records a belief in the project's world model.
///
/// This is the primary write path for the knowledge layer. When an agent forms or revises a persistent understanding
/// about the software system (based on evidence from episodes or direct observation), it calls this tool to persist
/// that belief for future sessions.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `claim`: concise statement of what the agent believes
/// - `rationale`: explanation of why the agent holds this belief
/// - `confidence`: 0.0 to 1.0, how confident the agent is
///
/// Optional arguments:
/// - `supportingEpisodeIds`: episode IDs that provide evidence
/// - `supersededBeliefIds`: belief IDs this belief replaces
/// - `relatedPaths`: file paths relevant to this belief
/// - `tags`: free-form tags for categorization
McpTool learnTool() {
  return McpTool(
    name: 'learn',
    description:
        'Records a belief about the software system in the project world model. '
        'Use this when you form a persistent understanding worth preserving: '
        'which components own which responsibilities, which patterns are used, '
        'which approaches to avoid, which areas are fragile, or which '
        'dependencies exist between subsystems.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'projectPath': {
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'claim': {
          'type': 'string',
          'description': 'A concise statement of what the agent believes to be true about the system.',
        },
        'rationale': {
          'type': 'string',
          'description': 'An explanation providing context, reasoning, or justification for this belief.',
        },
        'confidence': {
          'type': 'number',
          'description':
              'How confident the agent is in this belief, from 0.0 (no confidence) to 1.0 (fully confident).',
          'minimum': 0.0,
          'maximum': 1.0,
        },
        'supportingEpisodeIds': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Identifiers of episodes that provide evidence for this belief. '
              'Maintains provenance by linking beliefs back to concrete experiences.',
        },
        'supersededBeliefIds': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Identifiers of older beliefs that this belief replaces. '
              'The superseded beliefs will be marked as such for traceability.',
        },
        'relatedPaths': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'File paths or identifiers relevant to this belief. '
              'Used as anchors for retrieval when working in the same area.',
        },
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Free-form tags for additional categorization and retrieval.',
        },
      },
      'required': ['projectPath', 'claim', 'rationale', 'confidence'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String claim = arguments['claim'] as String;
      final String rationale = arguments['rationale'] as String;
      final double confidence = (arguments['confidence'] is String)
          ? double.parse(arguments['confidence'] as String)
          : (arguments['confidence'] as num).toDouble();
      final List<String> supportingEpisodeIds =
          (arguments['supportingEpisodeIds'] as List<dynamic>?)?.cast<String>() ?? [];
      final List<String> supersededBeliefIds =
          (arguments['supersededBeliefIds'] as List<dynamic>?)?.cast<String>() ?? [];
      final List<String> relatedPaths = (arguments['relatedPaths'] as List<dynamic>?)?.cast<String>() ?? [];
      final List<String> tags = (arguments['tags'] as List<dynamic>?)?.cast<String>() ?? [];

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(
        projectPath,
      );
      final EntityStore store = EntityStore(storagePath: storagePath);

      // Generate a unique ID for this belief.
      final IdGenerator generator = IdGenerator();
      final String beliefId = generator.generate();

      // Create the belief entity.
      final DateTime now = DateTime.now().toUtc();
      final Belief belief = Belief(
        id: beliefId,
        createdAt: now,
        updatedAt: now,
        revision: 1,
        claim: claim,
        rationale: rationale,
        confidence: confidence,
        status: BeliefStatus.active,
        supportingEpisodeIds: supportingEpisodeIds,
        supersededBeliefIds: supersededBeliefIds,
        relatedPaths: relatedPaths,
        tags: tags,
      );

      // If this belief supersedes others, mark them as superseded.
      for (final String oldBeliefId in supersededBeliefIds) {
        final Map<String, dynamic>? existing = await store.load(
          collection: 'beliefs',
          id: oldBeliefId,
        );
        if (existing != null) {
          final Belief oldBelief = Belief.fromJson(existing);
          final Belief updatedOld = Belief(
            id: oldBelief.id,
            createdAt: oldBelief.createdAt,
            updatedAt: now,
            revision: oldBelief.revision + 1,
            claim: oldBelief.claim,
            rationale: oldBelief.rationale,
            confidence: oldBelief.confidence,
            status: BeliefStatus.superseded,
            supportingEpisodeIds: oldBelief.supportingEpisodeIds,
            supersededBeliefIds: oldBelief.supersededBeliefIds,
            relatedPaths: oldBelief.relatedPaths,
            tags: oldBelief.tags,
          );
          await store.update(
            collection: 'beliefs',
            entity: updatedOld,
            expectedRevision: oldBelief.revision,
          );
        }
      }

      // Persist the new belief.
      await store.save(collection: 'beliefs', entity: belief);

      return {
        'status': 'learned',
        'beliefId': beliefId,
        'belief': belief.toJson(),
      };
    },
  );
}
