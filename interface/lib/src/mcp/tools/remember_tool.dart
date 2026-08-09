import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `remember` tool which saves or updates a JSON entity in a specified collection in the project's world
/// model.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `collection`: target collection name
/// - `data`: JSON object containing the entity properties
///
/// Optional arguments:
/// - `id`: unique identifier. If provided, updates existing entity or creates it. If omitted, generates a new ID.
McpTool rememberTool() {
  return McpTool(
    name: 'remember',
    description:
        'Saves or updates a JSON entity in a specified collection in the project world model. '
        'If an ID is provided, updates the existing entity or creates it if absent. '
        'If no ID is provided, generates a new unique ID and saves the entity.',
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
              'Optional identifier of the entity to create or update. If omitted, a new ID is generated.',
        },
        'data': <String, String>{
          'type': 'object',
          'description':
              'The flexible JSON payload containing the entity properties.',
        },
      },
      'required': <String>['projectPath', 'collection', 'data'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String collection = arguments['collection'] as String;
      final String? id = arguments['id'] as String?;
      final Map<String, dynamic> data =
          arguments['data'] as Map<String, dynamic>;

      // Resolve the project's storage directory.
      final String storagePath = ProjectResolver.resolveStoragePath(
        projectPath,
      );
      final EntityStore store = EntityStore(storagePath: storagePath);

      final DateTime now = DateTime.now().toUtc();
      final String entityId;
      final WorldModelEntity entity;

      if (id != null && id.isNotEmpty) {
        entityId = id;
        final Map<String, dynamic>? existing = await store.load(
          collection: collection,
          id: entityId,
        );

        if (existing != null) {
          final WorldModelEntity original = WorldModelEntity.fromJson(existing);
          entity = WorldModelEntity(
            id: entityId,
            createdAt: original.createdAt,
            updatedAt: now,
            data: data,
          );
          await store.update(collection: collection, entity: entity);
        } else {
          entity = WorldModelEntity(
            id: entityId,
            createdAt: now,
            updatedAt: now,
            data: data,
          );
          await store.save(collection: collection, entity: entity);
        }
      } else {
        final IdGenerator generator = IdGenerator();
        entityId = generator.generateShort();
        entity = WorldModelEntity(
          id: entityId,
          createdAt: now,
          updatedAt: now,
          data: data,
        );
        await store.save(collection: collection, entity: entity);
      }

      return <String, dynamic>{
        'status': 'saved',
        'id': entityId,
        'entity': entity.toJson(),
      };
    },
  );
}
