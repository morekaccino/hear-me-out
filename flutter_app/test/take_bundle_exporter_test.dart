import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/take_bundle_exporter.dart';
import 'package:hear_me_out/core/media/take_bundle_exporter_io.dart';

Uint8List _bytes(int seed) =>
    Uint8List.fromList(<int>[seed, seed + 1, seed + 2, seed + 3]);

TakeBundleRequest _request() => TakeBundleRequest(
  takeId: 'take-1',
  files: <TakeBundleFile>[
    TakeBundleFile(
      fileName: 'take-1.wav',
      bytes: _bytes(10),
      mimeType: 'audio/wav',
    ),
    TakeBundleFile(
      fileName: 'take-1.json',
      bytes: _bytes(20),
      mimeType: 'application/json',
    ),
    TakeBundleFile(
      fileName: 'take-1.pdf',
      bytes: _bytes(30),
      mimeType: 'application/pdf',
    ),
  ],
);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hmo_bundle_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('writes every file under the exports directory', () async {
    final exporter = FileTakeBundleExporter(directory: tempDir.path);
    final request = _request();

    final result = await exporter.exportBundle(request);

    expect(result.takeId, 'take-1');
    expect(result.fileNames, <String>[
      'take-1.wav',
      'take-1.json',
      'take-1.pdf',
    ]);
    expect(result.paths, hasLength(3));
    for (final file in result.files) {
      expect(file.path, isNotNull);
      final written = File(file.path!);
      expect(await written.exists(), isTrue);
    }
    expect(
      await File('${tempDir.path}/take-1.wav').readAsBytes(),
      _bytes(10),
    );
    expect(
      await File('${tempDir.path}/take-1.json').readAsBytes(),
      _bytes(20),
    );
    expect(
      await File('${tempDir.path}/take-1.pdf').readAsBytes(),
      _bytes(30),
    );
  });

  test('does not delete or change a source take outside the export folder', () async {
    final source = File('${tempDir.path}/stored-take.wav');
    await source.writeAsBytes(_bytes(99), flush: true);
    final exporter = FileTakeBundleExporter(directory: '${tempDir.path}/exports');

    await exporter.exportBundle(_request());

    expect(await source.exists(), isTrue);
    expect(await source.readAsBytes(), _bytes(99));
  });

  test('rejects a traversal file name without writing outside the folder', () async {
    final exporter = FileTakeBundleExporter(directory: tempDir.path);
    final request = TakeBundleRequest(
      takeId: 'take-1',
      files: <TakeBundleFile>[
        TakeBundleFile(
          fileName: '../escape.wav',
          bytes: _bytes(1),
          mimeType: 'audio/wav',
        ),
      ],
    );

    await expectLater(
      exporter.exportBundle(request),
      throwsA(isA<TakeBundleExportException>()),
    );
    expect(await File('${tempDir.path}/../escape.wav').exists(), isFalse);
  });

  test('returns a typed failure when the export folder cannot be created', () async {
    final blocked = File('${tempDir.path}/blocked');
    await blocked.writeAsString('not a directory');
    final exporter = FileTakeBundleExporter(
      directory: '${blocked.path}/exports',
    );

    await expectLater(
      exporter.exportBundle(_request()),
      throwsA(
        isA<TakeBundleExportException>().having(
          (error) => error.message,
          'message',
          contains('Could not write'),
        ),
      ),
    );
  });

  test('an empty bundle is a typed failure', () async {
    final exporter = FileTakeBundleExporter(directory: tempDir.path);

    await expectLater(
      exporter.exportBundle(
        const TakeBundleRequest(takeId: 'take-1', files: <TakeBundleFile>[]),
      ),
      throwsA(isA<TakeBundleExportException>()),
    );
  });
}
