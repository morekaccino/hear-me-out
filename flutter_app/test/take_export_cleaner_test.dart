import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/take_export_cleaner_io.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hmo_export_clean_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deletes only the files directly inside the exports folder', () async {
    final exports = Directory('${tempDir.path}/exports')..createSync();
    File('${exports.path}/take-1.wav').writeAsBytesSync(<int>[1]);
    File('${exports.path}/take-1.json').writeAsBytesSync(<int>[2]);
    File('${exports.path}/take-1.pdf').writeAsBytesSync(<int>[3]);
    final nested = Directory('${exports.path}/nested')..createSync();
    File('${nested.path}/keep.wav').writeAsBytesSync(<int>[4]);
    final media = File('${tempDir.path}/media/take-1.wav')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[5]);

    final cleaner = FileTakeExportCleaner(directory: exports.path);
    final result = await cleaner.clearExports();

    expect(result.cleared, isTrue);
    expect(result.deletedCount, 3);
    expect(await File('${exports.path}/take-1.wav').exists(), isFalse);
    expect(await File('${exports.path}/take-1.json').exists(), isFalse);
    expect(await File('${exports.path}/take-1.pdf').exists(), isFalse);
    // A nested directory and its file are left alone.
    expect(await Directory(nested.path).exists(), isTrue);
    expect(await File('${nested.path}/keep.wav').exists(), isTrue);
    // The stored media folder is untouched.
    expect(await media.exists(), isTrue);
  });

  test('an absent exports folder clears zero files', () async {
    final cleaner = FileTakeExportCleaner(directory: '${tempDir.path}/exports');

    final result = await cleaner.clearExports();

    expect(result.cleared, isTrue);
    expect(result.deletedCount, 0);
  });

  test('a file at the exports path is a typed failure', () async {
    final blocked = File('${tempDir.path}/exports')
      ..writeAsStringSync('not a directory');
    final cleaner = FileTakeExportCleaner(directory: blocked.path);

    final result = await cleaner.clearExports();

    expect(result.cleared, isFalse);
    expect(result.failure, isNotNull);
    expect(result.failure!.message, contains('not a folder'));
    expect(await blocked.exists(), isTrue);
  });
}
