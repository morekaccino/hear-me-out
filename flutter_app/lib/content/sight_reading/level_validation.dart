import '../../core/music/playability.dart';
import 'etude_generator.dart';
import 'level_spec.dart';

/// One level-grammar finding for a generated candidate.
class LevelGrammarIssue {
  const LevelGrammarIssue({
    required this.code,
    required this.message,
    this.phraseIndex,
    this.eventIndex,
  });

  final String code;
  final String message;
  final int? phraseIndex;
  final int? eventIndex;

  @override
  String toString() {
    final parts = <String>[];
    if (phraseIndex != null) parts.add('phrase ${phraseIndex! + 1}');
    if (eventIndex != null) parts.add('event $eventIndex');
    final location = parts.isEmpty ? '' : ' at ${parts.join(', ')}';
    return '$code$location: $message';
  }
}

/// Checks that a [GeneratedEtude] really follows its declared level grammar.
///
/// The playability validator covers the per-note rules (stretch, crossings,
/// rhythm cells, cadence, accidentals). This check covers the level contract
/// that a score alone cannot express: the candidate's declared level, total
/// bars, phrase plan, tempo, meter, key, positions, required rhythm cells, and
/// shift budget. The CLI and the approval gate run both.
List<LevelGrammarIssue> validateLevelGrammar(GeneratedEtude etude) {
  final issues = <LevelGrammarIssue>[];
  final spec = etude.spec;
  final score = etude.score;

  void add(String code, String message, {int? phraseIndex, int? eventIndex}) {
    issues.add(
      LevelGrammarIssue(
        code: code,
        message: message,
        phraseIndex: phraseIndex,
        eventIndex: eventIndex,
      ),
    );
  }

  if (etude.level != spec.level) {
    add(
      'grammar.levelMismatch',
      'The candidate declares level ${etude.level}, but its grammar is '
          'level ${spec.level}.',
    );
  }

  final totalBars = score.phrases.fold<int>(
    0,
    (sum, phrase) => sum + phrase.bars,
  );
  if (totalBars != spec.totalBars) {
    add(
      'grammar.totalBars',
      'Level ${spec.level} uses ${spec.totalBars} bars; this candidate has '
          '$totalBars.',
    );
  }
  if (score.phrases.length != spec.phrasePlan.length) {
    add(
      'grammar.phraseCount',
      'Level ${spec.level} uses ${spec.phrasePlan.length} phrases; this '
          'candidate has ${score.phrases.length}.',
    );
  }
  if (!spec.allowedMeters.contains(score.piece.timeSignature)) {
    add(
      'grammar.meter',
      'Meter ${score.piece.timeSignature} is not allowed at level '
          '${spec.level}.',
    );
  }
  if (!spec.allowedKeys.any((key) => key.name == score.piece.key)) {
    add(
      'grammar.key',
      'Key "${score.piece.key}" is not allowed at level ${spec.level}.',
    );
  }

  final durations = <double>{};
  for (var phraseIndex = 0; phraseIndex < score.phrases.length; phraseIndex++) {
    final phrase = score.phrases[phraseIndex];
    if (phraseIndex < spec.phrasePlan.length) {
      final plan = spec.phrasePlan[phraseIndex];
      if (phrase.bars != plan.bars) {
        add(
          'grammar.phraseBars',
          'Phrase ${phraseIndex + 1} uses ${phrase.bars} bars; the level plan '
              'uses ${plan.bars}.',
          phraseIndex: phraseIndex,
        );
      }
      final expected = plan.position == EtudePosition.first
          ? 'first'
          : 'second';
      final actual = PlayabilityValidator.phrasePosition(phrase);
      if (actual != expected) {
        add(
          'grammar.position',
          'Phrase ${phraseIndex + 1} is ${actual ?? 'neutral'} position; the '
              'level plan expects $expected.',
          phraseIndex: phraseIndex,
        );
      }
    }
    if (phrase.targetTempoBpm != spec.tempoBpm) {
      add(
        'grammar.tempo',
        'Phrase ${phraseIndex + 1} targets ${phrase.targetTempoBpm} BPM; the '
            'level uses ${spec.tempoBpm}.',
        phraseIndex: phraseIndex,
      );
    }

    for (var eventIndex = 0; eventIndex < phrase.events.length; eventIndex++) {
      final event = phrase.events[eventIndex];
      durations.add(event.durationBeats);
      if (!event.isNote) continue;
      final string = event.string;
      if (string == null || !spec.allowedStrings.contains(string)) {
        add(
          'grammar.string',
          'String ${string ?? '(missing)'} is outside the level strings '
              '${spec.allowedStrings.first}-${spec.allowedStrings.last}.',
          phraseIndex: phraseIndex,
          eventIndex: eventIndex,
        );
      }
      final fret = event.fret;
      if (fret == null || fret < spec.minFret || fret > spec.maxFret) {
        add(
          'grammar.fret',
          'Fret ${fret ?? '(missing)'} is outside the level frets '
              '${spec.minFret}-${spec.maxFret}.',
          phraseIndex: phraseIndex,
          eventIndex: eventIndex,
        );
      }
    }

    final notes = phrase.notes;
    for (var index = 1; index < notes.length; index++) {
      final previous = notes[index - 1].writtenNote?.midi;
      final current = notes[index].writtenNote?.midi;
      if (previous == null || current == null) continue;
      final interval = (current - previous).abs();
      if (interval > spec.maxIntervalSemitones) {
        add(
          'grammar.interval',
          'A $interval-semitone interval exceeds the level limit of '
              '${spec.maxIntervalSemitones}.',
          phraseIndex: phraseIndex,
          eventIndex: phrase.events.indexOf(notes[index]),
        );
      }
    }
  }

  for (final required in spec.requiredRhythmCells) {
    if (!durations.any((duration) => (duration - required).abs() < 1e-9)) {
      add(
        'grammar.requiredRhythmCell',
        'The level requires the rhythm cell $required.',
      );
    }
  }
  if (spec.requiresDottedRhythm &&
      !durations.any(
        (duration) =>
            (duration - 1.5).abs() < 1e-9 || (duration - 3.0).abs() < 1e-9,
      )) {
    add('grammar.dottedRhythm', 'The level requires a dotted rhythm cell.');
  }
  if (spec.requiresRest &&
      !score.phrases.any(
        (phrase) => phrase.events.any((event) => event.isRest),
      )) {
    add('grammar.rest', 'The level requires at least one rest.');
  }
  if (spec.requiresOpenString &&
      !score.phrases.any(
        (phrase) => phrase.notes.any((note) => note.fret == 0),
      )) {
    add('grammar.openString', 'The level requires at least one open string.');
  }

  final keyClasses = PlayabilityValidator.keyPitchClassesForKey(
    score.piece.key,
  );
  if (keyClasses != null) {
    final accidentals = <int>{
      for (final phrase in score.phrases)
        for (final note in phrase.notes)
          if (note.writtenNote != null) note.writtenNote!.midi % 12,
    }.difference(keyClasses);
    if (accidentals.length < spec.minAccidentals ||
        accidentals.length > spec.maxAccidentals) {
      add(
        'grammar.accidentalCount',
        'The level allows ${spec.minAccidentals}-${spec.maxAccidentals} '
            'accidental pitch class(es); this candidate has '
            '${accidentals.length}.',
      );
    }
  }

  final shifts = PlayabilityValidator(
    score,
    limits: spec.playabilityLimits,
  ).findShifts();
  if (shifts.length != spec.maxShifts) {
    add(
      'grammar.shiftCount',
      'The level uses ${spec.maxShifts} position shift(s); this candidate has '
          '${shifts.length}.',
    );
  }
  return issues;
}
