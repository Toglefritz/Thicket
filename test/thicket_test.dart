import 'package:thicket/thicket.dart';
import 'package:test/test.dart';

void main() {
  group('WorldModelEntity', () {
    test('round-trips through JSON', () {
      final now = DateTime.utc(2025, 1, 1);
      final entity = WorldModelEntity(
        id: 'test-id',
        createdAt: now,
        updatedAt: now,
        revision: 1,
      );

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
      final identity = ProjectIdentity(
        projectId: 'abc-123',
        projectName: 'My Project',
        createdAt: now,
      );

      final json = identity.toJson();
      final restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
    });
  });
}
