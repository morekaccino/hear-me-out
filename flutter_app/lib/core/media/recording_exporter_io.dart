import 'dart:io';

import 'recording_exporter.dart';

/// Builds the IO exporter. [exportsDirectory] is resolved by the app from the
/// application support directory; tests can point it at a temporary folder.
RecordingExporter createRecordingExporter({String exportsDirectory = ''}) {
  if (exportsDirectory.trim().isEmpty) {
    throw ArgumentError.value(
      exportsDirectory,
      'exportsDirectory',
      'an exports directory is required on IO platforms',
    );
  }
  return FileRecordingExporter(directory: exportsDirectory);
}

/// Writes the WAV under `<app support>/exports/`.
class FileRecordingExporter implements RecordingExporter {
  FileRecordingExporter({required this.directory});

  final String directory;

  @override
  Future<RecordingExportResult> export(RecordingExportRequest request) async {
    final name = request.fileName;
    if (name.contains('/') || name.contains(r'\') || name.contains('..')) {
      throw RecordingExportException('Invalid export file name: $name');
    }
    try {
      final folder = Directory(directory);
      await folder.create(recursive: true);
      final file = File('${folder.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(request.bytes, flush: true);
      return RecordingExportResult(fileName: name, path: file.path);
    } catch (error) {
      throw RecordingExportException(
        'Could not write the recording to the exports folder.',
        error,
      );
    }
  }
}
