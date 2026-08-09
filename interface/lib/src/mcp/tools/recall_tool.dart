import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `recall` tool which retrieves entities from a specified collection in the project's world model.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `collection`: target collection name
///
/// Optional arguments:
/// - `id`: unique identifier of a specific entity to retrieve. If omitted, returns all entities in the collection.
McpTool recallTool() {
  return McpTool(
    name: 'recall',
    description:
        'Retrieves entities from a specified collection in the project world model. '
        'If an ID is provided, retrieves only the specific entity with that ID. '
        'If no ID is provided, lists all entities in the collection, sorted by creation date (newest first).',
    inputSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, Map<String, String>>{
        'projectPath': <String, String>{
          'type': 'string',
          'description': 'Absolute path to the root directory of the project.',
        },
        'collection': <String, String>{
          'type': 'string',
          'description':
              'The name of the collection (e.g., "experiences", "beliefs", "concepts").',
        },
        'id': <String, String>{
          'type': 'string',
          'description':
              'Optional identifier of a specific entity to retrieve.',
        },
      },
      'required': <String>['projectPath', 'collection'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String collection = arguments['collection'] as String;
      final String? id = arguments['id'] as String?;

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(
        projectPath,
      );
      final EntityStore store = EntityStore(storagePath: storagePath);

      if (id != null && id.isNotEmpty) {
        final Map<String, dynamic>? entityJson = await store.load(
          collection: collection,
          id: id,
        );

        if (entityJson != null) {
          final WorldModelEntity entity = WorldModelEntity.fromJson(entityJson);
          return <String, dynamic>{
            'count': 1,
            'entities': <Map<String, dynamic>>[entity.toJson()],
          };
        } else {
          return <String, dynamic>{
            'count': 0,
            'entities': <Map<String, dynamic>>[],
          };
        }
      } else {
        final List<Map<String, dynamic>> allJson = await store.listAll(
          collection: collection,
        );

        final List<WorldModelEntity> entities = allJson
            .map(WorldModelEntity.fromJson)
            .toList();

        // Sort by creation time, most recent first.
        entities.sort(
          (WorldModelEntity a, WorldModelEntity b) =>
              b.createdAt.compareTo(a.createdAt),
        );

        return <String, dynamic>{
          'count': entities.length,
          'entities': entities.map((WorldModelEntity e) => e.toJson()).toList(),
        };
      }
    },
  );
}
