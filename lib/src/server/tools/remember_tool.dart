import '../../models/experience/episode.dart';
import '../../storage/entity_store.dart';
import '../../utils/id_generator.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `remember` tool which records a significant experience as an episode in the project's world model.
///
/// This is the primary write path for the experience layer. When an agent encounters something worth preserving (a
/// discovered constraint, a failed approach, a debugging outcome), it calls this tool to persist that knowledge for
/// future sessions.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `kind`: one of the [EpisodeKind] enum values
/// - `summary`: concise description of the experience
/// - `content`: full description with context and reasoning
///
/// Optional arguments:
/// - `relatedPaths`: list of file paths relevant to this experience
/// - `tags`: list of free-form tags for categorization
McpTool rememberTool() {
  return McpTool(
    name: 'remember',
    description:
        'Records a significant experience as an episode in the project world model. Use this when you discover '
        'something worth preserving for future sessions: architectural constraints, failed approaches, debugging '
        'outcomes, unexpected interactions, or important task results.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'projectPath': {
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'kind': {
          'type': 'string',
          'description': 'The category of experience being recorded.',
          'enum': [
            'taskPerformed',
            'constraintDiscovered',
            'approachFailed',
            'implementationRejected',
            'unexpectedInteraction',
            'debuggingOutcome',
            'observation',
          ],
        },
        'summary': {
          'type': 'string',
          'description':
              'A concise summary of the experience. Should be brief enough to be useful in retrieval results without '
              'reading the full content.',
        },
        'content': {
          'type': 'string',
          'description':
              'The full description of the experience, including relevant context, reasoning, and outcome.',
        },
        'relatedPaths': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'File paths or identifiers relevant to this experience. Used as anchors for retrieval when working in '
              'the same area.',
        },
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Free-form tags for additional categorization and retrieval.',
        },
      },
      'required': ['projectPath', 'kind', 'summary', 'content'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String kindStr = arguments['kind'] as String;
      final String summary = arguments['summary'] as String;
      final String content = arguments['content'] as String;
      final List<String> relatedPaths = (arguments['relatedPaths'] as List<dynamic>?)?.cast<String>() ?? [];
      final List<String> tags = (arguments['tags'] as List<dynamic>?)?.cast<String>() ?? [];

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(projectPath);

      // Generate a unique ID for this episode.
      final IdGenerator generator = IdGenerator();
      final String episodeId = generator.generate();

      // Parse the episode kind.
      final EpisodeKind kind = EpisodeKind.values.byName(kindStr);

      // Create the episode entity.
      final DateTime now = DateTime.now().toUtc();
      final Episode episode = Episode(
        id: episodeId,
        createdAt: now,
        updatedAt: now,
        revision: 1,
        kind: kind,
        summary: summary,
        content: content,
        relatedPaths: relatedPaths,
        tags: tags,
      );

      // Persist to the store.
      final EntityStore store = EntityStore(storagePath: storagePath);
      await store.save(collection: 'episodes', entity: episode);

      return {
        'status': 'recorded',
        'episodeId': episodeId,
        'episode': episode.toJson(),
      };
    },
  );
}
