import 'dart:typed_data';

/// One file in a take bundle. The bytes are already encoded; exporters only
/// copy them.
class TakeBundleFile {
  const TakeBundleFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  /// Safe file name shown to the user.
  final String fileName;

  final Uint8List bytes;
  final String mimeType;
}

/// One request to copy a take bundle out of the app.
///
/// The bundle is a copy. No exporter may delete, rewrite, or move the stored
/// take or its manifest entry.
class TakeBundleRequest {
  const TakeBundleRequest({required this.takeId, required this.files});

  /// Stored media id the bundle was built from.
  final String takeId;

  final List<TakeBundleFile> files;
}

/// Where one bundle file went.
class TakeBundleFileResult {
  const TakeBundleFileResult({required this.fileName, this.path});

  final String fileName;

  /// Absolute path on IO, or null on web where the browser owns the download.
  final String? path;
}

/// Result of a successful bundle export.
class TakeBundleResult {
  const TakeBundleResult({required this.takeId, required this.files});

  final String takeId;
  final List<TakeBundleFileResult> files;

  List<String> get fileNames =>
      List<String>.unmodifiable(files.map((file) => file.fileName));

  /// Paths for the files the platform wrote. Empty on web.
  List<String> get paths => List<String>.unmodifiable(
    files.map((file) => file.path).whereType<String>(),
  );

  /// True when the browser owns the files and no path is available.
  bool get isDownload => paths.isEmpty;
}

/// Copies a bundle out of local storage without changing it.
///
/// IO writes every file under the app support `exports/` directory. Web
/// downloads each file through the browser. There is no upload or cloud call.
abstract interface class TakeBundleExporter {
  /// Writes or downloads every file in [request].
  ///
  /// Throws [TakeBundleExportException] when the platform cannot write or
  /// download the bundle. Already-written files are left in place; the stored
  /// take is never touched.
  Future<TakeBundleResult> exportBundle(TakeBundleRequest request);
}

/// Thrown when the platform cannot write or download the bundle.
class TakeBundleExportException implements Exception {
  const TakeBundleExportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'TakeBundleExportException: $message';
}
