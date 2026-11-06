import 'note_event.dart';
import 'phrase.dart';
import 'score.dart';

/// Severity of a playability finding.
///
/// Every rule in this file is a hard error for a generated candidate. The
/// warning severity is reserved for feedback that depends on a human musical
/// judgement, such as an unknown key name.
enum PlayabilitySeverity { error, warning }

/// One typed playability finding with a phrase, bar, and event location.
///
/// [bar] is 1-based inside the phrase. [eventIndex] is the index in
/// `Phrase.events`, so a reviewer can open the exact note. Unlike
/// [ScoreIssue], this type carries the bar number because a playability
/// verdict is read bar by bar, not field by field.
class PlayabilityIssue {
  const PlayabilityIssue({
    required this.code,
    required this.message,
    this.severity = PlayabilitySeverity.error,
    this.phraseIndex,
    this.phraseId,
    this.bar,
    this.eventIndex,
  });

  final String code;
  final String message;
  final PlayabilitySeverity severity;
  final int? phraseIndex;
  final String? phraseId;
  final int? bar;
  final int? eventIndex;

  bool get isError => severity == PlayabilitySeverity.error;

  bool get isWarning => severity == PlayabilitySeverity.warning;

  /// Human-readable location, for example `phrase etude-l1-01-p1, bar 2`.
  String get location {
    final parts = <String>[];
    if (phraseId != null && phraseId!.isNotEmpty) {
      parts.add('phrase $phraseId');
    } else if (phraseIndex != null) {
      parts.add('phrase ${phraseIndex! + 1}');
    }
    if (bar != null) parts.add('bar $bar');
    if (eventIndex != null) parts.add('event $eventIndex');
    return parts.isEmpty ? 'score' : parts.join(', ');
  }

  @override
  String toString() => '${severity.name} $code at $location: $message';
}

/// A deliberate hand-position move found by [PlayabilityValidator.findShifts].
///
/// A shift is either a phrase-to-phrase first/second-position change or a
/// fretted leap wider than [PlayabilityLimits.maxStretch].
class PlayabilityShift {
  const PlayabilityShift({
    required this.phraseIndex,
    required this.phraseId,
    required this.bar,
    required this.eventIndex,
    required this.fromPosition,
    required this.toPosition,
    this.fretDistance,
  });

  final int phraseIndex;
  final String phraseId;
  final int bar;
  final int eventIndex;

  /// `first`, `second`, or `neutral` for the phrase before the shift.
  final String fromPosition;

  /// `first`, `second`, or `neutral` for the phrase after the shift.
  final String toPosition;

  /// Fret distance for a within-phrase leap, or null for a phrase-level move.
  final int? fretDistance;

  @override
  String toString() =>
      'shift at phrase $phraseId bar $bar event $eventIndex '
      '($fromPosition -> $toPosition)';
}

/// Limits a score must satisfy to count as playable.
///
/// The defaults are the broad V1 beginner envelope. A level grammar passes a
/// narrower instance, for example frets 0-3 on strings 1-3 for level 1. The
/// validator never changes the limits on its own; a caller that wants a
/// stricter level supplies them.
class PlayabilityLimits {
  const PlayabilityLimits({
    this.minString = 1,
    this.maxString = 6,
    this.minFret = 0,
    this.maxFret = 19,
    this.minWrittenMidi = 52, // E3
    this.maxWrittenMidi = 88, // E6
    this.maxStretch = 4,
    this.maxStringSkip = 3,
    this.maxShifts = 1000,
    this.maxShiftDistance = 7,
    this.requireOpenString = false,
    this.maxConsecutiveRepeatedNotes = 4,
    this.allowedDurations = const <double>[0.5, 1.0, 1.5, 2.0, 3.0],
    this.requireTonicCadence = true,
    this.maxCadenceApproachSemitones = 2,
    this.tonicPitchClass,
  });

  /// Inclusive string range. 1 = high E, 6 = low E.
  final int minString;
  final int maxString;

  /// Inclusive fret range. 0 = open string.
  final int minFret;
  final int maxFret;

  /// Inclusive written-pitch range. Guitar sounds one octave below this.
  final int minWrittenMidi;
  final int maxWrittenMidi;

  /// Largest fret span one hand position may cover inside a phrase.
  final int maxStretch;

  /// Largest allowed string jump between consecutive notes.
  final int maxStringSkip;

  /// Maximum number of deliberate shifts in the score.
  final int maxShifts;

  /// A single shift wider than this many frets is flagged as awkward.
  final int maxShiftDistance;

  /// Whether the score must use at least one open string.
  final bool requireOpenString;

  /// Longest allowed run of the same written pitch.
  final int maxConsecutiveRepeatedNotes;

  /// Durations allowed by the level rhythm grammar, in quarter-note beats.
  final List<double> allowedDurations;

  /// Whether the final note must be the tonic.
  final bool requireTonicCadence;

  /// Largest semitone interval allowed into the final tonic.
  final int maxCadenceApproachSemitones;

  /// Optional tonic override. When null, the key name is parsed.
  final int? tonicPitchClass;
}

/// A score plus the playability verdict.
///
/// [isValid] requires both `Score.validate()` and the playability rules to
/// pass. A caller must never treat a playability pass as a substitute for the
/// structural score checks.
class ScorePlayabilityReport {
  const ScorePlayabilityReport({
    required this.scoreIssues,
    required this.playabilityIssues,
  });

  final List<ScoreIssue> scoreIssues;
  final List<PlayabilityIssue> playabilityIssues;

  bool get hasErrors =>
      scoreIssues.any((issue) => issue.isError) ||
      playabilityIssues.any((issue) => issue.isError);

  bool get isValid => !hasErrors;
}

/// Validates the guitar-specific playability rules on a parsed [Score].
///
/// The structural model checks stay in [Score.validate]. This validator adds
/// the rules a beginner guitar reader cares about: stretch, string crossings,
/// shifts, open strings, repeated notes, range, rhythm cells, and cadence.
class PlayabilityValidator {
  const PlayabilityValidator(
    this.score, {
    this.limits = const PlayabilityLimits(),
  });

  final Score score;
  final PlayabilityLimits limits;

  static const double _epsilon = 1e-9;

  List<PlayabilityIssue> validate() {
    final issues = <PlayabilityIssue>[];
    for (
      var phraseIndex = 0;
      phraseIndex < score.phrases.length;
      phraseIndex++
    ) {
      final phrase = score.phrases[phraseIndex];
      _validateRange(phrase, phraseIndex, issues);
      _validateRhythmCells(phrase, phraseIndex, issues);
      _validateStretch(phrase, phraseIndex, issues);
      _validateStringCrossings(phrase, phraseIndex, issues);
      _validateRepeatedNotes(phrase, phraseIndex, issues);
    }
    _validateOpenStrings(issues);
    _validateShifts(issues);
    _validateCadence(issues);
    return issues;
  }

  /// Every shift in the score, whether or not it exceeds the limits.
  List<PlayabilityShift> findShifts() {
    final shifts = <PlayabilityShift>[];
    final seen = <String>{};
    String? previousPosition;

    for (
      var phraseIndex = 0;
      phraseIndex < score.phrases.length;
      phraseIndex++
    ) {
      final phrase = score.phrases[phraseIndex];
      final position = phrasePosition(phrase);
      final firstNote = _firstNote(phrase);
      if (previousPosition != null &&
          position != null &&
          firstNote != null &&
          _isFirstOrSecond(previousPosition) &&
          _isFirstOrSecond(position) &&
          previousPosition != position) {
        final key = '$phraseIndex:${firstNote.index}';
        shifts.add(
          PlayabilityShift(
            phraseIndex: phraseIndex,
            phraseId: phrase.id,
            bar: _barFor(phrase, firstNote.event.startBeat),
            eventIndex: firstNote.index,
            fromPosition: previousPosition,
            toPosition: position,
          ),
        );
        seen.add(key);
      }
      if (position != null) previousPosition = position;

      int? previousFret;
      for (
        var eventIndex = 0;
        eventIndex < phrase.events.length;
        eventIndex++
      ) {
        final event = phrase.events[eventIndex];
        if (!event.isNote || event.fret == null) continue;
        final fret = event.fret!;
        if (fret == 0) continue;
        if (previousFret != null &&
            (fret - previousFret).abs() > limits.maxStretch) {
          final key = '$phraseIndex:$eventIndex';
          if (seen.add(key)) {
            shifts.add(
              PlayabilityShift(
                phraseIndex: phraseIndex,
                phraseId: phrase.id,
                bar: _barFor(phrase, event.startBeat),
                eventIndex: eventIndex,
                fromPosition: position ?? 'neutral',
                toPosition: position ?? 'neutral',
                fretDistance: (fret - previousFret).abs(),
              ),
            );
          }
        }
        previousFret = fret;
      }
    }
    return shifts;
  }

  /// Classifies a phrase as `first`, `second`, or `neutral`.
  ///
  /// This mirrors the T3.6 rubric: first position uses a fret 0-1 and no fret
  /// 4-5, second position uses a fret 4-5 and no fret 0-1. A phrase that uses
  /// both, or neither, is neutral and does not count as a position change.
  static String? phrasePosition(Phrase phrase) {
    var hasFirst = false;
    var hasSecond = false;
    for (final note in phrase.notes) {
      final fret = note.fret;
      if (fret == null) continue;
      if (fret <= 1) hasFirst = true;
      if (fret >= 4) hasSecond = true;
    }
    if (hasFirst && !hasSecond) return 'first';
    if (hasSecond && !hasFirst) return 'second';
    return null;
  }

  /// Parses the tonic pitch class from a key name such as `G major` or
  /// `A minor`. Returns null for an unsupported key spelling.
  static int? tonicPitchClassForKey(String key) {
    final match = RegExp(r'^([A-Ga-g])([#b]?)').firstMatch(key.trim());
    if (match == null) return null;
    final name = '${match.group(1)!.toLowerCase()}${match.group(2) ?? ''}';
    return _pitchClasses[name];
  }

  static const Map<String, int> _pitchClasses = <String, int>{
    'c': 0,
    'c#': 1,
    'db': 1,
    'd': 2,
    'd#': 3,
    'eb': 3,
    'e': 4,
    'f': 5,
    'f#': 6,
    'gb': 6,
    'g': 7,
    'g#': 8,
    'ab': 8,
    'a': 9,
    'a#': 10,
    'bb': 10,
    'b': 11,
  };

  void _validateRange(
    Phrase phrase,
    int phraseIndex,
    List<PlayabilityIssue> issues,
  ) {
    for (var eventIndex = 0; eventIndex < phrase.events.length; eventIndex++) {
      final event = phrase.events[eventIndex];
      if (!event.isNote) continue;
      final bar = _barFor(phrase, event.startBeat);
      final written = event.writtenNote;
      if (written != null &&
          (written.midi < limits.minWrittenMidi ||
              written.midi > limits.maxWrittenMidi)) {
        _add(
          issues,
          code: 'playability.writtenRange',
          message:
              'Written ${written.id} is outside the allowed range '
              '${_midiName(limits.minWrittenMidi)}-'
              '${_midiName(limits.maxWrittenMidi)}.',
          phrase: phrase,
          phraseIndex: phraseIndex,
          bar: bar,
          eventIndex: eventIndex,
        );
      }

      final string = event.string;
      if (string != null &&
          (string < limits.minString || string > limits.maxString)) {
        _add(
          issues,
          code: 'playability.stringRange',
          message:
              'String $string is outside the allowed strings '
              '${limits.minString}-${limits.maxString}.',
          phrase: phrase,
          phraseIndex: phraseIndex,
          bar: bar,
          eventIndex: eventIndex,
        );
      }

      final fret = event.fret;
      if (fret != null && (fret < limits.minFret || fret > limits.maxFret)) {
        _add(
          issues,
          code: 'playability.fretRange',
          message:
              'Fret $fret is outside the allowed frets '
              '${limits.minFret}-${limits.maxFret}.',
          phrase: phrase,
          phraseIndex: phraseIndex,
          bar: bar,
          eventIndex: eventIndex,
        );
      }
    }
  }

  void _validateRhythmCells(
    Phrase phrase,
    int phraseIndex,
    List<PlayabilityIssue> issues,
  ) {
    for (var eventIndex = 0; eventIndex < phrase.events.length; eventIndex++) {
      final event = phrase.events[eventIndex];
      if (!_durationAllowed(event.durationBeats)) {
        _add(
          issues,
          code: 'playability.rhythmCell',
          message:
              'Duration ${_format(event.durationBeats)} is not one of the '
              'allowed rhythm cells ${_allowedDurationsText()}.',
          phrase: phrase,
          phraseIndex: phraseIndex,
          bar: _barFor(phrase, event.startBeat),
          eventIndex: eventIndex,
        );
      }
    }
  }

  void _validateStretch(
    Phrase phrase,
    int phraseIndex,
    List<PlayabilityIssue> issues,
  ) {
    int? low;
    int? high;
    int? highIndex;
    for (var eventIndex = 0; eventIndex < phrase.events.length; eventIndex++) {
      final event = phrase.events[eventIndex];
      final fret = event.fret;
      if (!event.isNote || fret == null || fret == 0) continue;
      if (low == null || fret < low) low = fret;
      if (high == null || fret > high) {
        high = fret;
        highIndex = eventIndex;
      }
    }
    if (low == null || high == null || highIndex == null) return;
    if (high - low <= limits.maxStretch) return;

    final event = phrase.events[highIndex];
    _add(
      issues,
      code: 'playability.stretch',
      message:
          'This phrase reaches frets $low-$high; one hand position may span '
          '${limits.maxStretch} frets. Split the phrase or move a note into '
          'the position.',
      phrase: phrase,
      phraseIndex: phraseIndex,
      bar: _barFor(phrase, event.startBeat),
      eventIndex: highIndex,
    );
  }

  void _validateStringCrossings(
    Phrase phrase,
    int phraseIndex,
    List<PlayabilityIssue> issues,
  ) {
    final notes = phrase.notes;
    for (var index = 1; index < notes.length; index++) {
      final previous = notes[index - 1].string;
      final current = notes[index].string;
      if (previous == null || current == null) continue;
      final jump = (current - previous).abs();
      if (jump <= limits.maxStringSkip) continue;
      _add(
        issues,
        code: 'playability.stringCrossing',
        message:
            'String $previous to string $current skips $jump strings; at most '
            '${limits.maxStringSkip} are allowed between consecutive notes.',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, notes[index].startBeat),
        eventIndex: phrase.events.indexOf(notes[index]),
      );
    }
  }

  void _validateRepeatedNotes(
    Phrase phrase,
    int phraseIndex,
    List<PlayabilityIssue> issues,
  ) {
    var run = 1;
    for (var index = 1; index < phrase.notes.length; index++) {
      final previous = phrase.notes[index - 1].writtenNote?.id;
      final current = phrase.notes[index].writtenNote?.id;
      if (previous != null && previous == current) {
        run++;
        if (run == limits.maxConsecutiveRepeatedNotes + 1) {
          _add(
            issues,
            code: 'playability.repeatedNote',
            message:
                'The same note repeats ${limits.maxConsecutiveRepeatedNotes + 1} '
                'times in a row; the limit is '
                '${limits.maxConsecutiveRepeatedNotes}.',
            phrase: phrase,
            phraseIndex: phraseIndex,
            bar: _barFor(phrase, phrase.notes[index].startBeat),
            eventIndex: phrase.events.indexOf(phrase.notes[index]),
          );
        }
      } else {
        run = 1;
      }
    }
  }

  void _validateOpenStrings(List<PlayabilityIssue> issues) {
    if (!limits.requireOpenString) return;
    for (final phrase in score.phrases) {
      if (phrase.notes.any((note) => note.fret == 0)) return;
    }
    issues.add(
      const PlayabilityIssue(
        code: 'playability.noOpenString',
        message: 'This level requires at least one open string.',
      ),
    );
  }

  void _validateShifts(List<PlayabilityIssue> issues) {
    final shifts = findShifts();
    if (shifts.length > limits.maxShifts) {
      final excess = shifts[limits.maxShifts < 0 ? 0 : limits.maxShifts];
      _add(
        issues,
        code: 'playability.tooManyShifts',
        message:
            'This score has ${shifts.length} position shifts; the level allows '
            '${limits.maxShifts}.',
        phrase: score.phrases[excess.phraseIndex],
        phraseIndex: excess.phraseIndex,
        bar: excess.bar,
        eventIndex: excess.eventIndex,
      );
    }
    for (final shift in shifts) {
      final distance = shift.fretDistance;
      if (distance == null || distance <= limits.maxShiftDistance) continue;
      _add(
        issues,
        code: 'playability.shiftTooFar',
        message:
            'A $distance-fret shift is wider than the '
            '${limits.maxShiftDistance}-fret limit.',
        phrase: score.phrases[shift.phraseIndex],
        phraseIndex: shift.phraseIndex,
        bar: shift.bar,
        eventIndex: shift.eventIndex,
      );
    }
  }

  void _validateCadence(List<PlayabilityIssue> issues) {
    if (!limits.requireTonicCadence) return;
    if (score.phrases.isEmpty) return;
    final phrase = score.phrases.last;
    final phraseIndex = score.phrases.length - 1;
    final notes = phrase.notes;
    if (notes.isEmpty || !phrase.events.last.isNote) {
      _add(
        issues,
        code: 'playability.cadence',
        message: 'The etude must end on a note, not a rest.',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, phrase.events.last.startBeat),
        eventIndex: phrase.events.length - 1,
      );
      return;
    }

    final last = notes.last;
    final written = last.writtenNote;
    if (written == null) return;
    final tonic =
        limits.tonicPitchClass ?? tonicPitchClassForKey(score.piece.key);
    if (tonic == null) {
      _add(
        issues,
        severity: PlayabilitySeverity.warning,
        code: 'playability.unknownKey',
        message:
            'Cannot parse a tonic from key "${score.piece.key}"; the cadence '
            'check was skipped.',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, last.startBeat),
        eventIndex: phrase.events.indexOf(last),
      );
      return;
    }

    if (written.midi % 12 != tonic) {
      _add(
        issues,
        code: 'playability.cadence',
        message:
            'The final note ${written.id} is not the tonic '
            '(${_pitchClassName(tonic)}).',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, last.startBeat),
        eventIndex: phrase.events.indexOf(last),
      );
    }

    if (notes.length < 2) {
      _add(
        issues,
        code: 'playability.cadenceApproach',
        message: 'The cadence needs a second note to approach the tonic.',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, last.startBeat),
        eventIndex: phrase.events.indexOf(last),
      );
      return;
    }

    final previous = notes[notes.length - 2].writtenNote;
    if (previous == null) return;
    final approach = (written.midi - previous.midi).abs();
    if (approach > limits.maxCadenceApproachSemitones) {
      _add(
        issues,
        code: 'playability.cadenceApproach',
        message:
            'The final approach is $approach semitones; use a step or '
            'half-step (at most ${limits.maxCadenceApproachSemitones}).',
        phrase: phrase,
        phraseIndex: phraseIndex,
        bar: _barFor(phrase, last.startBeat),
        eventIndex: phrase.events.indexOf(last),
      );
    }
  }

  bool _durationAllowed(double duration) {
    for (final allowed in limits.allowedDurations) {
      if ((duration - allowed).abs() <= _epsilon) return true;
    }
    return false;
  }

  String _allowedDurationsText() {
    final values = limits.allowedDurations.toList()..sort();
    return values.map(_format).join(', ');
  }

  ({int index, NoteEvent event})? _firstNote(Phrase phrase) {
    for (var index = 0; index < phrase.events.length; index++) {
      if (phrase.events[index].isNote) {
        return (index: index, event: phrase.events[index]);
      }
    }
    return null;
  }

  int _barFor(Phrase phrase, double beat) {
    if (phrase.timeSignature.beatsPerBar <= 0 || phrase.bars < 1) return 1;
    final beatsPerBar = phrase.timeSignature.beatsPerBar;
    int bar;
    if (phrase.pickupBeats > 0) {
      if (beat < phrase.pickupBeats) {
        bar = 1;
      } else {
        bar = 2 + ((beat - phrase.pickupBeats) / beatsPerBar).floor();
      }
    } else {
      bar = 1 + (beat / beatsPerBar).floor();
    }
    if (bar < 1) return 1;
    if (bar > phrase.bars) return phrase.bars;
    return bar;
  }

  bool _isFirstOrSecond(String position) =>
      position == 'first' || position == 'second';

  void _add(
    List<PlayabilityIssue> issues, {
    required String code,
    required String message,
    required Phrase phrase,
    required int phraseIndex,
    required int bar,
    required int eventIndex,
    PlayabilitySeverity severity = PlayabilitySeverity.error,
  }) {
    issues.add(
      PlayabilityIssue(
        severity: severity,
        code: code,
        message: message,
        phraseIndex: phraseIndex,
        phraseId: phrase.id.isEmpty ? null : phrase.id,
        bar: bar,
        eventIndex: eventIndex,
      ),
    );
  }

  String _format(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _midiName(int midi) {
    const names = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    return '${names[midi % 12]}${midi ~/ 12 - 1}';
  }

  String _pitchClassName(int pitchClass) {
    const names = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    return names[pitchClass % 12];
  }
}

/// Runs [Score.validate] and [PlayabilityValidator.validate] together.
///
/// A candidate is valid only when both lists have no errors. A playability
/// pass never hides a structural error, and a structural pass never hides an
/// unplayable line.
ScorePlayabilityReport validateCandidateScore(
  Score score, {
  PlayabilityLimits limits = const PlayabilityLimits(),
}) {
  return ScorePlayabilityReport(
    scoreIssues: score.validate(),
    playabilityIssues: PlayabilityValidator(score, limits: limits).validate(),
  );
}
