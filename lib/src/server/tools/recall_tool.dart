import '../../models/experience/episode.dart';
import '../../storage/entity_store.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `recall` tool which retrieves episodes from the project's world model.
///
/// This is the primary read path for the experience layer. When an agent begins work on a task, it calls this tool to
/// retrieve relevant prior experiences that may inform its approach.
///
/// Without any filter arguments, returns all episodes in the project. Optional filters narrow the results:
/// - `kind`: return only episodes of a specific category
/// - `tags`: return episodes that contain any of the specified tags
/// - `relatedPaths`: return episodes related to any of the specified file paths
///
/// Results are returned in reverse chronological order (most recent first).
McpTool recallTool() {
  return McpTool(
    name: 'recall',
    description:
        'Retrieves episodes from the project world model. Use this at the start of a task to recall relevant prior '
        'experiences: constraints discovered, approaches that failed, debugging outcomes, and other knowledge '
        'accumulated in previous sessions. Supports optional filtering by kind, tags, or related file paths.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'projectPath': {
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'kind': {
          'type': 'string',
          'description': 'Filter to only episodes of this category.',
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
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Filter to episodes containing any of these tags.',
        },
        'relatedPaths': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'Filter to episodes related to any of these file paths.',
        },
      },
      'required': ['projectPath'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String? kindFilter = arguments['kind'] as String?;
      final List<String>? tagsFilter = (arguments['tags'] as List<dynamic>?)
          ?.cast<String>();
      final List<String>? pathsFilter =
          (arguments['relatedPaths'] as List<dynamic>?)?.cast<String>();

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(
        projectPath,
      );
      final EntityStore store = EntityStore(storagePath: storagePath);

      // Load all episodes from the store.
      final List<Map<String, dynamic>> allEpisodes = await store.listAll(
        collection: 'episodes',
      );

      // Deserialize into typed episodes for filtering.
      List<Episode> episodes = allEpisodes
          .map((Map<String, dynamic> json) => Episode.fromJson(json))
          .toList();

      // Apply kind filter.
      if (kindFilter != null) {
        final EpisodeKind kind = EpisodeKind.values.byName(kindFilter);
        episodes = episodes.where((Episode ep) => ep.kind == kind).toList();
      }

      // Apply tags filter (match any).
      if (tagsFilter != null && tagsFilter.isNotEmpty) {
        episodes = episodes
            .where(
              (Episode ep) =>
                  ep.tags.any((String tag) => tagsFilter.contains(tag)),
            )
            .toList();
      }

      // Apply related paths filter (match any).
      if (pathsFilter != null && pathsFilter.isNotEmpty) {
        episodes = episodes
            .where(
              (Episode ep) => ep.relatedPaths.any(
                (String path) => pathsFilter.contains(path),
              ),
            )
            .toList();
      }

      // Sort by creation time, most recent first.
      episodes.sort(
        (Episode a, Episode b) => b.createdAt.compareTo(a.createdAt),
      );

      return {
        'count': episodes.length,
        'episodes': episodes.map((Episode ep) => ep.toJson()).toList(),
      };
    },
  );
}
