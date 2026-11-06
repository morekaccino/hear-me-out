import 'guitar.dart';
import 'note_event.dart';
import 'phrase.dart';
import 'piece.dart';

enum ScoreIssueSeverity { error, warning }

/// One validation finding. [path] points at the offending JSON-style field,
/// for example `piece.title` or `phrases[0].events[2].soundingMidi`.
class ScoreIssue {
  const ScoreIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.path,
    this.phraseId,
    this.eventIndex,
  });

  final ScoreIssueSeverity severity;
  final String code;
  final String message;
  final String path;
  final String? phraseId;
  final int? eventIndex;

  bool get isError => severity == ScoreIssueSeverity.error;

  bool get isWarning => severity == ScoreIssueSeverity.warning;

  @override
  String toString() => '${severity.name} $code at $path: $message';
}

/// A piece plus its phrases in performance order.
class Score {
  const Score({required this.piece, required this.phrases});

  final Piece piece;
  final List<Phrase> phrases;

  /// Returns every issue, not just the first. Structural JSON problems are
  /// reported by the parser; this method owns musical and model invariants.
  List<ScoreIssue> validate() => MonophonicValidator(this).validate();

  bool get hasErrors => validate().any((issue) => issue.isError);
}

/// Enforces the V1 monophonic rules and the score model invariants.
///
/// The validator deliberately re-derives sounding pitch from the written note
/// and from the string/fret position. It never trusts a caller-supplied
/// `soundingMidi`.
class MonophonicValidator {
  const MonophonicValidator(this.score);

  final Score score;

  static const double _epsilon = 1e-6;

  List<ScoreIssue> validate() {
    final issues = <ScoreIssue>[];
    _validatePiece(issues);

    if (score.phrases.isEmpty) {
      _error(
        issues,
        'score.empty',
        'A score must contain at least one phrase.',
        'phrases',
      );
    }

    final seenIds = <String>{};
    for (var index = 0; index < score.phrases.length; index++) {
      final phrase = score.phrases[index];
      _validatePhrase(phrase, 'phrases[$index]', seenIds, issues);
    }
    return issues;
  }

  void _validatePiece(List<ScoreIssue> issues) {
    final piece = score.piece;
    const path = 'piece';

    if (piece.id.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyId',
        'Piece id must not be empty.',
        '$path.id',
      );
    }
    if (piece.title.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyTitle',
        'Piece title must not be empty.',
        '$path.title',
      );
    }
    if (piece.composer.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyComposer',
        'Piece composer must not be empty.',
        '$path.composer',
      );
    }
    if (piece.key.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyKey',
        'Piece key must not be empty.',
        '$path.key',
      );
    }
    if (piece.license.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyLicense',
        'Piece license must not be empty.',
        '$path.license',
      );
    } else {
      final status = piece.licenseStatus;
      if (status == null) {
        _error(
          issues,
          'piece.unknownLicense',
          'License "${piece.license}" is not one of public-domain, original, or licensed.',
          '$path.license',
        );
      } else if (!status.isV1Compatible) {
        _error(
          issues,
          'piece.licenseNotV1Compatible',
          'V1 content must be public domain or original; "${piece.license}" is not.',
          '$path.license',
        );
      }
    }
    if (piece.capo < 0 || piece.capo > 12) {
      _error(
        issues,
        'piece.invalidCapo',
        'Capo must be between 0 and 12.',
        '$path.capo',
      );
    } else if (piece.capo != 0) {
      _error(
        issues,
        'piece.unsupportedCapo',
        'V1 supports capo 0 only; capo ${piece.capo} is not supported.',
        '$path.capo',
      );
    }
    if (!piece.timeSignature.isValid) {
      _error(
        issues,
        'piece.invalidTimeSignature',
        'Time signature $piece.timeSignature is not supported.',
        '$path.timeSignature',
      );
    }
    if (piece.tuning.name.trim().isEmpty) {
      _error(
        issues,
        'piece.emptyTuningName',
        'Tuning name must not be empty.',
        '$path.tuning.name',
      );
    }

    final openStrings = piece.tuning.openStrings;
    if (openStrings.length != 6) {
      _error(
        issues,
        'piece.invalidTuning',
        'A guitar tuning must have exactly six open strings.',
        '$path.tuning.openStrings',
      );
    } else {
      var valid = true;
      for (var index = 0; index < openStrings.length; index++) {
        if (openStrings[index] < 0 || openStrings[index] > 127) {
          valid = false;
        }
        if (index > 0 && openStrings[index] <= openStrings[index - 1]) {
          valid = false;
        }
      }
      if (!valid) {
        _error(
          issues,
          'piece.invalidTuning',
          'Open strings must be six ascending MIDI values.',
          '$path.tuning.openStrings',
        );
      } else if (!piece.tuning.isStandard) {
        _warning(
          issues,
          'piece.nonStandardTuning',
          'This piece uses a non-standard tuning; V1 content is expected to use E2 A2 D3 G3 B3 E4.',
          '$path.tuning.openStrings',
        );
      }
    }
  }

  void _validatePhrase(
    Phrase phrase,
    String path,
    Set<String> seenIds,
    List<ScoreIssue> issues,
  ) {
    final phraseId = phrase.id.isEmpty ? null : phrase.id;

    if (phrase.id.trim().isEmpty) {
      _error(
        issues,
        'phrase.emptyId',
        'Phrase id must not be empty.',
        '$path.id',
        phraseId: phraseId,
      );
    } else if (!seenIds.add(phrase.id)) {
      _error(
        issues,
        'phrase.duplicateId',
        'Duplicate phrase id "${phrase.id}".',
        '$path.id',
        phraseId: phraseId,
      );
    }

    if (phrase.bars < 1 || phrase.bars > Phrase.maxV1Bars) {
      _error(
        issues,
        'phrase.invalidBars',
        'A phrase must have between 1 and ${Phrase.maxV1Bars} bars.',
        '$path.bars',
        phraseId: phraseId,
      );
    }
    if (!phrase.timeSignature.isValid) {
      _error(
        issues,
        'phrase.invalidTimeSignature',
        'Time signature ${phrase.timeSignature} is not supported.',
        '$path.timeSignature',
        phraseId: phraseId,
      );
    }
    if (phrase.targetTempoBpm < 30 || phrase.targetTempoBpm > 200) {
      _error(
        issues,
        'phrase.invalidTempo',
        'Target tempo must be between 30 and 200 BPM.',
        '$path.targetTempoBpm',
        phraseId: phraseId,
      );
    }
    if (phrase.difficulty < 1 || phrase.difficulty > 5) {
      _error(
        issues,
        'phrase.invalidDifficulty',
        'Difficulty must be between 1 and 5.',
        '$path.difficulty',
        phraseId: phraseId,
      );
    }
    if (phrase.contentVersion < 1) {
      _error(
        issues,
        'phrase.invalidContentVersion',
        'Content version must be at least 1.',
        '$path.contentVersion',
        phraseId: phraseId,
      );
    }
    if (phrase.startBar < 1) {
      _error(
        issues,
        'phrase.invalidStartBar',
        'Start bar must be at least 1.',
        '$path.startBar',
        phraseId: phraseId,
      );
    }
    if (!phrase.pickupBeats.isFinite) {
      _error(
        issues,
        'phrase.invalidPickup',
        'Pickup length must be a finite number.',
        '$path.pickupBeats',
        phraseId: phraseId,
      );
    } else if (phrase.timeSignature.isValid &&
        (phrase.pickupBeats < 0 ||
            phrase.pickupBeats >= phrase.timeSignature.beatsPerBar)) {
      _error(
        issues,
        'phrase.invalidPickup',
        'Pickup length must be at least 0 and shorter than one bar.',
        '$path.pickupBeats',
        phraseId: phraseId,
      );
    }

    for (var index = 0; index < phrase.skills.length; index++) {
      if (phrase.skills[index].trim().isEmpty) {
        _error(
          issues,
          'phrase.emptySkill',
          'Skill ids must not be empty.',
          '$path.skills[$index]',
          phraseId: phraseId,
        );
      }
    }

    if (phrase.events.isEmpty) {
      _error(
        issues,
        'phrase.emptyEvents',
        'A phrase must contain at least one note or rest event.',
        '$path.events',
        phraseId: phraseId,
      );
      return;
    }

    for (var index = 1; index < phrase.events.length; index++) {
      if (phrase.events[index].startBeat <
          phrase.events[index - 1].startBeat - _epsilon) {
        _error(
          issues,
          'phrase.eventsUnordered',
          'Events must be listed in performance order.',
          '$path.events[$index]',
          phraseId: phraseId,
          eventIndex: index,
        );
      }
    }

    for (var index = 0; index < phrase.events.length; index++) {
      _validateEvent(phrase.events[index], index, path, phraseId, issues);
    }

    _validateOverlaps(phrase, path, phraseId, issues);
    _validateTies(phrase, path, phraseId, issues);
    _validateBars(phrase, path, phraseId, issues);
  }

  void _validateEvent(
    NoteEvent event,
    int eventIndex,
    String phrasePath,
    String? phraseId,
    List<ScoreIssue> issues,
  ) {
    final eventPath = '$phrasePath.events[$eventIndex]';
    if (!event.startBeat.isFinite) {
      _error(
        issues,
        'event.nonFinite',
        'Event start must be a finite number.',
        '$eventPath.startBeat',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    } else if (event.startBeat < 0) {
      _error(
        issues,
        'event.invalidStart',
        'Event start must not be negative.',
        '$eventPath.startBeat',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }

    if (!event.durationBeats.isFinite) {
      _error(
        issues,
        'event.nonFinite',
        'Event duration must be a finite number.',
        '$eventPath.durationBeats',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    } else if (event.durationBeats <= 0) {
      _error(
        issues,
        'event.invalidDuration',
        'Event duration must be greater than zero.',
        '$eventPath.durationBeats',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }

    if (!event.velocity.isFinite) {
      _error(
        issues,
        'event.nonFinite',
        'Event velocity must be a finite number.',
        '$eventPath.velocity',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    } else if (event.velocity < 0 || event.velocity > 1) {
      _error(
        issues,
        'event.invalidVelocity',
        'Velocity must be between 0 and 1.',
        '$eventPath.velocity',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }

    switch (event.kind) {
      case NoteEventKind.note:
        _validateNoteEvent(event, eventPath, phraseId, eventIndex, issues);
      case NoteEventKind.rest:
        _validateRestEvent(event, eventPath, phraseId, eventIndex, issues);
    }
  }

  void _validateNoteEvent(
    NoteEvent event,
    String eventPath,
    String? phraseId,
    int eventIndex,
    List<ScoreIssue> issues,
  ) {
    final written = event.writtenNote;
    final sounding = event.soundingMidi;
    if (written == null) {
      _error(
        issues,
        'note.missingWritten',
        'A note event must have a written note.',
        '$eventPath.writtenNote',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }
    if (sounding == null) {
      _error(
        issues,
        'note.missingSounding',
        'A note event must have a sounding MIDI number.',
        '$eventPath.soundingMidi',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    } else if (sounding < 0 || sounding > 127) {
      _error(
        issues,
        'note.soundingOutOfRange',
        'Sounding MIDI must be between 0 and 127.',
        '$eventPath.soundingMidi',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }

    if (written != null && sounding != null) {
      final expected = Guitar.soundingMidiForWritten(written);
      if (sounding != expected) {
        _error(
          issues,
          'note.writtenSoundingMismatch',
          'Written ${written.id} sounds as MIDI $expected, but the event declares $sounding.',
          '$eventPath.soundingMidi',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      }
    }

    final string = event.string;
    final fret = event.fret;
    if ((string == null) != (fret == null)) {
      _error(
        issues,
        'fingering.incomplete',
        'Provide both string and fret, or neither.',
        eventPath,
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    } else if (string != null && fret != null) {
      var validPosition = true;
      if (string < 1 || string > 6) {
        validPosition = false;
        _error(
          issues,
          'fingering.invalidString',
          'String must be between 1 (high E) and 6 (low E).',
          '$eventPath.string',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      }
      if (fret < 0 || fret > 24) {
        validPosition = false;
        _error(
          issues,
          'fingering.invalidFret',
          'Fret must be between 0 and 24.',
          '$eventPath.fret',
          phraseId: phraseId,
          eventIndex: eventIndex,
        );
      }
      if (validPosition) {
        final positionMidi = score.piece.tuning.soundingMidiAt(string, fret);
        if (positionMidi != null &&
            sounding != null &&
            positionMidi != sounding) {
          _error(
            issues,
            'fingering.mismatch',
            'String $string fret $fret sounds as MIDI $positionMidi, not $sounding.',
            eventPath,
            phraseId: phraseId,
            eventIndex: eventIndex,
          );
        }
      }
    }
  }

  void _validateRestEvent(
    NoteEvent event,
    String eventPath,
    String? phraseId,
    int eventIndex,
    List<ScoreIssue> issues,
  ) {
    if (event.writtenNote != null) {
      _error(
        issues,
        'rest.hasWrittenNote',
        'A rest cannot have a written note.',
        '$eventPath.writtenNote',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }
    if (event.soundingMidi != null) {
      _error(
        issues,
        'rest.hasSoundingMidi',
        'A rest cannot have a sounding MIDI number.',
        '$eventPath.soundingMidi',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }
    if (event.string != null || event.fret != null) {
      _error(
        issues,
        'rest.hasFingering',
        'A rest cannot have a string or fret.',
        eventPath,
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }
    if (event.tieToNext) {
      _error(
        issues,
        'rest.hasTie',
        'A rest cannot be tied.',
        '$eventPath.tieToNext',
        phraseId: phraseId,
        eventIndex: eventIndex,
      );
    }
  }

  void _validateOverlaps(
    Phrase phrase,
    String phrasePath,
    String? phraseId,
    List<ScoreIssue> issues,
  ) {
    final events = phrase.events;
    final order = List<int>.generate(events.length, (index) => index);
    order.sort((a, b) {
      final byStart = events[a].startBeat.compareTo(events[b].startBeat);
      return byStart != 0 ? byStart : a.compareTo(b);
    });

    var activeEnd = double.negativeInfinity;
    var activeIndex = -1;
    for (final index in order) {
      final event = events[index];
      if (!event.startBeat.isFinite ||
          !event.durationBeats.isFinite ||
          event.durationBeats <= 0) {
        continue;
      }
      if (activeIndex >= 0 && event.startBeat < activeEnd - _epsilon) {
        final previous = events[activeIndex];
        final bothNotes = event.isNote && previous.isNote;
        final sameStart =
            (event.startBeat - previous.startBeat).abs() <= _epsilon;
        final code = bothNotes
            ? (sameStart ? 'monophonic.chord' : 'monophonic.overlap')
            : 'event.overlap';
        final message = code == 'monophonic.chord'
            ? 'Note events at beat ${_format(event.startBeat)} form a chord or double stop; V1 is monophonic.'
            : 'Event at beat ${_format(event.startBeat)} overlaps an event ending at beat ${_format(activeEnd)}.';
        _error(
          issues,
          code,
          message,
          '$phrasePath.events[$index]',
          phraseId: phraseId,
          eventIndex: index,
        );
      }
      if (event.endBeat > activeEnd) {
        activeEnd = event.endBeat;
        activeIndex = index;
      }
    }
  }

  void _validateTies(
    Phrase phrase,
    String phrasePath,
    String? phraseId,
    List<ScoreIssue> issues,
  ) {
    for (var index = 0; index < phrase.events.length; index++) {
      final event = phrase.events[index];
      if (!event.tieToNext || !event.isNote) continue;
      if (!event.startBeat.isFinite || !event.durationBeats.isFinite) continue;

      final eventPath = '$phrasePath.events[$index].tieToNext';
      if (index + 1 >= phrase.events.length) {
        _error(
          issues,
          'tie.dangling',
          'A tied note must be followed by its continuation.',
          eventPath,
          phraseId: phraseId,
          eventIndex: index,
        );
        continue;
      }

      final next = phrase.events[index + 1];
      if (!next.isNote) {
        _error(
          issues,
          'tie.mismatch',
          'A tie must continue into another note, not a rest.',
          eventPath,
          phraseId: phraseId,
          eventIndex: index,
        );
        continue;
      }

      final gap = next.startBeat - event.endBeat;
      if (!gap.isFinite || gap.abs() > _epsilon) {
        _error(
          issues,
          'tie.notAdjacent',
          'A tied continuation must start at beat ${_format(event.endBeat)}.',
          eventPath,
          phraseId: phraseId,
          eventIndex: index,
        );
        continue;
      }

      final sameSounding = next.soundingMidi == event.soundingMidi;
      final sameWritten = next.writtenNote?.id == event.writtenNote?.id;
      final eventHasPosition = event.string != null || event.fret != null;
      final nextHasPosition = next.string != null || next.fret != null;
      final samePosition =
          (!eventHasPosition && !nextHasPosition) ||
          (event.string != null &&
              event.fret != null &&
              next.string != null &&
              next.fret != null &&
              next.string == event.string &&
              next.fret == event.fret);
      if (!sameSounding || !sameWritten || !samePosition) {
        _error(
          issues,
          'tie.mismatch',
          'A tie must continue the same written pitch; when either side names a position, both sides must use the same string and fret.',
          eventPath,
          phraseId: phraseId,
          eventIndex: index,
        );
      }
    }
  }

  void _validateBars(
    Phrase phrase,
    String phrasePath,
    String? phraseId,
    List<ScoreIssue> issues,
  ) {
    if (!phrase.timeSignature.isValid ||
        phrase.bars < 1 ||
        phrase.bars > Phrase.maxV1Bars) {
      return;
    }
    if (!phrase.pickupBeats.isFinite ||
        phrase.pickupBeats < 0 ||
        phrase.pickupBeats >= phrase.timeSignature.beatsPerBar) {
      return;
    }

    final beatsPerBar = phrase.timeSignature.beatsPerBar;
    final spans = <({int number, double start, double end})>[];
    var cursor = 0.0;
    for (var bar = 1; bar <= phrase.bars; bar++) {
      final length = bar == 1 && phrase.pickupBeats > 0
          ? phrase.pickupBeats
          : beatsPerBar;
      spans.add((number: bar, start: cursor, end: cursor + length));
      cursor += length;
    }

    final expectedTotal = cursor;
    final actualTotal = phrase.totalBeats;
    if ((actualTotal - expectedTotal).abs() > _epsilon) {
      _error(
        issues,
        'phrase.barCountMismatch',
        'Phrase has ${phrase.bars} bar(s) of ${phrase.timeSignature} (${_format(expectedTotal)} beats) but its events span ${_format(actualTotal)} beats.',
        '$phrasePath.bars',
        phraseId: phraseId,
      );
    }

    for (final span in spans) {
      final covered = _coveredBeats(phrase.events, span.start, span.end);
      final length = span.end - span.start;
      if ((covered - length).abs() > _epsilon) {
        _error(
          issues,
          'bar.durationMismatch',
          'Bar ${span.number} covers ${_format(covered)} of ${_format(length)} beats.',
          '$phrasePath.events',
          phraseId: phraseId,
        );
      }
    }
  }

  double _coveredBeats(List<NoteEvent> events, double barStart, double barEnd) {
    final intervals = <({double start, double end})>[];
    for (final event in events) {
      if (!event.startBeat.isFinite ||
          !event.durationBeats.isFinite ||
          event.durationBeats <= 0) {
        continue;
      }
      final start = event.startBeat > barStart ? event.startBeat : barStart;
      final end = event.endBeat < barEnd ? event.endBeat : barEnd;
      if (end > start) intervals.add((start: start, end: end));
    }
    intervals.sort((a, b) => a.start.compareTo(b.start));

    var covered = 0.0;
    double? currentStart;
    double? currentEnd;
    for (final interval in intervals) {
      if (currentStart == null) {
        currentStart = interval.start;
        currentEnd = interval.end;
        continue;
      }
      final start = currentStart;
      final end = currentEnd!;
      if (interval.start <= end + _epsilon) {
        if (interval.end > end) currentEnd = interval.end;
      } else {
        covered += end - start;
        currentStart = interval.start;
        currentEnd = interval.end;
      }
    }
    if (currentStart != null) {
      covered += currentEnd! - currentStart;
    }
    return covered;
  }

  String _format(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
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
