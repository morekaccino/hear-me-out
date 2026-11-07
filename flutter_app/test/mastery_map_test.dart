import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/core/learning/mastery_map.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/music/score.dart';

const _events = <NoteEvent>[
  NoteEvent(
    startBeat: 0,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('G', 3),
    soundingMidi: 43,
    string: 6,
    fret: 3,
  ),
  NoteEvent(
    startBeat: 1,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('A', 3),
    soundingMidi: 45,
    string: 5,
    fret: 0,
  ),
  NoteEvent(
    startBeat: 2,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('B', 3),
    soundingMidi: 47,
    string: 5,
    fret: 2,
  ),
  NoteEvent(
    startBeat: 3,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: Note('C', 4),
    soundingMidi: 48,
    string: 5,
    fret: 3,
  ),
];

Piece _piece() => Piece(
  id: 'study',
  title: 'Original Study',
  composer: 'Hear Me Out',
  license: 'original',
  tuning: Tuning.standard,
  timeSignature: const TimeSignature(4, 4),
  key: 'G major',
);

Phrase _phrase({
  required String id,
  required String title,
  int difficulty = 1,
  int tempo = 72,
}) => Phrase(
  id: id,
  bars: 1,
  timeSignature: const TimeSignature(4, 4),
  events: _events,
  targetTempoBpm: tempo,
  title: title,
  skills: const <String>['note-reading.first-position'],
  difficulty: difficulty,
);

Score _score(List<Phrase> phrases) => Score(piece: _piece(), phrases: phrases);

PhraseProgress _masteredPhrase(String id) {
  final progress = PhraseProgress(phraseId: id);
  for (final day in [
    DateTime(2026, 1, 1, 10),
    DateTime(2026, 1, 5, 10),
    DateTime(2026, 1, 12, 10),
  ]) {
    progress.recordAttempt(
      PhraseAttempt(
        phraseId: id,
        outcome: AttemptOutcome.correct,
        now: day,
        accuracy: 1,
        tempoBpm: 72,
        targetTempoBpm: 72,
      ),
    );
  }
  return progress;
}

SkillProgress _masteredReading(String objectiveId, SkillFamily family) {
  return SkillProgress(
    objectiveId: objectiveId,
    family: family,
    stabilityDays: 30,
    reps: 5,
    correct: 5,
    correctDays: <String>{'2026-01-01', '2026-01-05', '2026-01-12'},
    productionCorrect: 1,
    transferCorrect: 1,
    masteredAt: DateTime(2026, 1, 12),
  );
}

SkillProgress _skill({
  required String objectiveId,
  required SkillFamily family,
  bool fragile = false,
  DateTime? dueAt,
}) {
  return SkillProgress(
    objectiveId: objectiveId,
    family: family,
    reps: fragile ? 4 : 2,
    correct: 1,
    incorrect: fragile ? 3 : 1,
    lapses: fragile ? 2 : 0,
    fragile: fragile,
    dueAt: dueAt,
    lastSeenAt: DateTime(2026, 1, 20),
  );
}

void main() {
  final now = DateTime(2026, 2, 1, 10);

  PhraseObjectiveRegistry registryWith(Phrase first, {Phrase? second}) {
    return PhraseObjectiveRegistry()..registerScore(_score([first, ?second]));
  }

  test('can play needs performance mastery, not raw phrase attempts', () {
    final registry = registryWith(
      _phrase(id: 'study-p1', title: 'Rising line'),
      second: _phrase(id: 'study-p2', title: 'Answer line', difficulty: 2),
    );
    final progress = ProgressState(
      phraseProgress: {
        'study-p1': _masteredPhrase('study-p1'),
        'study-p2': PhraseProgress(phraseId: 'study-p2')
          ..recordAttempt(
            PhraseAttempt(
              phraseId: 'study-p2',
              outcome: AttemptOutcome.correct,
              now: DateTime(2026, 1, 1),
              accuracy: 1,
              tempoBpm: 72,
              targetTempoBpm: 72,
            ),
          )
          ..recordAttempt(
            PhraseAttempt(
              phraseId: 'study-p2',
              outcome: AttemptOutcome.correct,
              now: DateTime(2026, 1, 5),
              accuracy: 1,
              tempoBpm: 72,
              targetTempoBpm: 72,
            ),
          ),
      },
    );

    final map = MasteryMap.build(
      progress: progress,
      registry: registry,
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.canPlay, hasLength(1));
    expect(map.canPlay.single.phraseId, 'study-p1');
    expect(map.canPlay.single.kind, MasteryKind.canPlay);
  });

  test('a can-play row maps piece, phrase, tempo, date, and latest take', () {
    final registry = registryWith(
      _phrase(id: 'study-p1', title: 'Rising line'),
    );
    final progress = ProgressState(
      phraseProgress: {'study-p1': _masteredPhrase('study-p1')},
    );
    final takes = <RecordingTake>[
      RecordingTake(
        id: 'older-take',
        createdAt: DateTime.utc(2026, 1, 20, 12),
        byteLength: 1200,
        durationMs: 2000,
        pieceId: 'study',
        phraseId: 'study-p1',
      ),
      RecordingTake(
        id: 'latest-take',
        createdAt: DateTime.utc(2026, 1, 30, 12),
        byteLength: 1200,
        durationMs: 2000,
        pieceId: 'study',
        phraseId: 'study-p1',
      ),
    ];

    final map = MasteryMap.build(
      progress: progress,
      registry: registry,
      takes: takes,
      now: now,
    );

    final entry = map.canPlay.single;
    expect(entry.title, 'Rising line');
    expect(entry.subtitle, 'Original Study');
    expect(entry.pieceId, 'study');
    expect(entry.phraseId, 'study-p1');
    expect(entry.tempoBpm, 72);
    expect(entry.date, DateTime(2026, 1, 12, 10));
    expect(entry.recordingTakeId, 'latest-take');
  });

  test('a stale content version removes the can-play badge', () {
    final registry = registryWith(_phrase(id: 'study-p1', title: 'Rising line'))
      ..registerPhrase(
        piece: _piece(),
        phrase: _phrase(id: 'study-p1', title: 'Rising line'),
        contentVersion: 2,
        stage: 1,
      );
    final progress = ProgressState(
      phraseProgress: {'study-p1': _masteredPhrase('study-p1')},
    );

    final map = MasteryMap.build(
      progress: progress,
      registry: registry,
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.canPlay, isEmpty);
  });

  test('shaky holds due or fragile atomic skills, at most five', () {
    final progress = ProgressState(
      skills: {
        for (var index = 0; index < 6; index++)
          'note:E${4 + index}': _skill(
            objectiveId: 'note:E${4 + index}',
            family: SkillFamily.noteReading,
            dueAt: now.subtract(Duration(days: index + 1)),
          ),
        'rhythm:eighths': _skill(
          objectiveId: 'rhythm:eighths',
          family: SkillFamily.rhythm,
          fragile: true,
        ),
        'ear:interval:m3:melodic': _skill(
          objectiveId: 'ear:interval:m3:melodic',
          family: SkillFamily.ear,
          dueAt: now.subtract(const Duration(days: 2)),
        ),
        'interval:P5:melodic': _skill(
          objectiveId: 'interval:P5:melodic',
          family: SkillFamily.theory,
          dueAt: now.subtract(const Duration(days: 3)),
        ),
        'chord:G:maj': _skill(
          objectiveId: 'chord:G:maj',
          family: SkillFamily.harmony,
          dueAt: now.subtract(const Duration(days: 4)),
        ),
      },
    );

    final map = MasteryMap.build(
      progress: progress,
      registry: PhraseObjectiveRegistry(),
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.shaky, hasLength(5));
    final titles = map.shaky.map((entry) => entry.title).toList();
    expect(titles, isNot(contains('chord:G:maj')));
    expect(titles, contains('E9'));
    expect(map.shaky.every((entry) => entry.kind == MasteryKind.shaky), isTrue);
  });

  test('reading counts note and rhythm skills and lists a few mastered', () {
    final progress = ProgressState(
      skills: {
        'note:A4': _masteredReading('note:A4', SkillFamily.noteReading),
        'rhythm:triplets': _masteredReading(
          'rhythm:triplets',
          SkillFamily.rhythm,
        ),
        'note:E4': _skill(
          objectiveId: 'note:E4',
          family: SkillFamily.noteReading,
          dueAt: now.subtract(const Duration(days: 1)),
        ),
        'rhythm:eighths': _skill(
          objectiveId: 'rhythm:eighths',
          family: SkillFamily.rhythm,
          fragile: true,
        ),
        'ear:chordquality:C:major': _masteredReading(
          'ear:chordquality:C:major',
          SkillFamily.ear,
        ),
      },
    );

    final map = MasteryMap.build(
      progress: progress,
      registry: PhraseObjectiveRegistry(),
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.readingTrackedCount, 4);
    expect(map.readingMasteredCount, 2);
    expect(map.reading, hasLength(2));
    expect(
      map.reading.map((entry) => entry.title),
      containsAll(<String>['A4', 'Rhythm · triplets']),
    );
    expect(
      map.reading.every((entry) => entry.kind == MasteryKind.reading),
      isTrue,
    );
  });

  test('next has due atomic skills and the first unmastered phrase', () {
    final registry = registryWith(
      _phrase(id: 'study-p1', title: 'Rising line'),
      second: _phrase(id: 'study-p2', title: 'Answer line', difficulty: 2),
    );
    final progress = ProgressState(
      phraseProgress: {'study-p1': _masteredPhrase('study-p1')},
      skills: {
        'note:E4': _skill(
          objectiveId: 'note:E4',
          family: SkillFamily.noteReading,
          dueAt: now.subtract(const Duration(days: 1)),
        ),
        'chord:G:maj': _skill(
          objectiveId: 'chord:G:maj',
          family: SkillFamily.harmony,
          dueAt: now.subtract(const Duration(days: 1)),
        ),
      },
    );

    final map = MasteryMap.build(
      progress: progress,
      registry: registry,
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.next.first.title, 'E4');
    expect(
      map.next.map((entry) => entry.title),
      isNot(contains('chord:G:maj')),
    );
    final phraseNext = map.next.where((entry) => entry.phraseId != null).single;
    expect(phraseNext.phraseId, 'study-p2');
    expect(phraseNext.title, 'Answer line');
    expect(phraseNext.tempoBpm, 72);
    // A can-play phrase is never recommended again.
    expect(map.next.where((entry) => entry.phraseId == 'study-p1'), isEmpty);
  });

  test('an empty profile has honest empty sections', () {
    final map = MasteryMap.build(
      progress: ProgressState.fresh(),
      registry: PhraseObjectiveRegistry(),
      takes: const <RecordingTake>[],
      now: now,
    );

    expect(map.canPlay, isEmpty);
    expect(map.shaky, isEmpty);
    expect(map.reading, isEmpty);
    expect(map.next, isEmpty);
    expect(map.readingMasteredCount, 0);
    expect(map.readingTrackedCount, 0);
  });

  test('readable objective ids are human-readable', () {
    expect(readableObjectiveId('note:E4'), 'E4');
    expect(readableObjectiveId('rhythm:eighths'), 'Rhythm · eighths');
    expect(
      readableObjectiveId('ear:interval:m3:melodic'),
      'Interval · m3 · melodic',
    );
  });
}
