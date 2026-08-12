import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';

import 'store_resolver.dart';

/// Saves or updates an entity in the world model.
///
/// If an `id` is provided and the entity already exists, it is updated (preserving `createdAt`). If the entity does
/// not exist or no `id` is given, a new entity is created.
Future<String> handleRemember(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String? ?? '';
  final String collection = args['collection'] as String;
  final String? id = args['id'] as String?;
  final Map<String, dynamic> data = args['data'] as Map<String, dynamic>;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);
  final DateTime now = DateTime.now().toUtc();
  final String entityId;
  final WorldModelEntity entity;

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store = await StoreResolver.createFirestoreStore(identity);

    if (id != null && id.isNotEmpty) {
      entityId = id;
      final Map<String, dynamic>? existing = await store.load(collection: collection, id: entityId);
      if (existing != null) {
        final WorldModelEntity original = WorldModelEntity.fromJson(existing);
        entity = WorldModelEntity(id: entityId, createdAt: original.createdAt, updatedAt: now, data: data);
        await store.update(collection: collection, entity: entity);
      } else {
        entity = WorldModelEntity(id: entityId, createdAt: now, updatedAt: now, data: data);
        await store.save(collection: collection, entity: entity);
      }
    } else {
      entityId = IdGenerator().generateShort();
      entity = WorldModelEntity(id: entityId, createdAt: now, updatedAt: now, data: data);
      await store.save(collection: collection, entity: entity);
    }
  } else {
    final EntityStore store = StoreResolver.createLocalStore(identity, projectPath);

    if (id != null && id.isNotEmpty) {
      entityId = id;
      final Map<String, dynamic>? existing = await store.load(collection: collection, id: entityId);
      if (existing != null) {
        final WorldModelEntity original = WorldModelEntity.fromJson(existing);
        entity = WorldModelEntity(id: entityId, createdAt: original.createdAt, updatedAt: now, data: data);
        await store.update(collection: collection, entity: entity);
      } else {
        entity = WorldModelEntity(id: entityId, createdAt: now, updatedAt: now, data: data);
        await store.save(collection: collection, entity: entity);
      }
    } else {
      entityId = IdGenerator().generateShort();
      entity = WorldModelEntity(id: entityId, createdAt: now, updatedAt: now, data: data);
      await store.save(collection: collection, entity: entity);
    }
  }

  return jsonEncode(<String, dynamic>{'status': 'saved', 'id': entityId, 'entity': entity.toJson()});
}

/// Retrieves entities from a collection in the world model.
///
/// If an `id` is provided, returns only that entity. Otherwise returns all entities in the collection sorted by
/// creation time (newest first).
Future<String> handleRecall(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String? ?? '';
  final String collection = args['collection'] as String;
  final String? id = args['id'] as String?;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store = await StoreResolver.createFirestoreStore(identity);

    if (id != null && id.isNotEmpty) {
      final Map<String, dynamic>? entityJson = await store.load(collection: collection, id: id);
      if (entityJson != null) {
        return jsonEncode(<String, dynamic>{'count': 1, 'entities': <Map<String, dynamic>>[entityJson]});
      }
      return jsonEncode(<String, dynamic>{'count': 0, 'entities': <Map<String, dynamic>>[]});
    }

    final List<Map<String, dynamic>> allJson = await store.listAll(collection: collection);
    final List<WorldModelEntity> entities = allJson.map(WorldModelEntity.fromJson).toList()
      ..sort((WorldModelEntity a, WorldModelEntity b) => b.createdAt.compareTo(a.createdAt));
    return jsonEncode(<String, dynamic>{
      'count': entities.length,
      'entities': entities.map((WorldModelEntity e) => e.toJson()).toList(),
    });
  } else {
    final EntityStore store = StoreResolver.createLocalStore(identity, projectPath);

    if (id != null && id.isNotEmpty) {
      final Map<String, dynamic>? entityJson = await store.load(collection: collection, id: id);
      if (entityJson != null) {
        return jsonEncode(<String, dynamic>{'count': 1, 'entities': <Map<String, dynamic>>[entityJson]});
      }
      return jsonEncode(<String, dynamic>{'count': 0, 'entities': <Map<String, dynamic>>[]});
    }

    final List<Map<String, dynamic>> allJson = await store.listAll(collection: collection);
    final List<WorldModelEntity> entities = allJson.map(WorldModelEntity.fromJson).toList()
      ..sort((WorldModelEntity a, WorldModelEntity b) => b.createdAt.compareTo(a.createdAt));
    return jsonEncode(<String, dynamic>{
      'count': entities.length,
      'entities': entities.map((WorldModelEntity e) => e.toJson()).toList(),
    });
  }
}

/// Deletes an entity from the world model.
Future<String> handleForget(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String? ?? '';
  final String collection = args['collection'] as String;
  final String id = args['id'] as String;

  final ProjectIdentity identity = StoreResolver.readIdentity(projectPath);
  bool success;

  if (identity.storageMode == StorageMode.cloud) {
    final FirestoreEntityStore store = await StoreResolver.createFirestoreStore(identity);
    success = await store.delete(collection: collection, id: id);
  } else {
    final EntityStore store = StoreResolver.createLocalStore(identity, projectPath);
    success = await store.delete(collection: collection, id: id);
  }

  return jsonEncode(<String, dynamic>{'status': success ? 'deleted' : 'not_found', 'id': id});
}

/// Reads a file from the codebase (only works when running locally with filesystem access).
Future<String> handleInvestigate(Map<String, dynamic> args) async {
  final String projectPath = args['projectPath'] as String? ?? '';
  final String relativePath = args['relativePath'] as String;

  final File file = File(p.join(projectPath, relativePath));
  if (!file.existsSync()) {
    return jsonEncode(<String, dynamic>{'status': 'error', 'message': 'File not found: $relativePath'});
  }

  final String content = await file.readAsString();
  return jsonEncode(<String, dynamic>{'status': 'success', 'content': content});
}
