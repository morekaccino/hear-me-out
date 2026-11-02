import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final now = DateTime(2026, 11, 2, 10);

  test('smart practice reviews skills from every family', () {
    final progress = ProgressState.fresh();
    progress.skills['note:E4'] = SkillProgress(
      objectiveId: 'note:E4',
      family: SkillFamily.noteReading,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 2)),
      reps: 2,
      correct: 2,
    );
    progress.skills['keysig:G'] = SkillProgress(
      objectiveId: 'keysig:G',
      family: SkillFamily.theory,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(hours: 1)),
      reps: 2,
      correct: 2,
    );
    progress.skills['ear:interval:m3:melodic'] = SkillProgress(
      objectiveId: 'ear:interval:m3:melodic',
      family: SkillFamily.ear,
      stabilityDays: 2,
      dueAt: now.subtract(const Duration(minutes: 30)),
      reps: 2,
      correct: 2,
    );

    final prompts = buildSkillPracticeExercises(
      kind: 'smart',
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(7),
    );

    expect(prompts, hasLength(12));
    expect(
      prompts.map((prompt) => prompt.objective.family).toSet(),
      containsAll([
        SkillFamily.noteReading,
        SkillFamily.theory,
        SkillFamily.ear,
      ]),
    );
    expect(
      prompts.map((prompt) => prompt.objective.id),
      containsAll(['note:E4', 'keysig:G', 'ear:interval:m3:melodic']),
    );
    for (var index = 1; index < prompts.length; index++) {
      expect(
        prompts[index].objective.id,
        isNot(prompts[index - 1].objective.id),
      );
    }
  });

  test('a wrong answer makes a skill fragile and reschedules it soon', () {
    final skill = SkillProgress(
      objectiveId: 'keysig:G',
      family: SkillFamily.theory,
      stabilityDays: 10,
      difficulty: 5,
      reps: 2,
      correct: 2,
    );

    skill.recordAnswer(
      SkillAnswer(
        objectiveId: skill.objectiveId,
        family: skill.family,
        correct: false,
        now: now,
      ),
    );
    expect(skill.lapses, 1);
    expect(skill.fragile, isFalse);

    skill.recordAnswer(
      SkillAnswer(
        objectiveId: skill.objectiveId,
        family: skill.family,
        correct: false,
        now: now.add(const Duration(minutes: 10)),
      ),
    );
    expect(skill.lapses, 2);
    expect(skill.fragile, isTrue);
    expect(
      skill.dueAt!.isBefore(now.add(const Duration(hours: 1))),
      isTrue,
    );
  });

  test('a note answer still updates the legacy note view', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(
      note: Note.parse('E4'),
      correctAnswer: true,
      now: now,
      production: true,
      transfer: true,
      responseMs: 1000,
    );
    expect(progress.notes['E4']!.correct, 1);
    expect(progress.skills['note:E4']!.correct, 1);
    expect(progress.skills['note:E4']!.productionCorrect, 1);
    expect(progress.skills['note:E4']!.transferCorrect, 1);
  });
}
