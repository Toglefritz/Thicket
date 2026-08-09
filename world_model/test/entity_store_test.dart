import 'dart:io';

import 'package:test/test.dart';
import 'package:thicket/thicket.dart';

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

  test('save and load an entity', () async {
    final entity = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      data: const <String, dynamic>{
        'summary': 'Auth tokens must be refreshed',
        'kind': 'constraintDiscovered',
      },
    );

    await store.save(collection: 'entities', entity: entity);

    final loaded = await store.load(
      collection: 'entities',
      id: 'ent-001',
    );

    expect(loaded, isNotNull);
    expect(loaded!['summary'], equals('Auth tokens must be refreshed'));
    expect(loaded['kind'], equals('constraintDiscovered'));
  });

  test('listAll returns all entities in a collection', () async {
    final first = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      data: const <String, dynamic>{
        'val': 'one',
      },
    );

    final second = WorldModelEntity(
      id: 'ent-002',
      createdAt: DateTime.utc(2025, 1, 2),
      updatedAt: DateTime.utc(2025, 1, 2),
      data: const <String, dynamic>{
        'val': 'two',
      },
    );

    await store.save(collection: 'entities', entity: first);
    await store.save(collection: 'entities', entity: second);

    final all = await store.listAll(
      collection: 'entities',
    );

    expect(all.length, equals(2));
  });

  test('save throws StateError on duplicate', () async {
    final entity = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      data: const <String, dynamic>{
        'val': 'test',
      },
    );

    await store.save(collection: 'entities', entity: entity);

    expect(
      () => store.save(collection: 'entities', entity: entity),
      throwsA(isA<StateError>()),
    );
  });

  test('update succeeds', () async {
    final original = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      data: const <String, dynamic>{
        'summary': 'Original summary',
      },
    );

    await store.save(collection: 'entities', entity: original);

    final updated = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025, 1, 2),
      data: const <String, dynamic>{
        'summary': 'Updated summary',
      },
    );

    await store.update(
      collection: 'entities',
      entity: updated,
    );

    final loaded = await store.load(
      collection: 'entities',
      id: 'ent-001',
    );

    expect(loaded!['summary'], equals('Updated summary'));
  });

  test('delete removes entity and returns true', () async {
    final entity = WorldModelEntity(
      id: 'ent-001',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      data: const <String, dynamic>{
        'val': 'to delete',
      },
    );

    await store.save(collection: 'entities', entity: entity);

    final result = await store.delete(
      collection: 'entities',
      id: 'ent-001',
    );
    expect(result, isTrue);

    final loaded = await store.load(
      collection: 'entities',
      id: 'ent-001',
    );
    expect(loaded, isNull);
  });

  test('delete returns false for nonexistent entity', () async {
    final result = await store.delete(
      collection: 'entities',
      id: 'nonexistent',
    );
    expect(result, isFalse);
  });

  test('load returns null for nonexistent entity', () async {
    final loaded = await store.load(
      collection: 'entities',
      id: 'nonexistent',
    );
    expect(loaded, isNull);
  });
}
