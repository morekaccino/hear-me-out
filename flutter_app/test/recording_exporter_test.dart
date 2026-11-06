import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/recording_exporter.dart';
import 'package:hear_me_out/core/media/recording_exporter_io.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hmo_exports_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('writes the exact bytes under the exports directory', () async {
    final exporter = FileRecordingExporter(directory: tempDir.path);
    final bytes = Uint8List.fromList(<int>[82, 73, 70, 70, 1, 2, 3]);

    final result = await exporter.export(
      RecordingExportRequest(
        id: 'take-1',
        fileName: 'recording-take-1.wav',
        bytes: bytes,
        mimeType: 'audio/wav',
      ),
    );

    expect(result.fileName, 'recording-take-1.wav');
    expect(result.path, isNotNull);
    final file = File(result.path!);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), bytes);
  });

  test('rejects a file name that could escape the exports directory', () async {
    final exporter = FileRecordingExporter(directory: tempDir.path);

    await expectLater(
      exporter.export(
        RecordingExportRequest(
          id: 'take-1',
          fileName: '../escape.wav',
          bytes: Uint8List.fromList(<int>[1]),
          mimeType: 'audio/wav',
        ),
      ),
      throwsA(isA<RecordingExportException>()),
    );
  });
}
