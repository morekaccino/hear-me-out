import 'dart:convert';

import 'recording_index.dart';

/// Version of the researcher-readable recording manifest document.
const int recordingManifestSchemaVersion = 1;

/// Stable file name for the one-file beta manifest export.
const String recordingManifestFileName = 'hear-me-out-recordings-manifest.json';

/// The export-level capture assumption.
///
/// The app does not read each stored WAV header at export time. Every take in
/// the current V1 store was written by the same recorder and encoder, so the
/// document states the assumption once instead of pretending it was read per
/// take. A future rate or AAC change must fail the assertion in
/// `RecordingService.buildRecordingsManifest` and the assumption test.
class RecordingManifestCapture {
  const RecordingManifestCapture({
    required this.sampleRate,
    required this.format,
    this.assumed = true,
  });

  /// The V1 assumption: 22.05 kHz mono PCM16 WAV.
  static const RecordingManifestCapture analysis = RecordingManifestCapture(
    sampleRate: 22050,
    format: 'wav',
  );

  /// Rate the V1 recorder writes, in hertz.
  final int sampleRate;

  /// Container the V1 encoder writes.
  final String format;

  /// True because these values are the export's assumption, not a per-take
  /// header read.
  final bool assumed;

  Map<String, Object?> toJson() => <String, Object?>{
    'assumed': assumed,
    'sampleRate': sampleRate,
    'format': format,
  };
}

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

  /// True for the earliest currently stored take of a non-null piece.
  final bool firstTake;

  /// True for the latest currently stored take of a non-null piece.
  final bool lastTake;

  Map<String, Object?> toJson() => <String, Object?>{
    'pieceId': pieceId,
    'phraseId': phraseId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
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
    required this.capture,
    required this.takes,
    this.schemaVersion = recordingManifestSchemaVersion,
  });

  final int schemaVersion;
  final DateTime generatedAt;

  /// The export-level capture assumption shared by every stored take.
  final RecordingManifestCapture capture;

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
    required RecordingManifestCapture capture,
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
      capture: capture,
      takes: List<RecordingManifestTake>.unmodifiable(<RecordingManifestTake>[
        for (final take in index.takes)
          RecordingManifestTake(
            pieceId: take.pieceId,
            phraseId: take.phraseId,
            createdAt: take.createdAt.toUtc(),
            durationSeconds: take.durationMs / 1000,
            firstTake: take.pieceId != null && firstIds.contains(take.id),
            lastTake: take.pieceId != null && lastIds.contains(take.id),
          ),
      ]),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'capture': capture.toJson(),
    'takes': <Object?>[for (final take in takes) take.toJson()],
  };

  /// Indented JSON, suitable for the one-file export.
  String encodeJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
