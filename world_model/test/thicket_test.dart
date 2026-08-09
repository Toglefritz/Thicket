import 'package:test/test.dart';
import 'package:thicket/thicket.dart';

void main() {
  group('IdGenerator', () {
    test('generate returns adjective-noun-hex format', () {
      final IdGenerator generator = IdGenerator();
      final String id = generator.generate();
      expect(id, matches(RegExp(r'^[a-z\s]+-[a-z\s]+-[0-9a-f]{4}$')));
    });

    test('generateShort returns short hex format of default length', () {
      final IdGenerator generator = IdGenerator();
      final String id = generator.generateShort();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('generateShort returns short hex format of custom length', () {
      final IdGenerator generator = IdGenerator();
      final String id = generator.generateShort(length: 12);
      expect(id, matches(RegExp(r'^[0-9a-f]{12}$')));
    });
  });

  group('WorldModelEntity', () {
    test('round-trips through JSON', () {
      final DateTime now = DateTime.utc(2025);
      final WorldModelEntity entity = WorldModelEntity(
        id: 'test-id',
        createdAt: now,
        updatedAt: now,
        data: const <String, dynamic>{'field': 'value'},
      );

      final Map<String, dynamic> json = entity.toJson();
      final WorldModelEntity restored = WorldModelEntity.fromJson(json);

      expect(restored.id, equals('test-id'));
      expect(restored.createdAt, equals(now));
      expect(restored.updatedAt, equals(now));
      expect(restored.data['field'], equals('value'));
    });
  });

  group('ProjectIdentity', () {
    test('round-trips through JSON with defaults', () {
      final DateTime now = DateTime.utc(2025);
      final ProjectIdentity identity = ProjectIdentity(
        projectId: 'abc-123',
        projectName: 'My Project',
        createdAt: now,
      );

      final Map<String, dynamic> json = identity.toJson();
      final ProjectIdentity restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
      expect(restored.storageMode, equals(StorageMode.cloud));
    });

    test('round-trips through JSON with inRepo storageMode', () {
      final DateTime now = DateTime.utc(2025);
      final ProjectIdentity identity = ProjectIdentity(
        projectId: 'abc-123',
        projectName: 'My Project',
        createdAt: now,
        storageMode: StorageMode.inRepo,
      );

      final Map<String, dynamic> json = identity.toJson();
      final ProjectIdentity restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
      expect(restored.storageMode, equals(StorageMode.inRepo));
    });
  });
}
