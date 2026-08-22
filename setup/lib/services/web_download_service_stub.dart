/// Stub implementation of [WebDownloadService] for non-web platforms.
///
/// This is never called at runtime since the download buttons are only shown on web. The stub exists to satisfy the
/// conditional import at compile time on native platforms.
class WebDownloadService {
  const WebDownloadService._();

  /// No-op on native platforms.
  static void downloadAsZip({
    required List<MapEntry<String, String>> entries,
    String archiveName = 'thicket-config.zip',
  }) {}

  /// No-op on native platforms.
  static void downloadFile({
    required String fileName,
    required String content,
  }) {}
}
