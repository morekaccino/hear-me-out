import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/phrase_objective.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
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

Phrase _phrase({int contentVersion = 1, int tempo = 72}) => Phrase(
  id: 'study-p1',
  bars: 1,
  timeSignature: const TimeSignature(4, 4),
  events: _events,
  targetTempoBpm: tempo,
  title: 'Rising line',
  skills: const <String>['note-reading.first-position'],
  difficulty: 2,
  contentVersion: contentVersion,
);

Score _score({int contentVersion = 1, int tempo = 72}) => Score(
  piece: _piece(),
  phrases: <Phrase>[_phrase(contentVersion: contentVersion, tempo: tempo)],
);

void main() {
  final now = DateTime(2026, 11, 6, 10);
  const canonicalId = 'phrase:study:study-p1';

  test('resolves a registered phrase to a repertoire objective', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());

    final ref = registry.resolvePhrase('study-p1');

    expect(ref, isNotNull);
    expect(ref!.id, canonicalId);
    expect(ref.family, SkillFamily.repertoire);
    expect(ref.stage, 2);
    expect(ref.data[PhraseObjectiveData.pieceId], 'study');
    expect(ref.data[PhraseObjectiveData.phraseId], 'study-p1');
    expect(ref.data[PhraseObjectiveData.contentVersion], 1);
    expect(ref.data[PhraseObjectiveData.practicedContentVersion], 1);
    expect(ref.data[PhraseObjectiveData.needsRetest], isFalse);
    expect(ref.data[PhraseObjectiveData.stage], 2);
    expect(ref.data[PhraseObjectiveData.title], 'Rising line');
    expect(ref.data['question'], contains('Rising line'));
    expect(ref.data['correctId'], 'study');
  });

  test('exposes every registered record for progress surfaces', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());

    final records = registry.allRecords.toList();

    expect(records, hasLength(1));
    expect(records.single.phraseId, 'study-p1');
    expect(records.single.pieceId, 'study');
    expect(records.single.pieceTitle, 'Original Study');
    expect(records.single.phraseTitle, 'Rising line');
    expect(records.single.targetTempoBpm, 72);
    expect(records.single.contentVersion, 1);
    expect(records.single.stage, 2);
  });

  test('accepts canonical, legacy, and bare phrase ids', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());

    for (final id in <String>['study-p1', 'phrase:study-p1', canonicalId]) {
      expect(registry.resolvePhrase(id)?.id, canonicalId, reason: id);
    }
  });

  test('an unknown phrase id resolves to null', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());

    expect(registry.resolvePhrase('missing-p1'), isNull);
    expect(registry.resolvePhrase('phrase:missing:missing-p1'), isNull);
    expect(registry.resolvePhrase('phrase:'), isNull);
  });

  test('a practiced version newer than the build resolves to null', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());

    expect(registry.resolvePhrase('study-p1', contentVersion: 2), isNull);
  });

  test('re-registering a piece drops phrases it no longer contains', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    expect(registry.resolvePhrase('study-p1'), isNotNull);

    registry.registerScore(Score(piece: _piece(), phrases: const <Phrase>[]));

    expect(registry.resolvePhrase('study-p1'), isNull);
  });

  test('the same phrase id cannot move to another piece', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    final otherPiece = _piece().copyWith(
      id: 'other-study',
      title: 'Other Study',
    );

    expect(
      () => registry.registerPhrase(piece: otherPiece, phrase: _phrase()),
      throwsArgumentError,
    );
    expect(
      registry.resolvePhrase('study-p1')!.data[PhraseObjectiveData.pieceId],
      'study',
    );
  });

  test('a recorded phrase attempt creates a due phrase skill and appears in practice', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    final progress = ProgressState.fresh();

    progress.recordPhraseAttempt(
      PhraseAttempt(
        phraseId: 'study-p1',
        pieceId: 'study',
        contentVersion: 1,
        outcome: AttemptOutcome.incorrect,
        now: now,
        accuracy: 0.4,
        tempoBpm: 60,
      ),
    );

    final skill = progress.skills[canonicalId]!;
    expect(skill.family, SkillFamily.repertoire);
    expect(skill.dueAt, isNotNull);
    expect(skill.dueAt!.isAfter(now), isTrue);

    final phrase = progress.phraseProgressFor('study-p1')!;
    expect(phrase.contentVersion, 1);
    expect(phrase.reps, 1);
    expect(phrase.incorrect, 1);
    expect(phrase.performanceDays, hasLength(1));
    expect(phrase.lastPerformanceAt, now);
    expect(phrase.bestTempoBpm, 60);
    expect(phrase.bestAccuracy, 0.4);
    expect(phrase.dueAt, skill.dueAt);
    expect(progress.daily.correct, 0);

    final later = skill.dueAt!.add(const Duration(minutes: 1));
    final prompts = buildSkillPracticeExercises(
      kind: 'due',
      progress: progress,
      now: later,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(12),
      phraseResolver: registry,
    );

    expect(prompts.any((prompt) => prompt.objective.id == canonicalId), isTrue);
  });

  test('an edited phrase keeps the stable id and marks a re-test', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    final progress = ProgressState.fresh();
    progress.phraseProgress['study-p1'] = PhraseProgress(
      phraseId: 'study-p1',
      reps: 4,
      correct: 5,
      correctDays: <String>{'2026-10-20', '2026-10-27'},
      performanceDays: <String>{'2026-10-20', '2026-10-27', '2026-11-03'},
      firstPerformanceDay: '2026-10-20',
      contentVersion: 1,
    );

    final before = registry.resolvePhrase('study-p1', contentVersion: 1);
    expect(before!.id, canonicalId);
    expect(before.data[PhraseObjectiveData.needsRetest], isFalse);

    // Same stable phrase id, changed notes/tempo, new content version.
    registry.registerScore(_score(contentVersion: 2, tempo: 80));
    final after = registry.resolvePhrase('study-p1', contentVersion: 1);

    expect(after, isNotNull);
    expect(after!.id, canonicalId);
    expect(after.data[PhraseObjectiveData.contentVersion], 2);
    expect(after.data[PhraseObjectiveData.practicedContentVersion], 1);
    expect(after.data[PhraseObjectiveData.needsRetest], isTrue);

    final reloaded = ProgressState.fromJson(progress.toJson());
    expect(reloaded.phraseProgressFor('study-p1')!.reps, 4);
    expect(reloaded.phraseProgressFor('study-p1')!.contentVersion, 1);
    expect(reloaded.phraseProgressFor('study-p1')!.needsRetestFor(2), isTrue);

    // Once the learner practices the new arrangement, the evidence version
    // catches up without moving or resetting the counters.
    reloaded.phraseProgressFor('study-p1')!.contentVersion = 2;
    final practiced = ProgressState.fromJson(reloaded.toJson());
    expect(practiced.phraseProgressFor('study-p1')!.reps, 4);
    expect(practiced.phraseProgressFor('study-p1')!.needsRetestFor(2), isFalse);
  });

  test(
    'a due phrase skill appears in due practice without a catalog entry',
    () {
      final registry = PhraseObjectiveRegistry()..registerScore(_score());
      final progress = ProgressState.fresh();
      progress.skills[canonicalId] = SkillProgress(
        objectiveId: canonicalId,
        family: SkillFamily.repertoire,
        stabilityDays: 2,
        dueAt: now.subtract(const Duration(hours: 1)),
        reps: 2,
        correct: 2,
      );

      final prompts = buildSkillPracticeExercises(
        kind: 'due',
        progress: progress,
        now: now,
        micAvailable: false,
        mode: AnswerMode.name,
        random: Random(7),
        phraseResolver: registry,
      );

      expect(prompts, isNotEmpty);
      expect(
        prompts.any((prompt) => prompt.objective.id == canonicalId),
        isTrue,
      );
      expect(
        prompts
            .firstWhere((prompt) => prompt.objective.id == canonicalId)
            .objective
            .family,
        SkillFamily.repertoire,
      );
    },
  );

  test('a legacy phrase skill keeps its stored objective id', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    final progress = ProgressState.fresh();
    progress.skills['phrase:study-p1'] = SkillProgress(
      objectiveId: 'phrase:study-p1',
      family: SkillFamily.repertoire,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
      reps: 2,
      correct: 2,
    );

    final prompts = buildSkillPracticeExercises(
      kind: 'due',
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(8),
      phraseResolver: registry,
    );

    expect(
      prompts.any((prompt) => prompt.objective.id == 'phrase:study-p1'),
      isTrue,
    );
    expect(
      prompts.any((prompt) => prompt.objective.id == canonicalId),
      isFalse,
    );
  });

  test('phrase practice passes the stored content version to the resolver', () {
    final registry = PhraseObjectiveRegistry()
      ..registerScore(_score(contentVersion: 2));
    final progress = ProgressState.fresh();
    progress.phraseProgress['study-p1'] = PhraseProgress(
      phraseId: 'study-p1',
      reps: 3,
      correct: 3,
      contentVersion: 1,
    );
    progress.skills[canonicalId] = SkillProgress(
      objectiveId: canonicalId,
      family: SkillFamily.repertoire,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
      reps: 2,
      correct: 2,
    );

    final prompts = buildSkillPracticeExercises(
      kind: 'due',
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(9),
      phraseResolver: registry,
    );
    final phrasePrompt = prompts.firstWhere(
      (prompt) => prompt.objective.id == canonicalId,
    );

    expect(phrasePrompt.objective.data[PhraseObjectiveData.contentVersion], 2);
    expect(
      phrasePrompt.objective.data[PhraseObjectiveData.practicedContentVersion],
      1,
    );
    expect(
      phrasePrompt.objective.data[PhraseObjectiveData.needsRetest],
      isTrue,
    );
  });

  test('an unknown phrase skill is ignored without failing the session', () {
    final progress = ProgressState.fresh();
    progress.skills['phrase:missing:missing-p1'] = SkillProgress(
      objectiveId: 'phrase:missing:missing-p1',
      family: SkillFamily.repertoire,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
      reps: 2,
      correct: 2,
    );

    final prompts = buildSkillPracticeExercises(
      kind: 'due',
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(10),
      phraseResolver: PhraseObjectiveRegistry(),
    );

    expect(prompts, isNotEmpty);
    expect(
      prompts.any((prompt) => prompt.objective.id.startsWith('phrase:')),
      isFalse,
    );
    expect(
      prompts.every((prompt) => prompt.objective.id.startsWith('note:')),
      isTrue,
    );
  });

  test('phrase resolution does not change note or catalog practice', () {
    final registry = PhraseObjectiveRegistry()..registerScore(_score());
    final progress = ProgressState.fresh();
    progress.skills['note:E4'] = SkillProgress(
      objectiveId: 'note:E4',
      family: SkillFamily.noteReading,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 3)),
      reps: 2,
      correct: 2,
    );
    progress.skills['keysig:G'] = SkillProgress(
      objectiveId: 'keysig:G',
      family: SkillFamily.theory,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 2)),
      reps: 2,
      correct: 2,
    );
    progress.skills[canonicalId] = SkillProgress(
      objectiveId: canonicalId,
      family: SkillFamily.repertoire,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
      reps: 2,
      correct: 2,
    );

    final prompts = buildSkillPracticeExercises(
      kind: 'due',
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(11),
      phraseResolver: registry,
    );
    final ids = prompts.map((prompt) => prompt.objective.id).toSet();

    expect(ids, containsAll(<String>['note:E4', 'keysig:G', canonicalId]));
  });

  test('a phrase content version below 1 is rejected at registration', () {
    final registry = PhraseObjectiveRegistry();

    expect(
      () => registry.registerPhrase(
        piece: _piece(),
        phrase: _phrase(contentVersion: 0),
      ),
      throwsArgumentError,
    );
  });
}
