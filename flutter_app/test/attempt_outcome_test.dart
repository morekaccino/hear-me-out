import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/alignment.dart';
import 'package:hear_me_out/core/audio/note_segmenter.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/lesson/lesson_screen.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 6, 10);

  SkillProgress populatedSkill() => SkillProgress(
    objectiveId: 'note:E4',
    family: SkillFamily.noteReading,
    stabilityDays: 12,
    difficulty: 4,
    dueAt: now.add(const Duration(days: 3)),
    lastSeenAt: now.subtract(const Duration(days: 2)),
    reps: 4,
    lapses: 1,
    correct: 3,
    incorrect: 1,
    correctDays: <String>{'2026-11-01', '2026-11-03'},
    productionCorrect: 2,
    transferCorrect: 1,
    averageResponseMs: 1200,
    level: 2,
    fragile: true,
    recentTemplateIds: <String>['template-a', 'template-b'],
    centsSamples: 3,
    centsTotal: 45,
    box: 3,
    streak: 2,
    bestStreak: 3,
  );

  SkillAnswer indeterminateAnswer() => SkillAnswer(
    objectiveId: 'note:E4',
    family: SkillFamily.noteReading,
    outcome: AttemptOutcome.indeterminate,
    now: now,
    responseMs: 500,
    usedHint: true,
    revealed: true,
    production: true,
    transfer: true,
    templateId: 'template-c',
    absCents: 4,
  );

  group('AttemptOutcome is a no-op at the skill boundary', () {
    test('indeterminate leaves every SkillProgress field byte-for-byte', () {
      final skill = populatedSkill();
      final before = jsonEncode(skill.toJson());

      skill.recordAnswer(indeterminateAnswer());

      expect(jsonEncode(skill.toJson()), before);
    });

    test(
      'indeterminate leaves ProgressState counters and quests unchanged',
      () {
        final state = ProgressState.fresh(
          settings: const AppSettings(onboardingComplete: true),
        );
        state.addXp(25, now);
        state.completeLesson(
          lessonId: 'c3u1l1',
          accuracy: 1,
          earnedXp: 10,
          answered: 10,
          now: now.subtract(const Duration(days: 1)),
        );
        state.loseHeart(now);
        state.daily.correct = 3;
        state.recordDailyCombo(4, now);
        state.claimedQuests.add('lesson');
        state.questDay = '2026-11-06';
        state.skills['note:E4'] = populatedSkill();
        final before = jsonEncode(state.toJson());

        state.recordSkillAnswer(indeterminateAnswer());
        state.recordAnswer(
          note: Note.parse('E4'),
          outcome: AttemptOutcome.indeterminate,
          now: now,
        );

        expect(jsonEncode(state.toJson()), before);
      },
    );

    test('indeterminate PhraseProgress changes nothing', () {
      final phrase = PhraseProgress(
        phraseId: 'twinkle.a',
        reps: 2,
        correct: 1,
        incorrect: 1,
        correctDays: <String>{'2026-11-01'},
        performanceDays: <String>{'2026-11-01', '2026-11-02'},
        firstPerformanceDay: '2026-11-01',
        lastPerformanceAt: DateTime(2026, 11, 2, 9),
        bestTempoBpm: 70,
        bestAccuracy: 0.9,
      );
      final before = jsonEncode(phrase.toJson());

      phrase.recordAttempt(
        PhraseAttempt(
          phraseId: 'twinkle.a',
          outcome: AttemptOutcome.indeterminate,
          now: now,
          accuracy: 0.2,
          tempoBpm: 90,
        ),
      );

      expect(jsonEncode(phrase.toJson()), before);
    });
  });

  group('Determinate attempts still schedule and count', () {
    test('a correct answer advances FSRS and the correct counters', () {
      final skill = SkillProgress(
        objectiveId: 'keysig:G',
        family: SkillFamily.theory,
      );

      skill.recordAnswer(
        SkillAnswer(
          objectiveId: skill.objectiveId,
          family: skill.family,
          outcome: AttemptOutcome.correct,
          now: now,
          responseMs: 1200,
        ),
      );

      expect(skill.reps, 1);
      expect(skill.correct, 1);
      expect(skill.incorrect, 0);
      expect(skill.stabilityDays, greaterThan(0));
      expect(skill.dueAt, isNotNull);
    });

    test('an incorrect answer schedules a lapse', () {
      final skill = SkillProgress(
        objectiveId: 'keysig:G',
        family: SkillFamily.theory,
      );

      skill.recordAnswer(
        SkillAnswer(
          objectiveId: skill.objectiveId,
          family: skill.family,
          outcome: AttemptOutcome.incorrect,
          now: now,
        ),
      );

      expect(skill.reps, 1);
      expect(skill.correct, 0);
      expect(skill.incorrect, 1);
      expect(skill.lapses, 1);
      expect(skill.dueAt, isNotNull);
    });

    test(
      'note answers still update daily, skill, and legacy note progress',
      () {
        final state = ProgressState.fresh();

        state.recordAnswer(
          note: Note.parse('E4'),
          outcome: AttemptOutcome.correct,
          now: now,
        );
        expect(state.daily.correct, 1);
        expect(state.skills['note:E4']!.correct, 1);
        expect(state.notes['E4']!.correct, 1);

        state.recordAnswer(
          note: Note.parse('E4'),
          outcome: AttemptOutcome.incorrect,
          now: now.add(const Duration(minutes: 5)),
        );
        expect(state.daily.correct, 1);
        expect(state.skills['note:E4']!.incorrect, 1);
        expect(state.skills['note:E4']!.lapses, 1);
        expect(state.notes['E4']!.incorrect, 1);
      },
    );
  });

  group('AppController indeterminate path', () {
    Future<ProviderContainer> startNameLesson(MemoryProgressStore store) async {
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('c3u2l1', micAvailable: false);
      var run = container.read(appControllerProvider).requireValue.run!;
      while (!run.current.isScored) {
        await notifier.nextExercise();
        run = container.read(appControllerProvider).requireValue.run!;
      }
      return container;
    }

    test('indeterminate presents retry feedback and changes nothing', () async {
      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final container = await startNameLesson(store);
      final notifier = container.read(appControllerProvider.notifier);
      final beforeData = container.read(appControllerProvider).requireValue;
      final beforeProgress = jsonEncode(beforeData.progress.toJson());
      final beforeStore = jsonEncode(store.value!.toJson());
      final heartsBefore = beforeData.progress.hearts;
      final indexBefore = beforeData.run!.index;

      await notifier.submitOutcome(AttemptOutcome.indeterminate);

      final after = container.read(appControllerProvider).requireValue;
      expect(after.run!.awaitingNext, isTrue);
      expect(after.run!.lastOutcome, AttemptOutcome.indeterminate);
      expect(after.run!.lastCorrect, isFalse);
      expect(after.run!.index, indexBefore);
      expect(after.run!.correct, 0);
      expect(after.run!.wrong, 0);
      expect(after.run!.combo, 0);
      expect(after.run!.lives, heartsBefore);
      expect(after.run!.pendingMistakes, 0);
      expect(after.progress.hearts, heartsBefore);
      expect(after.progress.xp, 0);
      expect(after.progress.daily.correct, 0);
      expect(jsonEncode(after.progress.toJson()), beforeProgress);
      expect(jsonEncode(store.value!.toJson()), beforeStore);

      notifier.retryCurrent();
      final retried = container.read(appControllerProvider).requireValue;
      expect(retried.run!.awaitingNext, isFalse);
      expect(retried.run!.lastOutcome, isNull);
      expect(retried.run!.index, indexBefore);
    });

    test(
      'determinate answers still score after an indeterminate retry',
      () async {
        final store = MemoryProgressStore(
          ProgressState.fresh(
            settings: const AppSettings(
              onboardingComplete: true,
              answerMode: AnswerMode.name,
            ),
          ),
        );
        final container = await startNameLesson(store);
        final notifier = container.read(appControllerProvider.notifier);
        final heartsBefore = container
            .read(appControllerProvider)
            .requireValue
            .progress
            .hearts;
        final firstObjective = container
            .read(appControllerProvider)
            .requireValue
            .run!
            .current
            .objective
            .id;

        await notifier.submitOutcome(AttemptOutcome.indeterminate);
        notifier.retryCurrent();
        await notifier.submitAnswer(correct: true);

        var data = container.read(appControllerProvider).requireValue;
        expect(data.run!.correct, 1);
        expect(data.run!.wrong, 0);
        expect(data.run!.combo, 1);
        expect(data.progress.daily.correct, 1);
        expect(data.progress.skills[firstObjective]!.reps, 1);
        expect(data.progress.hearts, heartsBefore);

        await notifier.nextExercise();
        var run = data.run!;
        while (!run.current.isScored) {
          await notifier.nextExercise();
          run = container.read(appControllerProvider).requireValue.run!;
        }
        final secondObjective = run.current.objective.id;
        await notifier.submitAnswer(correct: false);

        data = container.read(appControllerProvider).requireValue;
        expect(data.run!.wrong, 1);
        expect(data.run!.combo, 0);
        expect(data.run!.correct, 1);
        expect(data.progress.daily.correct, 1);
        expect(data.progress.skills[secondObjective]!.incorrect, 1);
        expect(data.progress.hearts, heartsBefore - 1);
      },
    );
  });

  group('Phrase evidence', () {
    const sampleRate = 22050;

    List<TargetNote> targets() => [
      for (var index = 0; index < 4; index++)
        TargetNote(
          index: index,
          midi: 64 + index,
          onsetSeconds: 0.3 + index * 0.5,
          durationSeconds: 0.4,
          bar: 0,
        ),
    ];

    DetectedNote detection(TargetNote target, {required double confidence}) =>
        DetectedNote(
          startSeconds: target.onsetSeconds,
          durationSeconds: 0.4,
          midi: target.midi,
          cents: 0,
          confidence: confidence,
          sampleIndex: 0,
        );

    test(
      'a low-confidence phrase is indeterminate and records nothing',
      () async {
        final target = targets();
        final result = PhraseScorer(sampleRate: sampleRate.toDouble())
            .scoreDetections(
              target: target,
              detected: [
                for (var index = 0; index < target.length; index++)
                  detection(target[index], confidence: index == 2 ? 0.3 : 0.95),
              ],
              bpm: 60,
            );
        expect(result.outcome, AttemptOutcome.indeterminate);

        final store = MemoryProgressStore(ProgressState.fresh());
        final container = ProviderContainer(
          overrides: [progressStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        await container.read(appControllerProvider.future);
        final before = jsonEncode(
          container.read(appControllerProvider).requireValue.progress.toJson(),
        );

        final recorded = await container
            .read(appControllerProvider.notifier)
            .recordPhraseResult(
              phraseId: 'twinkle.a',
              result: result,
              tempoBpm: 60,
              now: now,
            );

        expect(recorded, isFalse);
        final progress = container
            .read(appControllerProvider)
            .requireValue
            .progress;
        expect(progress.phraseProgress, isEmpty);
        expect(jsonEncode(progress.toJson()), before);
      },
    );

    test('a phrase attempt and a note attempt are separate evidence', () async {
      final target = targets();
      final result = PhraseScorer(sampleRate: sampleRate.toDouble())
          .scoreDetections(
            target: target,
            detected: [
              for (final note in target) detection(note, confidence: 0.95),
            ],
            bpm: 60,
          );
      expect(result.outcome, AttemptOutcome.correct);

      final store = MemoryProgressStore(ProgressState.fresh());
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);

      final recorded = await notifier.recordPhraseResult(
        phraseId: 'twinkle.a',
        result: result,
        tempoBpm: 60,
        now: now,
      );
      expect(recorded, isTrue);

      var progress = container
          .read(appControllerProvider)
          .requireValue
          .progress;
      final phrase = progress.phraseProgress['twinkle.a']!;
      expect(phrase.reps, 1);
      expect(phrase.correct, 1);
      expect(phrase.correctDays, contains('2026-11-06'));
      expect(phrase.performanceDays, contains('2026-11-06'));
      expect(phrase.bestTempoBpm, 60);
      expect(phrase.bestAccuracy, 1);
      expect(progress.skills, isEmpty);
      expect(progress.notes, isEmpty);
      expect(progress.xp, 0);
      expect(progress.streak, 0);
      expect(progress.daily.correct, 0);
      expect(progress.hearts, maxHearts);

      progress.recordAnswer(
        note: Note.parse('E4'),
        outcome: AttemptOutcome.correct,
        now: now.add(const Duration(minutes: 1)),
      );
      progress = container.read(appControllerProvider).requireValue.progress;
      expect(progress.phraseProgress['twinkle.a']!.reps, 1);
      expect(progress.skills['note:E4']!.correct, 1);
      expect(progress.notes['E4']!.correct, 1);
    });
  });

  group('Lesson feedback', () {
    testWidgets('an indeterminate answer shows a calm retry, not "Not quite"', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(store),
          pitchSourceFactoryProvider.overrideWithValue(
            FakePitchSourceFactory(permission: false).call,
          ),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('c3u2l1', micAvailable: false);
      var run = container.read(appControllerProvider).requireValue.run!;
      while (!run.current.isScored) {
        await notifier.nextExercise();
        run = container.read(appControllerProvider).requireValue.run!;
      }
      final heartsBefore = container
          .read(appControllerProvider)
          .requireValue
          .progress
          .hearts;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LessonScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await notifier.submitOutcome(AttemptOutcome.indeterminate);
      await tester.pumpAndSettle();

      expect(find.text('Could not hear that clearly'), findsOneWidget);
      expect(find.text('Not quite'), findsNothing);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(
        container.read(appControllerProvider).requireValue.progress.hearts,
        heartsBefore,
      );

      await tester.ensureVisible(find.text('TRY AGAIN'));
      await tester.tap(find.text('TRY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('Could not hear that clearly'), findsNothing);
      expect(
        container.read(appControllerProvider).requireValue.run!.awaitingNext,
        isFalse,
      );
    });
  });
}
