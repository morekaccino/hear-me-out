import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/session_factory.dart';
import '../core/audio/phrase_scorer.dart';
import '../core/learning/lesson_run.dart';
import '../core/learning/progress.dart';
import '../core/learning/prompt.dart';
import '../core/learning/skill.dart';
import '../core/music/curriculum.dart';
import '../core/music/note.dart';
import '../core/storage/progress_store.dart';
import 'providers.dart';

const Set<int> _streakMilestones = {7, 14, 30, 50, 100, 180, 365};

class LessonResult {
  const LessonResult({
    required this.lessonId,
    required this.title,
    required this.passed,
    required this.accuracy,
    required this.xp,
    required this.streak,
    required this.answered,
    required this.bestCombo,
    required this.isPractice,
    this.leveledUp = false,
    this.dailyGoalReached = false,
    this.lessonUnlocked = false,
    this.streakAdvanced = false,
    this.streakMilestone = false,
  });

  final String lessonId;
  final String title;
  final bool passed;
  final double accuracy;
  final int xp;
  final int streak;
  final int answered;
  final int bestCombo;
  final bool isPractice;
  final bool leveledUp;
  final bool dailyGoalReached;
  final bool lessonUnlocked;
  final bool streakAdvanced;
  final bool streakMilestone;
}

class AppData {
  const AppData({required this.progress, this.run, this.result});

  final ProgressState progress;
  final LessonRun? run;
  final LessonResult? result;

  AppData copyWith({
    ProgressState? progress,
    LessonRun? run,
    LessonResult? result,
    bool clearRun = false,
    bool clearResult = false,
  }) {
    return AppData(
      progress: progress ?? this.progress,
      run: clearRun ? null : (run ?? this.run),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class AppController extends AsyncNotifier<AppData> {
  late ProgressStore _store;
  bool _lastMicAvailable = false;

  @override
  Future<AppData> build() async {
    _store = ref.watch(progressStoreProvider);
    ProgressState progress;
    try {
      progress = await _store.load() ?? ProgressState.fresh();
    } catch (_) {
      progress = ProgressState.fresh();
    }
    progress.refreshHearts(DateTime.now());
    progress.refreshDaily(DateTime.now());
    _applySoundSettings(progress.settings);
    return AppData(progress: progress);
  }

  AppData get _data => state.requireValue;

  void _applySoundSettings(AppSettings settings) {
    ref.read(soundServiceProvider).enabled = settings.soundEffects;
  }

  Future<void> _save() async {
    try {
      await _store.save(_data.progress);
    } catch (_) {
      // Local storage failures must not break a lesson.
    }
  }

  Future<void> completeOnboarding(AppSettings settings) async {
    final data = _data;
    data.progress.settings = settings.copyWith(onboardingComplete: true);
    _applySoundSettings(data.progress.settings);
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
  }

  Future<void> updateSettings(AppSettings settings) async {
    final data = _data;
    data.progress.settings = settings;
    _applySoundSettings(settings);
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
  }

  void startLesson(String lessonId, {required bool micAvailable}) {
    final lesson = lessonById[lessonId];
    if (lesson == null) return;
    _lastMicAvailable = micAvailable;
    final data = _data;
    final exercises = buildLessonSession(
      lesson: lesson,
      progress: data.progress,
      now: DateTime.now(),
      micAvailable: micAvailable,
      mode: data.progress.settings.answerMode,
    );
    final run = LessonRun(
      lesson: lesson,
      exercises: exercises,
      isPractice: false,
    );
    run.lives = data.progress.hearts;
    state = AsyncData(data.copyWith(run: run, clearResult: true));
  }

  void startPractice({required String kind, required bool micAvailable}) {
    _lastMicAvailable = micAvailable;
    final data = _data;
    final exercises = buildSkillPracticeExercises(
      kind: kind,
      progress: data.progress,
      now: DateTime.now(),
      micAvailable: micAvailable,
      mode: data.progress.settings.answerMode,
    );
    final title = switch (kind) {
      'smart' => 'Smart review',
      'due' => 'Due review',
      'weak' => 'Weak skills',
      _ => 'Free practice',
    };
    final lesson = LessonDefinition(
      id: 'practice_$kind',
      unitId: 'practice',
      title: title,
      newNotes: const [],
      reviewNotes: const [],
      isReview: true,
    );
    final run = LessonRun(
      lesson: lesson,
      exercises: exercises,
      isPractice: true,
      practiceTitle: title,
    );
    run.lives = data.progress.hearts;
    state = AsyncData(data.copyWith(run: run, clearResult: true));
  }

  /// Starts a 15-exercise test of the material before [sectionId]. Passing it
  /// marks every earlier lesson complete, mirroring Duolingo's jump-ahead.
  void startJumpTest({
    required String sectionId,
    required bool micAvailable,
  }) {
    final sectionIndex = sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (sectionIndex <= 0) return;
    _lastMicAvailable = micAvailable;
    final data = _data;
    final notes = <Note>[];
    final seen = <String>{};
    for (var index = 0; index < sectionIndex; index++) {
      for (final unit in sections[index].units) {
        for (final lesson in unit.lessons) {
          for (final note in [...lesson.newNotes, ...lesson.reviewNotes]) {
            if (seen.add(note.id)) notes.add(note);
          }
        }
      }
    }
    if (notes.isEmpty) {
      notes.addAll(noteCatalog.take(8));
    }
    final lesson = LessonDefinition(
      id: 'jump_$sectionId',
      unitId: 'jump',
      title: 'Jump ahead test',
      newNotes: const [],
      reviewNotes: notes,
      isReview: true,
    );
    final exercises = buildLessonSession(
      lesson: lesson,
      progress: data.progress,
      now: DateTime.now(),
      micAvailable: micAvailable,
      mode: data.progress.settings.answerMode,
    );
    final run = LessonRun(
      lesson: lesson,
      exercises: exercises,
      isPractice: false,
      isJumpTest: true,
      jumpTargetSectionId: sectionId,
    );
    run.lives = data.progress.hearts;
    state = AsyncData(data.copyWith(run: run, clearResult: true));
  }

  /// Records a determinate answer. Use [submitOutcome] when the app cannot
  /// decide whether the attempt was correct.
  Future<void> submitAnswer({
    required bool correct,
    double? cents,
    Note? detected,
    bool octaveError = false,
    int responseMs = 0,
  }) {
    return submitOutcome(
      correct ? AttemptOutcome.correct : AttemptOutcome.incorrect,
      cents: cents,
      detected: detected,
      octaveError: octaveError,
      responseMs: responseMs,
    );
  }

  /// The single answer entry point for all three outcomes.
  ///
  /// An indeterminate attempt is a retry signal: it presents feedback and
  /// waits for the learner, but it does not schedule the skill, change XP,
  /// streak, hearts, daily counters, or combo, and it does not queue a
  /// mistake. Only determinate outcomes reach progress storage.
  Future<void> submitOutcome(
    AttemptOutcome outcome, {
    double? cents,
    Note? detected,
    bool octaveError = false,
    int responseMs = 0,
  }) async {
    final data = _data;
    final run = data.run;
    if (run == null || run.awaitingNext || run.isFinished) return;

    final prompt = run.current;
    if (!prompt.isScored) return;

    final target = prompt is NotePrompt ? prompt.note : null;
    final now = DateTime.now();

    run.lastTarget = target;
    run.lastOutcome = outcome;
    run.lastOctaveError = octaveError;
    run.lastCents = cents;
    run.lastDetected = detected;
    run.awaitingNext = true;

    if (outcome == AttemptOutcome.indeterminate) {
      state = AsyncData(data.copyWith(run: run));
      return;
    }

    final production =
        prompt.usesMicrophone ||
        prompt is RhythmPrompt ||
        prompt is FretTapPrompt ||
        prompt is StaffTapPrompt ||
        prompt is OrderPrompt;
    data.progress.recordSkillAnswer(
      SkillAnswer(
        objectiveId: prompt.objective.id,
        family: prompt.objective.family,
        outcome: outcome,
        now: now,
        absCents: cents,
        production: production,
        transfer: !prompt.isNew,
        templateId: prompt.templateId,
        responseMs: responseMs,
      ),
    );

    if (outcome == AttemptOutcome.correct) {
      run.correct++;
      run.combo++;
      run.bestCombo = run.bestCombo < run.combo ? run.combo : run.bestCombo;
      data.progress.recordDailyCombo(run.combo, now);
    } else {
      run.wrong++;
      run.combo = 0;
      run.queueMistake(prompt);
      // Checkpoints are assessments: a wrong answer lowers the score, not the
      // shared heart pool. Practice is also heart-free.
      if (!run.isPractice && !run.lesson.isReview) {
        data.progress.loseHeart(now);
        run.lives = data.progress.hearts;
      }
    }

    state = AsyncData(data.copyWith(run: run));
    await _save();
  }

  /// Clears the feedback for an indeterminate attempt without advancing or
  /// scoring anything, so the learner can try the same prompt again.
  void retryCurrent() {
    final data = _data;
    final run = data.run;
    if (run == null || !run.awaitingNext) return;
    run.awaitingNext = false;
    run.lastOutcome = null;
    run.lastOctaveError = false;
    run.lastCents = null;
    run.lastDetected = null;
    run.lastTarget = null;
    state = AsyncData(data.copyWith(run: run));
  }

  /// Records phrase-level evidence from a scored phrase.
  ///
  /// [PhraseResult.outcome] is the source of truth. A low-confidence or
  /// incomplete take is indeterminate and records nothing. A determinate take
  /// updates only the phrase's own progress; per-note skills are recorded
  /// separately and are never derived from a phrase attempt, so the same take
  /// cannot count twice.
  Future<bool> recordPhraseResult({
    required String phraseId,
    required PhraseResult result,
    required int tempoBpm,
    DateTime? now,
  }) async {
    if (result.outcome == AttemptOutcome.indeterminate) return false;
    final data = _data;
    data.progress.recordPhraseAttempt(
      PhraseAttempt(
        phraseId: phraseId,
        outcome: result.outcome,
        now: now ?? DateTime.now(),
        accuracy: result.noteAccuracy,
        tempoBpm: tempoBpm,
      ),
    );
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<void> nextExercise() async {
    final data = _data;
    final run = data.run;
    if (run == null || run.isFinished) return;
    // Teach cards are informational, so they advance without an answer.
    if (!run.awaitingNext && run.current.isScored) return;

    if (!run.isPractice && run.outOfLives) {
      await _finish(passed: false);
      return;
    }
    if (run.index >= run.exercises.length - 1 && !run.appendNextMistake()) {
      final threshold = run.lesson.isReview ? 0.85 : 0.8;
      final passed = run.isPractice || run.accuracy >= threshold;
      await _finish(passed: passed);
      return;
    }

    run.index++;
    run.awaitingNext = false;
    run.lastOutcome = null;
    run.lastOctaveError = false;
    run.lastCents = null;
    run.lastDetected = null;
    run.lastTarget = null;
    state = AsyncData(data.copyWith(run: run));
  }

  Future<void> _finish({required bool passed}) async {
    final data = _data;
    final run = data.run;
    if (run == null) return;

    final accuracy = run.accuracy;
    final answered = run.answered;
    final now = DateTime.now();
    final goal = data.progress.settings.dailyGoalXp;
    final goalBefore = data.progress.xpTodayForDisplay >= goal;
    final levelBefore = data.progress.level;
    final streakBefore = data.progress.effectiveStreak;
    final alreadyCompleted = !run.isPractice &&
        data.progress.completedLessons.contains(run.lesson.id);
    final multiplier = data.progress.xpMultiplierAt(now);
    var earnedXp = 0;

    if (run.isPractice) {
      if (passed) {
        earnedXp = run.earnedXp * multiplier;
        data.progress.addXp(earnedXp, now);
        data.progress.recordPractice(now);
        // Practice is the free way back into a lesson when hearts run low.
        data.progress.gainHeart(now);
      }
    } else if (passed) {
      earnedXp = alreadyCompleted ? 5 : run.earnedXp;
      if (alreadyCompleted && run.wrong == 0) earnedXp += 3;
      earnedXp *= multiplier;
      if (run.isJumpTest && run.jumpTargetSectionId != null) {
        _unlockSectionsBefore(run.jumpTargetSectionId!, data.progress);
      }
      data.progress.completeLesson(
        lessonId: run.lesson.id,
        accuracy: accuracy,
        earnedXp: earnedXp,
        answered: answered,
        now: now,
      );
      if (run.lesson.isReview) {
        data.progress.completedCheckpoints.add(run.lesson.id);
      }
    } else {
      data.progress.recordFailedSession(
        lessonId: run.lesson.id,
        accuracy: accuracy,
        answered: answered,
        now: now,
      );
    }

    final streakAfter = data.progress.effectiveStreak;
    final result = LessonResult(
      lessonId: run.lesson.id,
      title: run.isPractice
          ? (run.practiceTitle ?? 'Practice')
          : run.lesson.title,
      passed: passed,
      accuracy: accuracy,
      xp: earnedXp,
      streak: streakAfter,
      answered: answered,
      bestCombo: run.bestCombo,
      isPractice: run.isPractice,
      leveledUp: earnedXp > 0 && data.progress.level > levelBefore,
      dailyGoalReached:
          earnedXp > 0 && !goalBefore && data.progress.xpTodayForDisplay >= goal,
      lessonUnlocked: passed &&
          !run.isPractice &&
          (run.isJumpTest || !alreadyCompleted),
      streakAdvanced: passed && !run.isPractice && streakAfter > streakBefore,
      streakMilestone:
          passed &&
          !run.isPractice &&
          streakAfter > streakBefore &&
          _streakMilestones.contains(streakAfter),
    );

    state = AsyncData(
      data.copyWith(progress: data.progress, clearRun: true, result: result),
    );
    await _save();
  }

  void exitLesson() {
    final data = _data;
    state = AsyncData(data.copyWith(clearRun: true));
  }

  void dismissResult() {
    final data = _data;
    state = AsyncData(data.copyWith(clearResult: true));
  }

  void retryLesson() {
    final data = _data;
    final result = data.result;
    if (result == null) return;
    if (result.isPractice) {
      startPractice(
        kind: result.lessonId.replaceFirst('practice_', ''),
        micAvailable: _lastMicAvailable,
      );
    } else if (result.lessonId.startsWith('jump_')) {
      startJumpTest(
        sectionId: result.lessonId.replaceFirst('jump_', ''),
        micAvailable: _lastMicAvailable,
      );
    } else {
      startLesson(result.lessonId, micAvailable: _lastMicAvailable);
    }
  }

  void _unlockSectionsBefore(String sectionId, ProgressState progress) {
    final sectionIndex = sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (sectionIndex <= 0) return;
    for (var index = 0; index < sectionIndex; index++) {
      for (final unit in sections[index].units) {
        for (final lesson in unit.lessons) {
          progress.completedLessons.add(lesson.id);
          progress.bestLessonAccuracy[lesson.id] =
              progress.bestLessonAccuracy[lesson.id] ?? 1;
        }
      }
    }
  }

  Future<bool> openChest(String chestId) async {
    final chest = chestById[chestId];
    if (chest == null) return false;
    final data = _data;
    final opened = data.progress.openChest(chest.id, chest.gems);
    if (!opened) return false;
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<bool> claimQuest(String questId) async {
    QuestDefinition? quest;
    for (final candidate in dailyQuestDefinitions) {
      if (candidate.id == questId) {
        quest = candidate;
        break;
      }
    }
    if (quest == null) return false;
    final data = _data;
    final claimed = data.progress.claimQuest(quest, DateTime.now());
    if (!claimed) return false;
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<bool> buyHeartRefill() async {
    final data = _data;
    final bought = data.progress.refillHearts(DateTime.now());
    if (!bought) return false;
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<bool> buyStreakFreeze() async {
    final data = _data;
    final bought = data.progress.buyStreakFreeze();
    if (!bought) return false;
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<bool> buyXpBoost() async {
    final data = _data;
    final bought = data.progress.buyXpBoost(DateTime.now());
    if (!bought) return false;
    state = AsyncData(data.copyWith(progress: data.progress));
    await _save();
    return true;
  }

  Future<void> resetProgress() async {
    final data = _data;
    final keepSettings = data.progress.settings;
    final fresh = ProgressState.fresh(
      settings: keepSettings.copyWith(onboardingComplete: true),
    );
    _applySoundSettings(fresh.settings);
    state = AsyncData(AppData(progress: fresh));
    try {
      await _store.clear();
    } catch (_) {}
    try {
      await _store.save(fresh);
    } catch (_) {}
  }

  Future<void> replaceProgress(ProgressState progress) async {
    _applySoundSettings(progress.settings);
    state = AsyncData(AppData(progress: progress));
    await _save();
  }
}

final appControllerProvider = AsyncNotifierProvider<AppController, AppData>(
  AppController.new,
);
