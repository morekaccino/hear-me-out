/// Picks the platform media store.
///
/// IO platforms use [FileMediaStore] with a caller-supplied directory. Web uses
/// [WebMediaStore] over IndexedDB. Both implementations satisfy the pure Dart
/// `MediaStore` interface from `media_store.dart`.
library;

export 'media_store_factory_io.dart'
    if (dart.library.js_interop) 'media_store_factory_web.dart';
