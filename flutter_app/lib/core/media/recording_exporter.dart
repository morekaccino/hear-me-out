import 'dart:typed_data';

/// One request to copy a stored take out of the app.
class RecordingExportRequest {
  const RecordingExportRequest({
    required this.id,
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  /// Stored media id. Exporters must not delete or replace it.
  final String id;

  /// Safe file name suggested to the platform.
  final String fileName;

  final Uint8List bytes;
  final String mimeType;
}

/// Result of an export.
class RecordingExportResult {
  const RecordingExportResult({required this.fileName, this.path});

  /// File name the user sees.
  final String fileName;

  /// Absolute path on IO, or null on web where the browser owns the download.
  final String? path;
}

/// Copies a recording out of local storage without changing it.
///
/// IO writes under the app support `exports/` directory. Web downloads the file
/// through the browser. This single-file seam has no share or cloud dependency;
/// T7.2 adds the OS share sheet separately behind `TakeShareGateway`. There is
/// still no cloud, upload, or sync package.
abstract interface class RecordingExporter {
  Future<RecordingExportResult> export(RecordingExportRequest request);
}

/// Thrown when the platform cannot write or download the export.
class RecordingExportException implements Exception {
  const RecordingExportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'RecordingExportException: $message';
}
