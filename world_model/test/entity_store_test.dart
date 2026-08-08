import 'dart:io';

import 'package:test/test.dart';
import 'package:thicket/src/models/experience/episode.dart';
import 'package:thicket/src/storage/entity_store.dart';

void main() {
  late EntityStore store;
  const testPath = '/tmp/thicket-store-test';

  setUp(() {
    store = EntityStore(storagePath: testPath);
  });

  tearDown(() {
    final dir = Directory(testPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('save and load an episode', () async {
    final episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      kind: EpisodeKind.constraintDiscovered,
      summary: 'Auth tokens must be refreshed',
      content: 'Discovered that the token service requires proactive refresh.',
    );

    await store.save(collection: 'episodes', entity: episode);

    final loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );

    expect(loaded, isNotNull);
    expect(loaded!['summary'], equals('Auth tokens must be refreshed'));
    expect(loaded['kind'], equals('constraintDiscovered'));
  });

  test('listAll returns all entities in a collection', () async {
    final first = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      kind: EpisodeKind.taskPerformed,
      summary: 'First episode',
      content: 'Content one.',
    );

    final second = Episode(
      id: 'ep-002',
      createdAt: DateTime.utc(2025, 1, 2),
      updatedAt: DateTime.utc(2025, 1, 2),
      kind: EpisodeKind.observation,
      summary: 'Second episode',
      content: 'Content two.',
    );

    await store.save(collection: 'episodes', entity: first);
    await store.save(collection: 'episodes', entity: second);

    final all = await store.listAll(
      collection: 'episodes',
    );

    expect(all.length, equals(2));
  });

  test('save throws StateError on duplicate', () async {
    final episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      kind: EpisodeKind.taskPerformed,
      summary: 'An episode',
      content: 'Content.',
    );

    await store.save(collection: 'episodes', entity: episode);

    expect(
      () => store.save(collection: 'episodes', entity: episode),
      throwsA(isA<StateError>()),
    );
  });

  test('update succeeds', () async {
    final original = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      kind: EpisodeKind.taskPerformed,
      summary: 'Original summary',
      content: 'Original content.',
    );

    await store.save(collection: 'episodes', entity: original);

    final updated = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025, 1, 2),
      kind: EpisodeKind.taskPerformed,
      summary: 'Updated summary',
      content: 'Updated content.',
    );

    await store.update(
      collection: 'episodes',
      entity: updated,
    );

    final loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );

    expect(loaded!['summary'], equals('Updated summary'));
  });

  test('delete removes entity and returns true', () async {
    final episode = Episode(
      id: 'ep-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      kind: EpisodeKind.taskPerformed,
      summary: 'To delete',
      content: 'Content.',
    );

    await store.save(collection: 'episodes', entity: episode);

    final result = await store.delete(
      collection: 'episodes',
      id: 'ep-001',
    );
    expect(result, isTrue);

    final loaded = await store.load(
      collection: 'episodes',
      id: 'ep-001',
    );
    expect(loaded, isNull);
  });

  test('delete returns false for nonexistent entity', () async {
    final result = await store.delete(
      collection: 'episodes',
      id: 'nonexistent',
    );
    expect(result, isFalse);
  });

  test('load returns null for nonexistent entity', () async {
    final loaded = await store.load(
      collection: 'episodes',
      id: 'nonexistent',
    );
    expect(loaded, isNull);
  });
}
