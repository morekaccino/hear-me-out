import '../../core/music/json_read.dart';
import '../../core/music/phrase.dart';
import '../../core/music/score.dart';
import '../../core/music/score_parser.dart';

/// Version of the hand-authored score envelope.
///
/// The envelope reuses the canonical score document from
/// `core/music/score_parser.dart` and adds an optional `authoring` object.
/// Future envelope versions are rejected instead of guessed.
const int authoringSchemaVersion = 1;

/// A parse failure in the authoring envelope with a stable code and path.
///
/// It extends [FormatException] so callers that only understand the domain
/// parser can keep using one exception type. The [code] is suitable for CLI
/// output and tests; [path] names the offending JSON field.
class AuthoringFormatException extends FormatException {
  const AuthoringFormatException({
    required this.code,
    required this.path,
    required String message,
  }) : super(message);

  final String code;
  final String path;

  @override
  String toString() => 'FormatException: $message at $path';
}

/// Descriptive metadata that is not part of the musical score.
///
/// This is provenance, not a legal opinion. T6.3 owns legal review; the
/// validator only checks the machine-readable [Piece.license] status.
class AuthoringMeta {
  const AuthoringMeta({
    this.author,
    this.source,
    this.reviewedBy,
    this.notes,
    this.kind,
    this.tier,
    this.stage,
  });

  final String? author;
  final String? source;
  final String? reviewedBy;
  final String? notes;

  /// `piece` or `etude`. Etudes may use fewer than four phrases.
  final String? kind;

  /// Content tier such as `foundation` or `returner`.
  final String? tier;

  /// V1 stage, 1 through 12.
  final int? stage;

  bool get isEtude => kind == 'etude';

  factory AuthoringMeta.fromJsonAt(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final kind = readOptionalJsonString(json, 'kind', path);
    if (kind != null && kind != 'piece' && kind != 'etude') {
      throw AuthoringFormatException(
        code: 'authoring.invalidKind',
        path: '$path.kind',
        message: 'Authoring kind must be "piece" or "etude".',
      );
    }
    return AuthoringMeta(
      author: readOptionalJsonString(json, 'author', path),
      source: readOptionalJsonString(json, 'source', path),
      reviewedBy: readOptionalJsonString(json, 'reviewedBy', path),
      notes: readOptionalJsonString(json, 'notes', path),
      kind: kind,
      tier: readOptionalJsonString(json, 'tier', path),
      stage: readOptionalJsonInt(json, 'stage', path),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (author != null) json['author'] = author;
    if (source != null) json['source'] = source;
    if (reviewedBy != null) json['reviewedBy'] = reviewedBy;
    if (notes != null) json['notes'] = notes;
    if (kind != null) json['kind'] = kind;
    if (tier != null) json['tier'] = tier;
    if (stage != null) json['stage'] = stage;
    return json;
  }
}

/// A parsed authoring document: the musical score plus its provenance.
class AuthoringDocument {
  const AuthoringDocument({required this.score, this.meta});

  final Score score;
  final AuthoringMeta? meta;
}

/// Parses the authoring envelope and composes the T2.1 domain parser.
///
/// Unknown fields are ignored for forward compatibility. A missing, malformed,
/// or future [authoringSchemaVersion] is rejected with an
/// [AuthoringFormatException] naming `schemaVersion`. Structural score errors
/// keep the exact path produced by `parseScore`, for example
/// `phrases[0].events[2].durationBeats`.
AuthoringDocument parseAuthoringDocument(Map<String, dynamic> json) {
  final rawVersion = json['schemaVersion'];
  if (rawVersion == null) {
    throw const AuthoringFormatException(
      code: 'authoring.schemaVersion',
      path: 'schemaVersion',
      message: 'Missing required field schemaVersion.',
    );
  }
  if (rawVersion is! num ||
      !rawVersion.isFinite ||
      rawVersion != rawVersion.roundToDouble()) {
    throw const AuthoringFormatException(
      code: 'authoring.schemaVersion',
      path: 'schemaVersion',
      message: 'Expected an integer schemaVersion.',
    );
  }
  final version = rawVersion.toInt();
  if (version != authoringSchemaVersion) {
    final future = version > authoringSchemaVersion;
    throw AuthoringFormatException(
      code: future ? 'authoring.futureSchema' : 'authoring.unsupportedSchema',
      path: 'schemaVersion',
      message: future
          ? 'Unsupported future authoring schemaVersion $version; '
                'this build supports $authoringSchemaVersion.'
          : 'Unsupported authoring schemaVersion $version; '
                'this build supports $authoringSchemaVersion.',
    );
  }

  AuthoringMeta? meta;
  final rawMeta = json['authoring'];
  if (rawMeta != null) {
    if (rawMeta is! Map) {
      throw const AuthoringFormatException(
        code: 'authoring.invalidMeta',
        path: 'authoring',
        message: 'Expected an object.',
      );
    }
    final metaJson = rawMeta is Map<String, dynamic>
        ? rawMeta
        : Map<String, dynamic>.from(rawMeta);
    meta = AuthoringMeta.fromJsonAt(metaJson, path: 'authoring');
  }

  return AuthoringDocument(score: parseScore(json), meta: meta);
}

/// Parses an authoring document and returns only the musical score.
Score parseAuthoringScore(Map<String, dynamic> json) =>
    parseAuthoringDocument(json).score;

/// Serializes [score] in the authoring envelope.
///
/// The musical fields are produced by the canonical `scoreToJson`, so the
/// authoring format cannot drift from the domain format. [meta] is optional;
/// callers that do not use provenance get a valid canonical score document.
Map<String, dynamic> authoringToJson(Score score, {AuthoringMeta? meta}) {
  final json = scoreToJson(score);
  final metaJson = meta?.toJson();
  if (metaJson != null && metaJson.isNotEmpty) {
    json['authoring'] = metaJson;
  }
  return json;
}

/// V1 authoring and playability checks that sit on top of
/// [MonophonicValidator].
///
/// [validate] returns the T2.1 issues followed by the T3.2 authoring checks.
/// The domain validator remains the single owner of monophonic texture, bars,
/// ties, fingering arithmetic, written/sounding pitch, and capo.
class AuthoringValidator {
  const AuthoringValidator(this.score);

  final Score score;

  static const int minTempoBpm = 50;
  static const int maxTempoBpm = 90;
  static const int maxV1PhraseBars = 4;
  static const int maxV1BeginnerFret = 12;
  static const int maxV1Fret = 19;
  static const int minWrittenMidi = 52; // E3
  static const int maxWrittenMidi = 88; // E6
  static const int shiftFretDistance = 5;

  List<ScoreIssue> validate() {
    final issues = <ScoreIssue>[...score.validate()];
    for (var index = 0; index < score.phrases.length; index++) {
      _validatePhrase(score.phrases[index], index, issues);
    }
    _validateShifts(issues);
    return issues;
  }

  void _validatePhrase(
    Phrase phrase,
    int phraseIndex,
    List<ScoreIssue> issues,
  ) {
    final phrasePath = 'phrases[$phraseIndex]';
    final phraseId = phrase.id.isEmpty ? null : phrase.id;

    if (phrase.bars > maxV1PhraseBars) {
      _error(
        issues,
        'authoring.phraseTooLong',
        'V1 phrases are 1-$maxV1PhraseBars bars; this phrase declares '
            '${phrase.bars}.',
        '$phrasePath.bars',
        phraseId: phraseId,
      );
    }

    final tempo = phrase.targetTempoBpm;
    // Do not add a V1 warning when the domain validator already rejects the
    // tempo outright; one clear error is better than an error and a warning.
    if (tempo >= 30 &&
        tempo <= 200 &&
        (tempo < minTempoBpm || tempo > maxTempoBpm)) {
      _warning(
        issues,
        'authoring.tempoOutsideV1',
        'V1 pieces target $minTempoBpm-$maxTempoBpm BPM; this phrase targets '
            '$tempo BPM.',
        '$phrasePath.targetTempoBpm',
        phraseId: phraseId,
      );
    }

    for (var eventIndex = 0; eventIndex < phrase.events.length; eventIndex++) {
      final event = phrase.events[eventIndex];
      if (!event.isNote) continue;
      final eventPath = '$phrasePath.events[$eventIndex]';

      final written = event.writtenNote;
      if (written != null &&
          (written.midi < minWrittenMidi || written.midi > maxWrittenMidi)) {
        _error(
          issues,
          'authoring.noteOutOfRange',
          'Written ${written.id} is outside the V1 written range E3-E6 '
              '(sounding E2-E5).',
          '$eventPath.writtenNote',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      }

      final hasString = event.string != null;
      final hasFret = event.fret != null;
      if (!hasString && !hasFret) {
        _error(
          issues,
          'authoring.missingFingering',
          'Every V1 note needs an explicit string and fret so the app does '
              'not have to guess between an open string and a fretted '
              'position.',
          eventPath,
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
        continue;
      }

      final fret = event.fret;
      if (fret == null) continue;
      if (fret > maxV1Fret) {
        _error(
          issues,
          'authoring.fretAboveV1Max',
          'V1 supports frets 0-$maxV1Fret; fret $fret is not allowed.',
          '$eventPath.fret',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      } else if (fret > maxV1BeginnerFret) {
        _warning(
          issues,
          'authoring.highFret',
          'Fret $fret is above the V1 beginner range (0-$maxV1BeginnerFret).',
          '$eventPath.fret',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      }
    }
  }

  void _validateShifts(List<ScoreIssue> issues) {
    final totalBars = score.phrases.fold<int>(
      0,
      (sum, phrase) => sum + (phrase.bars > 0 ? phrase.bars : 0),
    );
    if (totalBars == 0) return;

    final shifts = <({int phraseIndex, int eventIndex})>[];
    int? previousFret;
    for (
      var phraseIndex = 0;
      phraseIndex < score.phrases.length;
      phraseIndex++
    ) {
      final phrase = score.phrases[phraseIndex];
      for (
        var eventIndex = 0;
        eventIndex < phrase.events.length;
        eventIndex++
      ) {
        final event = phrase.events[eventIndex];
        if (!event.isNote || event.string == null || event.fret == null) {
          continue;
        }
        final fret = event.fret!;
        // An open string does not move the left hand; keep the last fretted
        // position as the anchor.
        if (fret == 0) continue;
        if (previousFret != null &&
            (fret - previousFret).abs() >= shiftFretDistance) {
          shifts.add((phraseIndex: phraseIndex, eventIndex: eventIndex));
        }
        previousFret = fret;
      }
    }

    final allowed = (totalBars / 2).ceil();
    if (shifts.length <= allowed) return;

    final excess = shifts[allowed];
    final phrase = score.phrases[excess.phraseIndex];
    _warning(
      issues,
      'authoring.tooManyShifts',
      'This score has ${shifts.length} position shifts across $totalBars '
          'bar(s); V1 allows at most one per 2 bars ($allowed).',
      'phrases[${excess.phraseIndex}].events[${excess.eventIndex}]',
      phraseId: phrase.id.isEmpty ? null : phrase.id,
      eventIndex: excess.eventIndex,
    );
  }

  void _error(
    List<ScoreIssue> issues,
    String code,
    String message,
    String path, {
    String? phraseId,
    int? eventIndex,
  }) {
    issues.add(
      ScoreIssue(
        severity: ScoreIssueSeverity.error,
        code: code,
        message: message,
        path: path,
        phraseId: phraseId,
        eventIndex: eventIndex,
      ),
    );
  }

  void _warning(
    List<ScoreIssue> issues,
    String code,
    String message,
    String path, {
    String? phraseId,
    int? eventIndex,
  }) {
    issues.add(
      ScoreIssue(
        severity: ScoreIssueSeverity.warning,
        code: code,
        message: message,
        path: path,
        phraseId: phraseId,
        eventIndex: eventIndex,
      ),
    );
  }
}
