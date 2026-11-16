/// Strict validation of a reference-take manifest against the real pieces.
///
/// The catalog is an interface so `lib/core` never imports `lib/content`. The
/// CLI builds the catalog from the ten launch arrangements; tests use a small
/// in-memory catalog.
library;

import 'reference_take.dart';

/// The facts a reference take needs about one phrase.
class ReferenceTakePhrase {
  const ReferenceTakePhrase({
    required this.pieceId,
    required this.phraseId,
    required this.targetTempoBpm,
  });

  final String pieceId;
  final String phraseId;
  final int targetTempoBpm;
}

/// Resolves real piece and phrase ids.
abstract interface class ReferenceTakeCatalog {
  bool hasPiece(String pieceId);

  ReferenceTakePhrase? phraseFor(String pieceId, String phraseId);
}

/// An in-memory catalog for the CLI and tests.
class MapReferenceTakeCatalog implements ReferenceTakeCatalog {
  MapReferenceTakeCatalog(Iterable<ReferenceTakePhrase> phrases)
    : _phrases = <(String, String), ReferenceTakePhrase>{
        for (final phrase in phrases) (phrase.pieceId, phrase.phraseId): phrase,
      },
      _pieceIds = <String>{for (final phrase in phrases) phrase.pieceId};

  final Map<(String, String), ReferenceTakePhrase> _phrases;
  final Set<String> _pieceIds;

  @override
  bool hasPiece(String pieceId) => _pieceIds.contains(pieceId);

  @override
  ReferenceTakePhrase? phraseFor(String pieceId, String phraseId) =>
      _phrases[(pieceId, phraseId)];
}

/// One manifest violation. Reference takes have errors only, no warnings.
class ReferenceTakeIssue {
  const ReferenceTakeIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => 'error $code at $path: $message';
}

/// Checks the semantic rules that a parsed [ReferenceTakeManifest] must meet.
///
/// Structural failures (missing fields, wrong types, unknown variants, future
/// schema versions) are rejected by the parser. This validator owns the rules
/// that need the piece registry: unknown ids, the tempo envelope, duplicate
/// keys and files, and non-positive durations.
class ReferenceTakeValidator {
  const ReferenceTakeValidator(this.catalog);

  final ReferenceTakeCatalog catalog;

  List<ReferenceTakeIssue> validate(ReferenceTakeManifest manifest) {
    final issues = <ReferenceTakeIssue>[];
    final seenKeys = <(String, String, ReferenceTakeVariant), int>{};
    final seenFiles = <String, int>{};

    for (var index = 0; index < manifest.takes.length; index++) {
      final take = manifest.takes[index];
      final path = 'takes[$index]';
      final pieceIsBlank = take.pieceId.trim().isEmpty;
      final phraseIsBlank = take.phraseId.trim().isEmpty;
      final fileIsBlank = take.file.trim().isEmpty;

      if (pieceIsBlank) {
        issues.add(
          _issue(
            'referenceTake.missingKey',
            '$path.pieceId',
            'pieceId is empty; every take must name a piece.',
          ),
        );
      }
      if (phraseIsBlank) {
        issues.add(
          _issue(
            'referenceTake.missingKey',
            '$path.phraseId',
            'phraseId is empty; every take must name a phrase.',
          ),
        );
      }

      if (!pieceIsBlank && !phraseIsBlank) {
        final key = (take.pieceId, take.phraseId, take.variant);
        final first = seenKeys[key];
        if (first != null) {
          issues.add(
            _issue(
              'referenceTake.duplicateKey',
              path,
              'Duplicate (pieceId, phraseId, variant); the first entry is '
                  'takes[$first].',
            ),
          );
        } else {
          seenKeys[key] = index;
        }
      }

      if (!pieceIsBlank) {
        if (!catalog.hasPiece(take.pieceId)) {
          issues.add(
            _issue(
              'referenceTake.unknownPiece',
              '$path.pieceId',
              'Unknown piece "${take.pieceId}"; reference takes cover only '
                  'the ten launch pieces.',
            ),
          );
        } else if (!phraseIsBlank) {
          final phrase = catalog.phraseFor(take.pieceId, take.phraseId);
          if (phrase == null) {
            issues.add(
              _issue(
                'referenceTake.unknownPhrase',
                '$path.phraseId',
                'Unknown phrase "${take.phraseId}" for piece '
                    '"${take.pieceId}".',
              ),
            );
          } else {
            _checkTempo(issues, take, phrase, path);
          }
        }
      }

      if (take.durationMs <= 0) {
        issues.add(
          _issue(
            'referenceTake.durationNotPositive',
            '$path.durationMs',
            'durationMs must be greater than zero.',
          ),
        );
      }

      if (fileIsBlank) {
        issues.add(
          _issue(
            'referenceTake.emptyFile',
            '$path.file',
            'file is empty; every take must name a WAV file.',
          ),
        );
      } else {
        final first = seenFiles[take.file];
        if (first != null) {
          issues.add(
            _issue(
              'referenceTake.duplicateFile',
              '$path.file',
              'Duplicate file path "${take.file}"; the first entry is '
                  'takes[$first].',
            ),
          );
        } else {
          seenFiles[take.file] = index;
        }
      }
    }

    return issues;
  }

  void _checkTempo(
    List<ReferenceTakeIssue> issues,
    ReferenceTake take,
    ReferenceTakePhrase phrase,
    String path,
  ) {
    final target = phrase.targetTempoBpm;
    if (take.variant == ReferenceTakeVariant.target) {
      if (take.bpm != target) {
        issues.add(
          _issue(
            'referenceTake.bpmOutsideTempoEnvelope',
            '$path.bpm',
            'Target take is ${take.bpm} BPM; ${phrase.phraseId} declares '
                '$target BPM.',
          ),
        );
      }
      return;
    }

    // The slow take is 60-75% of the declared target. Keep the accepted
    // integer BPMs inside the percentage band instead of rounding a take that
    // is just outside it.
    final min = (target * 3 + 4) ~/ 5;
    final max = (target * 3) ~/ 4;
    if (take.bpm < min || take.bpm > max) {
      issues.add(
        _issue(
          'referenceTake.bpmOutsideTempoEnvelope',
          '$path.bpm',
          'Slow take is ${take.bpm} BPM; the 60-75% envelope for $target BPM '
              'is $min-$max BPM.',
        ),
      );
    }
  }
}

ReferenceTakeIssue _issue(String code, String path, String message) =>
    ReferenceTakeIssue(code: code, path: path, message: message);
