import 'media_store.dart';
import 'web_media_store.dart';

/// Creates the IndexedDB-backed media store for web.
///
/// [directory] is ignored because IndexedDB has no filesystem path.
Future<MediaStore> createMediaStore({String? directory}) {
  return WebMediaStore.open();
}
