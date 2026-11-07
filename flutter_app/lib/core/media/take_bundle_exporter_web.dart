import 'recording_exporter.dart';
import 'recording_exporter_web.dart';
import 'take_bundle_exporter.dart';

/// Builds the web bundle exporter. The browser owns the download folder, so
/// [exportsDirectory] is ignored.
TakeBundleExporter createTakeBundleExporter({String exportsDirectory = ''}) =>
    const WebTakeBundleExporter();

/// Triggers one browser download per bundle file.
///
/// Browsers can throttle or block several downloads started by one tap. When a
/// download cannot start, the outcome is a typed [TakeBundleExportException]
/// so the screen can say which files may be missing rather than throwing into
/// the UI.
class WebTakeBundleExporter implements TakeBundleExporter {
  const WebTakeBundleExporter();

  @override
  Future<TakeBundleResult> exportBundle(TakeBundleRequest request) async {
    if (request.files.isEmpty) {
      throw const TakeBundleExportException(
        'The take bundle had no files to export.',
      );
    }
    const downloader = WebRecordingExporter();
    final results = <TakeBundleFileResult>[];
    for (final file in request.files) {
      try {
        final result = await downloader.export(
          RecordingExportRequest(
            id: request.takeId,
            fileName: file.fileName,
            bytes: file.bytes,
            mimeType: file.mimeType,
          ),
        );
        results.add(TakeBundleFileResult(fileName: result.fileName));
      } on RecordingExportException catch (error) {
        throw TakeBundleExportException(error.message, error.cause);
      } catch (error) {
        throw TakeBundleExportException(
          'Could not start every browser download. Allow multiple downloads '
          'and try again.',
          error,
        );
      }
    }
    return TakeBundleResult(takeId: request.takeId, files: results);
  }
}
