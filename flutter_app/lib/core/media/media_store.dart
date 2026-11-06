import 'dart:typed_data';

/// Metadata for one stored recording or other media blob.
///
/// [id] is opaque and stable for the lifetime of the item. [createdAt] is
/// stored in UTC. [byteLength] lets the UI show storage use without loading
/// the bytes.
class MediaRef {
  const MediaRef({
    required this.id,
    required this.mimeType,
    required this.byteLength,
    required this.createdAt,
  });

  final String id;
  final String mimeType;
  final int byteLength;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is MediaRef &&
      other.id == id &&
      other.mimeType == mimeType &&
      other.byteLength == byteLength &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, mimeType, byteLength, createdAt);

  @override
  String toString() => 'MediaRef($id, $mimeType, $byteLength bytes)';
}

/// Local storage for recordings and other media.
///
/// Recordings are never stored in `ProgressState`. Progress and media have
/// different lifecycles, sizes, and backup rules. T4.1 will provide mobile and
/// web implementations; this ticket defines only the interface and an
/// in-memory implementation for tests.
///
/// Implementations must:
/// - treat [MediaRef.id] as opaque and stable;
/// - replace an existing id atomically in [put];
/// - return a defensive copy of the bytes from [get];
/// - keep [list] limited to metadata.
abstract class MediaStore {
  /// Stores [bytes] under [id], or under a generated stable id when [id] is
  /// null. Storing an existing [id] replaces the previous item atomically.
  Future<MediaRef> put(Uint8List bytes, {required String mimeType, String? id});

  /// Returns a copy of the stored bytes, or null when [id] does not exist.
  Future<Uint8List?> get(String id);

  /// Deletes [id]. Deleting an unknown id is a no-op.
  Future<void> delete(String id);

  /// Returns metadata for every stored item, oldest first.
  Future<List<MediaRef>> list();

  /// Total bytes used by all stored items.
  Future<int> usageBytes();

  /// Deletes every stored item.
  Future<void> clear();
}

/// In-memory [MediaStore] for tests. Not for production recordings.
class MemoryMediaStore implements MediaStore {
  MemoryMediaStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Map<String, _StoredMedia> _entries = <String, _StoredMedia>{};
  final DateTime Function() _clock;
  int _nextId = 1;

  @override
  Future<MediaRef> put(
    Uint8List bytes, {
    required String mimeType,
    String? id,
  }) async {
    if (mimeType.trim().isEmpty) {
      throw ArgumentError.value(mimeType, 'mimeType', 'must not be empty');
    }
    if (id != null && id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }

    final resolvedId = id ?? _generateId();
    final copy = Uint8List.fromList(bytes);
    final ref = MediaRef(
      id: resolvedId,
      mimeType: mimeType,
      byteLength: copy.length,
      createdAt: _clock().toUtc(),
    );
    // Construct the replacement completely before touching the map so a
    // failed put cannot partially replace an existing item.
    _entries[resolvedId] = _StoredMedia(ref: ref, bytes: copy);
    return ref;
  }

  @override
  Future<Uint8List?> get(String id) async {
    final entry = _entries[id];
    if (entry == null) return null;
    return Uint8List.fromList(entry.bytes);
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
  }

  @override
  Future<List<MediaRef>> list() async {
    final refs = <MediaRef>[for (final entry in _entries.values) entry.ref];
    refs.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return List<MediaRef>.unmodifiable(refs);
  }

  @override
  Future<int> usageBytes() async {
    var total = 0;
    for (final entry in _entries.values) {
      total += entry.ref.byteLength;
    }
    return total;
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  String _generateId() {
    while (true) {
      final candidate = 'media-${_nextId++}';
      if (!_entries.containsKey(candidate)) return candidate;
    }
  }
}

class _StoredMedia {
  const _StoredMedia({required this.ref, required this.bytes});

  final MediaRef ref;
  final Uint8List bytes;
}
