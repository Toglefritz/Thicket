// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Provides file download capabilities for the web version of the setup wizard.
///
/// Uses the browser's download mechanism to save a ZIP archive containing all Thicket configuration files. This allows
/// users to download everything in one click rather than copying each file individually.
class WebDownloadService {
  const WebDownloadService._();

  /// Downloads all configuration files as a ZIP archive.
  ///
  /// Takes a list of entries where each entry is a pair of (relative file path, file content). Creates a ZIP archive
  /// preserving the directory structure and triggers a browser download.
  static void downloadAsZip({
    required List<MapEntry<String, String>> entries,
    String archiveName = 'thicket-config.zip',
  }) {
    final Archive archive = Archive();

    for (final MapEntry<String, String> entry in entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }

    final List<int> zipData = ZipEncoder().encode(archive);
    final Uint8List zipBytes = Uint8List.fromList(zipData);

    // Create a Blob and trigger a download via an anchor element.
    final html.Blob blob = html.Blob(<dynamic>[zipBytes], 'application/zip');
    final String url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', archiveName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// Downloads a single file with the given content.
  ///
  /// Triggers a browser download for a single configuration file, useful when the user wants to download one file at a
  /// time rather than the entire archive.
  static void downloadFile({
    required String fileName,
    required String content,
  }) {
    final html.Blob blob = html.Blob(
      <dynamic>[content],
      'application/octet-stream',
    );
    final String url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
