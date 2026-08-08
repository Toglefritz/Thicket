import 'package:thicket/thicket.dart';
import 'package:thicket/src/utils/id_generator.dart';
import 'package:test/test.dart';

void main() {
  group('IdGenerator', () {
    test('generate returns adjective-noun-hex format', () {
      final generator = IdGenerator();
      final id = generator.generate();
      expect(id, matches(RegExp(r'^[a-z]+-[a-z]+-[0-9a-f]{4}$')));
    });

    test('generateShort returns short hex format of default length', () {
      final generator = IdGenerator();
      final id = generator.generateShort();
      expect(id, matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('generateShort returns short hex format of custom length', () {
      final generator = IdGenerator();
      final id = generator.generateShort(length: 12);
      expect(id, matches(RegExp(r'^[0-9a-f]{12}$')));
    });
  });
  group('WorldModelEntity', () {
    test('round-trips through JSON', () {
      final now = DateTime.utc(2025, 1, 1);
      final entity = WorldModelEntity(id: 'test-id', createdAt: now, updatedAt: now, revision: 1);

      final json = entity.toJson();
      final restored = WorldModelEntity.fromJson(json);

      expect(restored.id, equals('test-id'));
      expect(restored.createdAt, equals(now));
      expect(restored.updatedAt, equals(now));
      expect(restored.revision, equals(1));
    });
  });

  group('ProjectIdentity', () {
    test('round-trips through JSON', () {
      final now = DateTime.utc(2025, 1, 1);
      final identity = ProjectIdentity(projectId: 'abc-123', projectName: 'My Project', createdAt: now);

      final json = identity.toJson();
      final restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
    });
  });
}
