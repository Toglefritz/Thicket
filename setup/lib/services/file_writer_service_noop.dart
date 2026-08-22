import 'thicket_api_service.dart';

/// No-op implementation of [FileWriterService] for web.
///
/// On web, file-system operations are not available. This implementation provides the same API but does nothing. The
/// controller checks `kIsWeb` before calling these methods, so they should never actually be invoked at runtime.
class FileWriterService {
  const FileWriterService._();

  /// Always returns false on web.
  static bool directoryExists(String path) => false;

  /// Always returns null on web.
  static Map<String, dynamic>? readExistingConfig(String projectPath) => null;

  /// No-op on web.
  static void writeProjectConfig({
    required RegistrationResult result,
    required String projectName,
    required String projectPath,
  }) {}

  /// No-op on web.
  static void writeCredentials({
    required String apiToken,
    required String projectPath,
  }) {}
}
