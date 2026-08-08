import 'package:thicket/thicket.dart';
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
        'accumulated in previous sessions. Supports optional filtering by kind.',
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
      },
      'required': ['projectPath'],
    },
    handler: (arguments) async {
      final projectPath = arguments['projectPath'] as String;
      final kindFilter = arguments['kind'] as String?;

      // Resolve the project's storage directory.
      final storagePath = ProjectResolver.resolveStoragePath(
        projectPath,
      );
      final store = EntityStore(storagePath: storagePath);

      // Load all episodes from the store.
      final allEpisodes = await store.listAll(
        collection: 'episodes',
      );

      // Deserialize into typed episodes for filtering.
      var episodes = allEpisodes.map(Episode.fromJson).toList();

      // Apply kind filter.
      if (kindFilter != null) {
        final kind = EpisodeKind.values.byName(kindFilter);
        episodes = episodes.where((ep) => ep.kind == kind).toList();
      }

      // Sort by creation time, most recent first.
      episodes.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return {
        'count': episodes.length,
        'episodes': episodes.map((ep) => ep.toJson()).toList(),
      };
    },
  );
}
