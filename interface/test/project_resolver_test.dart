import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:thicket_interface/src/mcp/tools/project_resolver.dart';

void main() {
  group('ProjectResolver', () {
    test('getHomeDirectory returns a value', () {
      final String home = ProjectResolver.getHomeDirectory();
      expect(home, isNotEmpty);
    });

    test('resolveStoragePath resolves centralized mode', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('thicket-test-centralized');
      try {
        final Directory thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final File identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-123",
  "projectName": "Test Project",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "storageMode": "centralized"
}
''');

        final String resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        final String home = ProjectResolver.getHomeDirectory();
        expect(resolved, equals(p.join(home, '.thicket', 'projects', 'test-project-123')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveStoragePath resolves inRepo mode', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('thicket-test-inrepo');
      try {
        final Directory thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final File identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-456",
  "projectName": "Test Project 2",
  "createdAt": "2025-01-01T00:00:00.000Z",
  "storageMode": "inRepo"
}
''');

        final String resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        expect(resolved, equals(p.join(tempDir.path, '.thicket', 'world_model')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveStoragePath defaults to centralized if storageMode missing', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('thicket-test-missing');
      try {
        final Directory thicketDir = Directory(p.join(tempDir.path, '.thicket'))..createSync();
        final File identityFile = File(p.join(thicketDir.path, 'project.json'));
        identityFile.writeAsStringSync('''
{
  "projectId": "test-project-789",
  "projectName": "Test Project 3",
  "createdAt": "2025-01-01T00:00:00.000Z"
}
''');

        final String resolved = ProjectResolver.resolveStoragePath(tempDir.path);
        final String home = ProjectResolver.getHomeDirectory();
        expect(resolved, equals(p.join(home, '.thicket', 'projects', 'test-project-789')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
