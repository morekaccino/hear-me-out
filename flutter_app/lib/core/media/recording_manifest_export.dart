import 'dart:convert';

import 'recording_index.dart';

/// Version of the researcher-readable recording manifest document.
const int recordingManifestSchemaVersion = 1;

/// Stable file name for the one-file beta manifest export.
const String recordingManifestFileName = 'hear-me-out-recordings-manifest.json';

/// One take row in [RecordingManifestExport].
///
/// The row deliberately omits the media id, byte length, absolute path, device
/// name, install id, participant name, free text, and audio bytes. It is built
/// from the local recording index only.
class RecordingManifestTake {
  const RecordingManifestTake({
    required this.pieceId,
    required this.phraseId,
    required this.createdAt,
    required this.durationSeconds,
    required this.sampleRate,
    required this.format,
    required this.firstTake,
    required this.lastTake,
  });

  /// Piece the take belongs to, or null for a free take.
  final String? pieceId;

  /// Phrase the take belongs to, or null for a whole-piece or free take.
  final String? phraseId;

  /// Creation time in UTC.
  final DateTime createdAt;

  /// Take length in seconds.
  final double durationSeconds;

  /// Sample rate of the stored WAV, in hertz.
  final int sampleRate;

  /// Stored format. V1 is `wav`.
  final String format;

  /// True for the earliest take of a non-null piece.
  final bool firstTake;

  /// True for the latest take of a non-null piece.
  final bool lastTake;

  Map<String, Object?> toJson() => <String, Object?>{
    'pieceId': pieceId,
    'phraseId': phraseId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'sampleRate': sampleRate,
    'format': format,
    'firstTake': firstTake,
    'lastTake': lastTake,
  };
}

/// A versioned, minimal local export of the recording manifest.
///
/// The document is read-only: it is built from [RecordingIndex] metadata and
/// never changes, deletes, or rewrites a take or the stored index. It carries
/// no audio bytes.
class RecordingManifestExport {
  const RecordingManifestExport({
    required this.generatedAt,
    required this.takes,
    this.schemaVersion = recordingManifestSchemaVersion,
  });

  final int schemaVersion;
  final DateTime generatedAt;
  final List<RecordingManifestTake> takes;

  /// Builds the export from [index].
  ///
  /// The first and last take are computed per non-null `pieceId` using the
  /// index's stable chronological order (created time, then id). A piece with
  /// one take marks that take as both first and last. A free take has no piece,
  /// so both flags are false.
  factory RecordingManifestExport.fromIndex(
    RecordingIndex index, {
    required DateTime generatedAt,
    required int sampleRate,
    required String format,
  }) {
    final firstIds = <String>{};
    final lastIds = <String>{};
    final groups = <String, List<RecordingTake>>{};
    for (final take in index.takes) {
      final pieceId = take.pieceId;
      if (pieceId == null) continue;
      groups.putIfAbsent(pieceId, () => <RecordingTake>[]).add(take);
    }
    for (final group in groups.values) {
      firstIds.add(group.first.id);
      lastIds.add(group.last.id);
    }

    return RecordingManifestExport(
      generatedAt: generatedAt.toUtc(),
      takes: List<RecordingManifestTake>.unmodifiable(<RecordingManifestTake>[
        for (final take in index.takes)
          RecordingManifestTake(
            pieceId: take.pieceId,
            phraseId: take.phraseId,
            createdAt: take.createdAt.toUtc(),
            durationSeconds: take.durationMs / 1000,
            sampleRate: sampleRate,
            format: format,
            firstTake: take.pieceId != null && firstIds.contains(take.id),
            lastTake: take.pieceId != null && lastIds.contains(take.id),
          ),
      ]),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'takes': <Object?>[for (final take in takes) take.toJson()],
  };

  /// Indented JSON, suitable for the one-file export.
  String encodeJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
