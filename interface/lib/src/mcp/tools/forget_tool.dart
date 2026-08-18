import 'package:thicket/thicket.dart';
import '../mcp_tool.dart';
import 'project_resolver.dart';

/// Creates the `forget` tool which deletes a specified entity from a collection.
McpTool forgetTool() {
  return McpTool(
    name: 'forget',
    description:
        'Deletes a JSON entity from a specified collection in the project world model.',
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
              'The knowledge category (e.g., "architecture", "conventions", "decisions", "gotchas").',
        },
        'id': <String, String>{
          'type': 'string',
          'description': 'The identifier of the entity to delete.',
        },
      },
      'required': <String>['projectPath', 'collection', 'id'],
    },
    handler: (Map<String, dynamic> arguments) async {
      final String projectPath = arguments['projectPath'] as String;
      final String collection = arguments['collection'] as String;
      final String id = arguments['id'] as String;

      // Resolve the project identity and select the appropriate storage backend.
      final ProjectIdentity identity = ProjectResolver.readIdentity(
        projectPath,
      );
      bool success;

      if (identity.storageMode == StorageMode.cloud) {
        final FirestoreEntityStore store = ProjectResolver.createFirestoreStore(
          identity,
        );
        success = await store.delete(collection: collection, id: id);
      } else {
        final String? storagePath = ProjectResolver.resolveLocalStoragePath(
          identity,
          projectPath,
        );
        if (storagePath == null) {
          throw StateError('Could not resolve local storage path for project.');
        }
        final EntityStore store = EntityStore(storagePath: storagePath);
        success = await store.delete(collection: collection, id: id);
      }

      return <String, dynamic>{
        'status': success ? 'deleted' : 'not_found',
        'id': id,
      };
    },
  );
}
