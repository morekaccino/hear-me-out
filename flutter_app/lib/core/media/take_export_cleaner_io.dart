import 'dart:io';

import 'take_export_cleaner.dart';

/// Builds the IO cleaner for the app support `exports/` folder.
TakeExportCleaner createTakeExportCleaner({String exportsDirectory = ''}) {
  if (exportsDirectory.trim().isEmpty) {
    throw ArgumentError.value(
      exportsDirectory,
      'exportsDirectory',
      'an exports directory is required on IO platforms',
    );
  }
  return FileTakeExportCleaner(directory: exportsDirectory);
}

/// Deletes only the files directly inside the exports folder.
///
/// The media store lives in `<app support>/media`, so this intentionally cannot
/// reach a stored take. Directories and links are skipped; a link is never
/// followed out of the folder.
class FileTakeExportCleaner implements TakeExportCleaner {
  FileTakeExportCleaner({required this.directory});

  final String directory;

  @override
  bool get isSupported => true;

  @override
  Future<TakeExportClearResult> clearExports() async {
    final folder = Directory(directory);
    var deleted = 0;
    try {
      if (!await folder.exists()) {
        // A file at the folder path is a broken setup, not an empty folder.
        if (await File(directory).exists()) {
          return const TakeExportClearResult(
            failure: TakeExportClearFailure(
              'The exports path is not a folder, so no exported copies were '
              'cleared.',
            ),
          );
        }
        return const TakeExportClearResult();
      }

      await for (final entity in folder.list(followLinks: false)) {
        if (entity is! File) continue;
        await entity.delete();
        deleted++;
      }
      return TakeExportClearResult(deletedCount: deleted);
    } catch (error) {
      return TakeExportClearResult(
        deletedCount: deleted,
        failure: TakeExportClearFailure(
          'Could not clear every exported file. Some copies may remain.',
          error,
        ),
      );
    }
  }
}
