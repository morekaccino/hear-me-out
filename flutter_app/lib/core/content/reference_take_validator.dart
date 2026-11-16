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

  /// Every phrase the registry expects a reference take for, in content order.
  Iterable<ReferenceTakePhrase> get phrases;
}

/// An in-memory catalog for the CLI and tests.
///
/// The constructor takes a [List] so its two indexes cannot consume a
/// single-pass [Iterable] or produce inconsistent piece and phrase maps.
class MapReferenceTakeCatalog implements ReferenceTakeCatalog {
  MapReferenceTakeCatalog(List<ReferenceTakePhrase> phrases)
    : _phrases = <(String, String), ReferenceTakePhrase>{
        for (final phrase in phrases) (phrase.pieceId, phrase.phraseId): phrase,
      },
      _pieceIds = <String>{for (final phrase in phrases) phrase.pieceId};

  final Map<(String, String), ReferenceTakePhrase> _phrases;
  final Set<String> _pieceIds;

  @override
  Iterable<ReferenceTakePhrase> get phrases => _phrases.values;

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
/// keys and files, non-positive durations, blank metadata, unsafe file paths,
/// and optional completeness.
class ReferenceTakeValidator {
  const ReferenceTakeValidator(this.catalog);

  final ReferenceTakeCatalog catalog;

  /// Validates [manifest].
  ///
  /// By default a subset is valid so recordings can arrive incrementally. Set
  /// [requireComplete] to require one target and one slow take for every
  /// phrase in the catalog. The CLI's real catalog is the ten launch pieces
  /// with four phrases each, so the complete set is 80 entries.
  List<ReferenceTakeIssue> validate(
    ReferenceTakeManifest manifest, {
    bool requireComplete = false,
  }) {
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

      if (take.guitar.trim().isEmpty) {
        issues.add(
          _issue(
            'referenceTake.emptyMetadata',
            '$path.guitar',
            'guitar is empty; record the instrument and strings used.',
          ),
        );
      }
      if (take.microphone.trim().isEmpty) {
        issues.add(
          _issue(
            'referenceTake.emptyMetadata',
            '$path.microphone',
            'microphone is empty; record the microphone and placement used.',
          ),
        );
      }
      if (take.consentId.trim().isEmpty) {
        issues.add(
          _issue(
            'referenceTake.emptyMetadata',
            '$path.consentId',
            'consentId is empty; every take must link to a signed release.',
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
        _checkFile(issues, take.file, path);
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

    if (requireComplete) {
      _checkCompleteness(issues, manifest);
    }

    return issues;
  }

  void _checkCompleteness(
    List<ReferenceTakeIssue> issues,
    ReferenceTakeManifest manifest,
  ) {
    final present = <(String, String, ReferenceTakeVariant)>{
      for (final take in manifest.takes)
        if (take.pieceId.trim().isNotEmpty && take.phraseId.trim().isNotEmpty)
          (take.pieceId, take.phraseId, take.variant),
    };

    for (final phrase in catalog.phrases) {
      for (final variant in ReferenceTakeVariant.values) {
        if (!present.contains((phrase.pieceId, phrase.phraseId, variant))) {
          issues.add(
            _issue(
              'referenceTake.missingTake',
              'takes',
              'Missing ${phrase.pieceId}/${phrase.phraseId} at '
                  '${variant.wireName} tempo.',
            ),
          );
        }
      }
    }
  }

  void _checkFile(List<ReferenceTakeIssue> issues, String file, String path) {
    final fieldPath = '$path.file';
    final absolute =
        file.startsWith('/') ||
        file.startsWith('\\') ||
        _driveLetter.hasMatch(file);
    if (absolute) {
      issues.add(
        _issue(
          'referenceTake.absoluteFile',
          fieldPath,
          'file must be relative to assets/content/reference_takes/; '
              'absolute paths are not allowed.',
        ),
      );
    }

    final segments = file.split(RegExp(r'[/\\]'));
    if (segments.contains('..')) {
      issues.add(
        _issue(
          'referenceTake.fileTraversal',
          fieldPath,
          'file must not contain a ".." segment.',
        ),
      );
    }

    if (!segments.last.toLowerCase().endsWith('.wav')) {
      issues.add(
        _issue(
          'referenceTake.nonWavFile',
          fieldPath,
          'file must name a .wav file.',
        ),
      );
    }
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

final RegExp _driveLetter = RegExp(r'^[A-Za-z]:');

ReferenceTakeIssue _issue(String code, String path, String message) =>
    ReferenceTakeIssue(code: code, path: path, message: message);
