import 'dart:typed_data';

/// Metadata for one stored recording or other media blob.
///
/// [id] is opaque and stable for the lifetime of the item. [createdAt] is
/// stored in UTC. [byteLength] lets the UI show storage use without loading
/// the bytes.
///
/// The optional fields are the recording manifest. They are null when the
/// caller has not supplied them, so existing callers stay source-compatible.
/// A take can be linked to a [pieceId] and [phraseId], carry its
/// [durationMs], and later receive an analysis [score] tagged with the
/// [analysisVersion] that produced it.
class MediaRef {
  const MediaRef({
    required this.id,
    required this.mimeType,
    required this.byteLength,
    required this.createdAt,
    this.pieceId,
    this.phraseId,
    this.durationMs,
    this.score,
    this.analysisVersion,
  });

  final String id;
  final String mimeType;
  final int byteLength;
  final DateTime createdAt;

  /// Piece the recording belongs to, or null for a free take.
  final String? pieceId;

  /// Phrase the recording belongs to, or null for a whole-piece or free take.
  final String? phraseId;

  /// Recording length in milliseconds, when known.
  final int? durationMs;

  /// Analysis result for this take, when analysis has run.
  final double? score;

  /// Version of the analyzer that produced [score].
  final int? analysisVersion;

  @override
  bool operator ==(Object other) =>
      other is MediaRef &&
      other.id == id &&
      other.mimeType == mimeType &&
      other.byteLength == byteLength &&
      other.createdAt == createdAt &&
      other.pieceId == pieceId &&
      other.phraseId == phraseId &&
      other.durationMs == durationMs &&
      other.score == score &&
      other.analysisVersion == analysisVersion;

  @override
  int get hashCode => Object.hash(
    id,
    mimeType,
    byteLength,
    createdAt,
    pieceId,
    phraseId,
    durationMs,
    score,
    analysisVersion,
  );

  @override
  String toString() => 'MediaRef($id, $mimeType, $byteLength bytes)';
}

/// Validates optional manifest fields before a store writes them.
///
/// Every [MediaStore] calls this in [MediaStore.put] so a value accepted by
/// [put] can always be read back. Throws [ArgumentError] named after the
/// offending field:
///
/// - [pieceId] and [phraseId] must not be blank when provided;
/// - [durationMs] and [analysisVersion] must be non-negative;
/// - [score] must be finite.
void validateMediaManifest({
  String? pieceId,
  String? phraseId,
  int? durationMs,
  double? score,
  int? analysisVersion,
}) {
  if (pieceId != null && pieceId.trim().isEmpty) {
    throw ArgumentError.value(pieceId, 'pieceId', 'must not be blank');
  }
  if (phraseId != null && phraseId.trim().isEmpty) {
    throw ArgumentError.value(phraseId, 'phraseId', 'must not be blank');
  }
  if (durationMs != null && durationMs < 0) {
    throw ArgumentError.value(durationMs, 'durationMs', 'must be non-negative');
  }
  if (score != null && !score.isFinite) {
    throw ArgumentError.value(score, 'score', 'must be finite');
  }
  if (analysisVersion != null && analysisVersion < 0) {
    throw ArgumentError.value(
      analysisVersion,
      'analysisVersion',
      'must be non-negative',
    );
  }
}

/// Local storage for recordings and other media.
///
/// Recordings are never stored in `ProgressState`. Progress and media have
/// different lifecycles, sizes, and backup rules. The platform implementations
/// are `FileMediaStore` (mobile/desktop) and `WebMediaStore` (IndexedDB);
/// `MemoryMediaStore` is for tests only.
///
/// Implementations must:
/// - treat [MediaRef.id] as opaque and stable;
/// - replace an existing id atomically in [put];
/// - return a defensive copy of the bytes from [get];
/// - keep [list] limited to metadata.
abstract class MediaStore {
  /// Stores [bytes] under [id], or under a generated stable id when [id] is
  /// null. Storing an existing [id] replaces the previous item atomically.
  ///
  /// The optional manifest fields are persisted with the item and returned by
  /// [list]. Omitted fields are stored as null.
  Future<MediaRef> put(
    Uint8List bytes, {
    required String mimeType,
    String? id,
    String? pieceId,
    String? phraseId,
    int? durationMs,
    double? score,
    int? analysisVersion,
  });

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
    String? pieceId,
    String? phraseId,
    int? durationMs,
    double? score,
    int? analysisVersion,
  }) async {
    if (mimeType.trim().isEmpty) {
      throw ArgumentError.value(mimeType, 'mimeType', 'must not be empty');
    }
    if (id != null && id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    validateMediaManifest(
      pieceId: pieceId,
      phraseId: phraseId,
      durationMs: durationMs,
      score: score,
      analysisVersion: analysisVersion,
    );

    final resolvedId = id ?? _generateId();
    final copy = Uint8List.fromList(bytes);
    final ref = MediaRef(
      id: resolvedId,
      mimeType: mimeType,
      byteLength: copy.length,
      createdAt: _clock().toUtc(),
      pieceId: pieceId,
      phraseId: phraseId,
      durationMs: durationMs,
      score: score,
      analysisVersion: analysisVersion,
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
