import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'recording_exporter.dart';

/// Builds the web exporter. The browser owns the download folder, so
/// [exportsDirectory] is ignored.
RecordingExporter createRecordingExporter({String exportsDirectory = ''}) =>
    const WebRecordingExporter();

/// Triggers a browser download of the WAV bytes.
class WebRecordingExporter implements RecordingExporter {
  const WebRecordingExporter();

  @override
  Future<RecordingExportResult> export(RecordingExportRequest request) async {
    try {
      final blob = web.Blob(
        <JSAny>[request.bytes.toJS].toJS,
        web.BlobPropertyBag(type: request.mimeType),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = request.fileName
        ..style.display = 'none';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
      return RecordingExportResult(fileName: request.fileName);
    } catch (error) {
      throw RecordingExportException(
        'Could not start the browser download.',
        error,
      );
    }
  }
}
