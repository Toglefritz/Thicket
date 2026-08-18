import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `remember` tool which saves or updates a JSON entity in a specified collection in the project's world
/// model.
///
/// Required arguments:
/// - `projectPath`: absolute path to the project root
/// - `collection`: target collection name
/// - `data`: JSON object containing the entity properties (must include a `summary` field)
///
/// Optional arguments:
/// - `id`: unique identifier. If provided, updates existing entity or creates it. If omitted, generates a new ID.
///
/// The `data` object must contain a `summary` field: a short natural-language description of what this entity
/// represents. This field is used by the search system to find relevant entries without loading every document.
McpTool rememberTool() {
  return McpTool(
    name: 'remember',
    description:
        'Stores a piece of durable knowledge about the project in the world model. '
        'Use this to record lessons, patterns, architectural insights, constraints, '
        'conventions, and decisions that would help a future agent work more effectively '
        'in this codebase. Do NOT use this to log task completions or record what you did — '
        'only record knowledge that transfers to future situations.\n\n'
        'If an ID is provided, updates the existing entity or creates it if absent. '
        'If no ID is provided, generates a new unique ID. '
        'The data object MUST include a "summary" field containing a short lesson-style '
        'description (e.g., "The routing layer uses a custom middleware chain because..." '
        'rather than "I added a route for the users endpoint").',
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
              'The knowledge category to store this in (e.g., "architecture", "conventions", '
              '"decisions", "gotchas", "dependencies", "workflows").',
        },
        'id': <String, String>{
          'type': 'string',
          'description':
              'Optional identifier of the entity to create or update. If omitted, a new ID is generated.',
        },
        'data': <String, String>{
          'type': 'object',
          'description':
              'The flexible JSON payload containing the entity properties. '
              'Must include a "summary" field with a short natural-language description of this entity.',
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

      // Validate that the data payload includes a summary field.
      final String? summary = data['summary'] as String?;
      if (summary == null || summary.trim().isEmpty) {
        throw ArgumentError(
          'The "data" object must include a non-empty "summary" field. '
          'This field is required for search indexing.',
        );
      }

      // Resolve the project identity and select the appropriate storage backend.
      final ProjectIdentity identity = ProjectResolver.readIdentity(
        projectPath,
      );

      final DateTime now = DateTime.now().toUtc();
      final String entityId;
      final WorldModelEntity entity;

      if (identity.storageMode == StorageMode.cloud) {
        final FirestoreEntityStore store = ProjectResolver.createFirestoreStore(
          identity,
        );

        if (id != null && id.isNotEmpty) {
          entityId = id;
          final Map<String, dynamic>? existing = await store.load(
            collection: collection,
            id: entityId,
          );

          if (existing != null) {
            final WorldModelEntity original = WorldModelEntity.fromJson(
              existing,
            );
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
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          identity,
          projectPath,
        );
        if (storagePath == null) {
          throw StateError('Could not resolve local storage path for project.');
        }
        final EntityStore store = EntityStore(storagePath: storagePath);

        if (id != null && id.isNotEmpty) {
          entityId = id;
          final Map<String, dynamic>? existing = await store.load(
            collection: collection,
            id: entityId,
          );

          if (existing != null) {
            final WorldModelEntity original = WorldModelEntity.fromJson(
              existing,
            );
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
      }

      return <String, dynamic>{
        'status': 'saved',
        'id': entityId,
        'entity': entity.toJson(),
      };
    },
  );
}
