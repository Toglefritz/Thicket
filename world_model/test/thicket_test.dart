import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:thicket/thicket.dart';
import 'package:thicket/src/utils/id_generator.dart';
import 'package:thicket/src/server/tools/project_resolver.dart';
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
      final entity = WorldModelEntity(id: 'test-id', createdAt: now, updatedAt: now);

      final json = entity.toJson();
      final restored = WorldModelEntity.fromJson(json);

      expect(restored.id, equals('test-id'));
      expect(restored.createdAt, equals(now));
      expect(restored.updatedAt, equals(now));
    });
  });

  group('ProjectIdentity', () {
    test('round-trips through JSON with defaults', () {
      final now = DateTime.utc(2025, 1, 1);
      final identity = ProjectIdentity(projectId: 'abc-123', projectName: 'My Project', createdAt: now);

      final json = identity.toJson();
      final restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
      expect(restored.storageMode, equals('centralized'));
    });

    test('round-trips through JSON with inRepo storageMode', () {
      final now = DateTime.utc(2025, 1, 1);
      final identity = ProjectIdentity(
        projectId: 'abc-123',
        projectName: 'My Project',
        createdAt: now,
        storageMode: 'inRepo',
      );

      final json = identity.toJson();
      final restored = ProjectIdentity.fromJson(json);

      expect(restored.projectId, equals('abc-123'));
      expect(restored.projectName, equals('My Project'));
      expect(restored.createdAt, equals(now));
      expect(restored.storageMode, equals('inRepo'));
    });
  });

  group('ProjectResolver', () {
    test('getHomeDirectory returns a value', () {
      final home = ProjectResolver.getHomeDirectory();
      expect(home, isNotEmpty);
    });

    test('resolveStoragePath resolves centralized mode', () {
      final tempDir = Directory.systemTemp.createTempSync('thicket-test-centralized');
      try {
        final thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-123",
  "projectName": "Test Project",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "storageMode": "centralized"
}
''');

        final resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        final home = ProjectResolver.getHomeDirectory();
        expect(resolved, equals(p.join(home, '.thicket', 'projects', 'test-project-123')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveStoragePath resolves inRepo mode', () {
      final tempDir = Directory.systemTemp.createTempSync('thicket-test-inrepo');
      try {
        final thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-456",
  "projectName": "Test Project 2",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "storageMode": "inRepo"
}
''');

        final resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        expect(resolved, equals(p.join(tempDir.path, '.thicket', 'world_model')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveStoragePath defaults to centralized if storageMode missing', () {
      final tempDir = Directory.systemTemp.createTempSync('thicket-test-missing');
      try {
        final thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-789",
  "projectName": "Test Project 3",
  "createdAt": "2025-01-01T00:00:00.000Z"
}
''');

        final resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        final home = ProjectResolver.getHomeDirectory();
        expect(resolved, equals(p.join(home, '.thicket', 'projects', 'test-project-789')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
