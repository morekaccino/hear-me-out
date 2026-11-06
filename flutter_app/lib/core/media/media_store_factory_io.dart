import 'media_store.dart';
import 'file_media_store.dart';

/// Creates the file-backed media store for IO platforms.
///
/// [directory] is required on IO so `core/` does not depend on `path_provider`;
/// the app layer resolves the application support directory and passes it in.
Future<MediaStore> createMediaStore({String? directory}) async {
  if (directory == null || directory.trim().isEmpty) {
    throw ArgumentError.value(
      directory,
      'directory',
      'A media directory is required on IO platforms. '
          'Resolve one with path_provider before creating the store.',
    );
  }
  return FileMediaStore(directory: directory);
}
