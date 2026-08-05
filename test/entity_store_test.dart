import 'dart:io';

import 'package:test/test.dart';
import 'package:thicket/src/models/experience/episode.dart';
import 'package:thicket/src/storage/entity_store.dart';
import 'package:thicket/src/storage/revision_conflict_exception.dart';

void main() {
  late EntityStore store;
  const String testPath = '/tmp/thicket-store-test';

  setUp(() {
    store = EntityStore(storagePath: testPath);
  });

  tearDown(() {
    final Directory dir = Directory(testPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('save and load an episode', () async {
    final Episode episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.constraintDiscovered,
      summary: 'Auth tokens must be refreshed',
      content: 'Discovered that the token service requires proactive refresh.',
      relatedPaths: ['lib/src/auth/token_service.dart'],
      tags: ['auth'],
    );

    await store.save(collection: 'episodes', entity: episode);

    final Map<String, dynamic>? loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );

    expect(loaded, isNotNull);
    expect(loaded!['summary'], equals('Auth tokens must be refreshed'));
    expect(loaded['kind'], equals('constraintDiscovered'));
    expect(loaded['relatedPaths'], contains('lib/src/auth/token_service.dart'));
  });

  test('listAll returns all entities in a collection', () async {
    final Episode first = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.taskPerformed,
      summary: 'First episode',
      content: 'Content one.',
    );

    final Episode second = Episode(
      id: 'ep-002',
      createdAt: DateTime.utc(2025, 1, 2),
      updatedAt: DateTime.utc(2025, 1, 2),
      revision: 1,
      kind: EpisodeKind.observation,
      summary: 'Second episode',
      content: 'Content two.',
    );

    await store.save(collection: 'episodes', entity: first);
    await store.save(collection: 'episodes', entity: second);

    final List<Map<String, dynamic>> all = await store.listAll(
      collection: 'episodes',
    );

    expect(all.length, equals(2));
  });

  test('save throws RevisionConflictException on duplicate', () async {
    final Episode episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.taskPerformed,
      summary: 'An episode',
      content: 'Content.',
    );

    await store.save(collection: 'episodes', entity: episode);

    expect(
      () => store.save(collection: 'episodes', entity: episode),
      throwsA(isA<RevisionConflictException>()),
    );
  });

  test('update succeeds with matching revision', () async {
    final Episode original = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.taskPerformed,
      summary: 'Original summary',
      content: 'Original content.',
    );

    await store.save(collection: 'episodes', entity: original);

    final Episode updated = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 2),
      revision: 2,
      kind: EpisodeKind.taskPerformed,
      summary: 'Updated summary',
      content: 'Updated content.',
    );

    await store.update(
      collection: 'episodes',
      entity: updated,
      expectedRevision: 1,
    );

    final Map<String, dynamic>? loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );

    expect(loaded!['summary'], equals('Updated summary'));
    expect(loaded['revision'], equals(2));
  });

  test('update throws RevisionConflictException on mismatch', () async {
    final Episode episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.taskPerformed,
      summary: 'An episode',
      content: 'Content.',
    );

    await store.save(collection: 'episodes', entity: episode);

    final Episode staleUpdate = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 2),
      revision: 3,
      kind: EpisodeKind.taskPerformed,
      summary: 'Stale update',
      content: 'Should fail.',
    );

    expect(
      () => store.update(
        collection: 'episodes',
        entity: staleUpdate,
        expectedRevision: 2,
      ),
      throwsA(isA<RevisionConflictException>()),
    );
  });

  test('delete removes entity and returns true', () async {
    final Episode episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      revision: 1,
      kind: EpisodeKind.taskPerformed,
      summary: 'To delete',
      content: 'Content.',
    );

    await store.save(collection: 'episodes', entity: episode);

    final bool result = await store.delete(
      collection: 'episodes',
      id: 'ep-001',
    );
    expect(result, isTrue);

    final Map<String, dynamic>? loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );
    expect(loaded, isNull);
  });

  test('delete returns false for nonexistent entity', () async {
    final bool result = await store.delete(
      collection: 'episodes',
      id: 'nonexistent',
    );
    expect(result, isFalse);
  });

  test('load returns null for nonexistent entity', () async {
    final Map<String, dynamic>? loaded = await store.load(
      collection: 'episodes',
      id: 'nonexistent',
    );
    expect(loaded, isNull);
  });
}
