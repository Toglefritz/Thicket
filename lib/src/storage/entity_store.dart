import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/core/world_model_entity.dart';
import 'revision_conflict_exception.dart';

/// Persists and retrieves world model entities as JSON files on the local filesystem.
///
/// Each entity type is stored in its own subdirectory under the project's storage root (e.g.
/// `~/.thicket/projects/<id>/episodes/`). Each entity occupies a single JSON file named by its ID.
///
/// This store enforces optimistic concurrency through revision checking: when updating an existing entity, the revision
/// on disk must match the expected previous revision. This prevents silent overwrites when two processes modify the
/// same entity.
class EntityStore {
  /// The root directory for this project's world model storage.
  ///
  /// Typically `~/.thicket/projects/<project-id>/`.
  final Directory _storageRoot;

  /// JSON encoder configured for human-readable output.
  ///
  /// Two-space indentation keeps the stored files easy to inspect during development and debugging.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Creates a store rooted at the given directory path.
  ///
  /// The directory does not need to exist yet; it will be created on the first write operation.
  EntityStore({required String storagePath}) : _storageRoot = Directory(storagePath);

  /// Saves a new entity to disk.
  ///
  /// The entity is written to `<storageRoot>/<collection>/<id>.json`. If a file already exists at that path, a
  /// [RevisionConflictException] is thrown to prevent accidental overwrites. Use [update] for modifying existing
  /// entities.
  ///
  /// The [collection] parameter determines the subdirectory (e.g. "episodes", "beliefs", "concepts").
  Future<void> save({
    required String collection,
    required WorldModelEntity entity,
  }) async {
    final File file = _fileFor(collection, entity.id);

    if (file.existsSync()) {
      final Map<String, dynamic> existing = _readJsonFile(file);
      final int existingRevision = existing['revision'] as int;

      throw RevisionConflictException(
        entityId: entity.id,
        currentRevision: existingRevision,
        expectedRevision: 0,
      );
    }

    _writeJsonFile(file, entity.toJson());
  }

  /// Updates an existing entity on disk.
  ///
  /// Before writing, the current file is read and its revision number is compared against [expectedRevision]. If they
  /// do not match, a [RevisionConflictException] is thrown.
  ///
  /// The caller is responsible for incrementing the entity's revision and updating its `updatedAt` timestamp before
  /// calling this method.
  Future<void> update({
    required String collection,
    required WorldModelEntity entity,
    required int expectedRevision,
  }) async {
    final File file = _fileFor(collection, entity.id);

    if (!file.existsSync()) {
      throw StateError(
        'Cannot update entity "${entity.id}" in "$collection": file does not exist',
      );
    }

    final Map<String, dynamic> existing = _readJsonFile(file);
    final int currentRevision = existing['revision'] as int;

    if (currentRevision != expectedRevision) {
      throw RevisionConflictException(
        entityId: entity.id,
        currentRevision: currentRevision,
        expectedRevision: expectedRevision,
      );
    }

    _writeJsonFile(file, entity.toJson());
  }

  /// Loads a single entity by ID from the given collection.
  ///
  /// Returns null if no file exists for the given ID. The caller is responsible for deserializing the returned map into
  /// the appropriate typed entity using its `fromJson` factory.
  Future<Map<String, dynamic>?> load({
    required String collection,
    required String id,
  }) async {
    final File file = _fileFor(collection, id);

    if (!file.existsSync()) {
      return null;
    }

    return _readJsonFile(file);
  }

  /// Lists all entities in the given collection.
  ///
  /// Returns a list of deserialized JSON maps, one per entity file in the collection directory. The caller is
  /// responsible for converting these into typed entities.
  ///
  /// Returns an empty list if the collection directory does not exist.
  Future<List<Map<String, dynamic>>> listAll({
    required String collection,
  }) async {
    final Directory collectionDir = _collectionDir(collection);

    if (!collectionDir.existsSync()) {
      return [];
    }

    final List<Map<String, dynamic>> results = [];

    final List<FileSystemEntity> entities = collectionDir
        .listSync()
        .whereType<File>()
        .where((File file) => file.path.endsWith('.json'))
        .toList();

    for (final FileSystemEntity entity in entities) {
      final Map<String, dynamic> json = _readJsonFile(entity as File);
      results.add(json);
    }

    return results;
  }

  /// Deletes an entity file from disk.
  ///
  /// Returns true if the file existed and was deleted, false if it did not exist.
  Future<bool> delete({
    required String collection,
    required String id,
  }) async {
    final File file = _fileFor(collection, id);

    if (!file.existsSync()) {
      return false;
    }

    file.deleteSync();

    return true;
  }

  /// Resolves the file path for an entity within a collection.
  File _fileFor(String collection, String id) {
    return File(p.join(_storageRoot.path, collection, '$id.json'));
  }

  /// Resolves the directory for a given collection name.
  Directory _collectionDir(String collection) {
    return Directory(p.join(_storageRoot.path, collection));
  }

  /// Reads and decodes a JSON file from disk.
  Map<String, dynamic> _readJsonFile(File file) {
    final String contents = file.readAsStringSync();

    return jsonDecode(contents) as Map<String, dynamic>;
  }

  /// Encodes and writes a JSON map to disk, creating parent directories as needed.
  void _writeJsonFile(File file, Map<String, dynamic> json) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_encoder.convert(json));
  }
}
