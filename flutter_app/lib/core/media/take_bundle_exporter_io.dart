import 'recording_exporter.dart';
import 'recording_exporter_io.dart';
import 'take_bundle_exporter.dart';

/// Builds the IO bundle exporter. [exportsDirectory] is the app support
/// `exports/` folder; tests point it at a temporary folder.
TakeBundleExporter createTakeBundleExporter({String exportsDirectory = ''}) {
  if (exportsDirectory.trim().isEmpty) {
    throw ArgumentError.value(
      exportsDirectory,
      'exportsDirectory',
      'an exports directory is required on IO platforms',
    );
  }
  return FileTakeBundleExporter(directory: exportsDirectory);
}

/// Writes every bundle file under `<app support>/exports/`.
///
/// It reuses [FileRecordingExporter], the same single-file writer the take
/// export already used, so there is one place that validates names and writes
/// atomically per file.
class FileTakeBundleExporter implements TakeBundleExporter {
  FileTakeBundleExporter({required this.directory});

  final String directory;

  @override
  Future<TakeBundleResult> exportBundle(TakeBundleRequest request) async {
    if (request.files.isEmpty) {
      throw const TakeBundleExportException(
        'The take bundle had no files to export.',
      );
    }
    final writer = FileRecordingExporter(directory: directory);
    final results = <TakeBundleFileResult>[];
    for (final file in request.files) {
      try {
        final result = await writer.export(
          RecordingExportRequest(
            id: request.takeId,
            fileName: file.fileName,
            bytes: file.bytes,
            mimeType: file.mimeType,
          ),
        );
        results.add(
          TakeBundleFileResult(fileName: result.fileName, path: result.path),
        );
      } on RecordingExportException catch (error) {
        throw TakeBundleExportException(error.message, error.cause);
      } catch (error) {
        throw TakeBundleExportException(
          'Could not write every file in the take bundle.',
          error,
        );
      }
    }
    return TakeBundleResult(takeId: request.takeId, files: results);
  }
}
