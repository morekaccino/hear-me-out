import 'media_store.dart';

/// One saved take in the [RecordingIndex].
///
/// This is the durable manifest for a take. The bytes live in [MediaStore]; the
/// index records which ids the app owns, so orphan reconciliation can tell a
/// real take from a stale blob. The index is deliberately separate from
/// `ProgressState`: clearing progress never deletes a recording.
class RecordingTake {
  const RecordingTake({
    required this.id,
    required this.createdAt,
    required this.byteLength,
    required this.durationMs,
    this.pieceId,
    this.phraseId,
    this.capped = false,
  });

  /// Opaque media id. Matches the id in the [MediaStore].
  final String id;

  /// Creation time in UTC.
  final DateTime createdAt;

  /// Size of the stored WAV in bytes.
  final int byteLength;

  /// Recording length in milliseconds after any 60-second truncation.
  final int durationMs;

  /// Piece the take belongs to, or null for a free take.
  final String? pieceId;

  /// Phrase the take belongs to, or null for a whole-piece or free take.
  final String? phraseId;

  /// True when the service stopped the take at the length limit.
  final bool capped;

  /// Human-readable label for the recordings list.
  String get label {
    final piece = pieceId;
    final phrase = phraseId;
    if (piece == null && phrase == null) return 'Free take';
    if (piece == null) return phrase!;
    if (phrase == null) return piece;
    return '$piece · $phrase';
  }

  RecordingTake copyWith({
    String? id,
    DateTime? createdAt,
    int? byteLength,
    int? durationMs,
    String? pieceId,
    String? phraseId,
    bool? capped,
  }) => RecordingTake(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    byteLength: byteLength ?? this.byteLength,
    durationMs: durationMs ?? this.durationMs,
    pieceId: pieceId ?? this.pieceId,
    phraseId: phraseId ?? this.phraseId,
    capped: capped ?? this.capped,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'byteLength': byteLength,
    'durationMs': durationMs,
    if (pieceId != null) 'pieceId': pieceId,
    if (phraseId != null) 'phraseId': phraseId,
    if (capped) 'capped': true,
  };

  /// Parses one index entry. Returns null for a malformed entry so one bad
  /// record cannot hide every other take.
  static RecordingTake? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final createdAt = value['createdAt'];
    final byteLength = value['byteLength'];
    final durationMs = value['durationMs'];
    if (id is! String ||
        id.trim().isEmpty ||
        createdAt is! String ||
        byteLength is! int ||
        byteLength < 0 ||
        durationMs is! int ||
        durationMs < 0) {
      return null;
    }
    final parsedAt = DateTime.tryParse(createdAt);
    if (parsedAt == null) return null;
    final pieceId = value['pieceId'];
    final phraseId = value['phraseId'];
    if (pieceId != null && (pieceId is! String || pieceId.trim().isEmpty)) {
      return null;
    }
    if (phraseId != null && (phraseId is! String || phraseId.trim().isEmpty)) {
      return null;
    }
    return RecordingTake(
      id: id,
      createdAt: parsedAt.toUtc(),
      byteLength: byteLength,
      durationMs: durationMs,
      pieceId: pieceId as String?,
      phraseId: phraseId as String?,
      capped: value['capped'] == true,
    );
  }

  /// Builds an index entry from a stored ref. Used when the index document was
  /// lost or unreadable and the app adopts the existing blobs instead of
  /// deleting them.
  static RecordingTake fromMediaRef(MediaRef ref, {bool capped = false}) =>
      RecordingTake(
        id: ref.id,
        createdAt: ref.createdAt.toUtc(),
        byteLength: ref.byteLength,
        durationMs: ref.durationMs ?? 0,
        pieceId: ref.pieceId,
        phraseId: ref.phraseId,
        capped: capped,
      );

  @override
  bool operator ==(Object other) =>
      other is RecordingTake &&
      other.id == id &&
      other.createdAt == createdAt &&
      other.byteLength == byteLength &&
      other.durationMs == durationMs &&
      other.pieceId == pieceId &&
      other.phraseId == phraseId &&
      other.capped == capped;

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    byteLength,
    durationMs,
    pieceId,
    phraseId,
    capped,
  );

  @override
  String toString() => 'RecordingTake($id, ${durationMs}ms, $byteLength bytes)';
}

/// Versioned manifest of the takes the app owns.
///
/// The document is stored outside `ProgressState` under its own key. Future
/// schema versions are rejected instead of guessed, matching the backup and
/// media-index rules.
class RecordingIndex {
  RecordingIndex(Iterable<RecordingTake> takes)
    : takes = List<RecordingTake>.unmodifiable(_sorted(takes));

  /// Version of the index document written by this build.
  static const int schemaVersion = 1;

  static final RecordingIndex empty = RecordingIndex(const <RecordingTake>[]);

  final List<RecordingTake> takes;

  bool get isEmpty => takes.isEmpty;

  int get length => takes.length;

  int get totalBytes => takes.fold(0, (sum, take) => sum + take.byteLength);

  RecordingTake? takeFor(String id) {
    for (final take in takes) {
      if (take.id == id) return take;
    }
    return null;
  }

  /// Adds [take], replacing an entry with the same id.
  RecordingIndex add(RecordingTake take) => RecordingIndex(<RecordingTake>[
    for (final existing in takes)
      if (existing.id != take.id) existing,
    take,
  ]);

  RecordingIndex remove(String id) =>
      RecordingIndex(takes.where((take) => take.id != id));

  /// Takes for [pieceId] in chronological order. A null piece id returns every
  /// free take.
  List<RecordingTake> takesForPiece(String? pieceId) =>
      List<RecordingTake>.of(takes.where((take) => take.pieceId == pieceId));

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'takes': <Object?>[for (final take in takes) take.toJson()],
  };

  /// Parses [json]. Throws [FormatException] for a missing or future schema
  /// version, or a document without a takes list. Malformed entries are
  /// skipped so one bad row cannot make every take unreadable.
  factory RecordingIndex.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException(
        'Unsupported recording index schemaVersion $version; '
        'expected $schemaVersion',
      );
    }
    final rawTakes = json['takes'];
    if (rawTakes is! List<dynamic>) {
      throw const FormatException('Recording index must contain a takes list.');
    }
    final parsed = <RecordingTake>[];
    for (final raw in rawTakes) {
      final take = RecordingTake.tryFromJson(raw);
      if (take != null) parsed.add(take);
    }
    return RecordingIndex(parsed);
  }

  static List<RecordingTake> _sorted(Iterable<RecordingTake> takes) {
    final list = List<RecordingTake>.of(takes);
    list.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return list;
  }
}
