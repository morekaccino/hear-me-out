import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/learning/progress.dart';
import '../core/learning/session_builder.dart';
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
    final exercises = buildLessonExercises(
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
    state = AsyncData(data.copyWith(run: run, clearResult: true));
  }

  void startPractice({required String kind, required bool micAvailable}) {
    _lastMicAvailable = micAvailable;
    final data = _data;
    final exercises = buildPracticeExercises(
      kind: kind,
      progress: data.progress,
      now: DateTime.now(),
      micAvailable: micAvailable,
      mode: data.progress.settings.answerMode,
    );
    final title = switch (kind) {
      'due' => 'Due review',
      'weak' => 'Weak notes',
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
    state = AsyncData(data.copyWith(run: run, clearResult: true));
  }

  Future<void> submitAnswer({
    required bool correct,
    double? cents,
    Note? detected,
    bool octaveError = false,
  }) async {
    final data = _data;
    final run = data.run;
    if (run == null || run.awaitingNext || run.isFinished) return;

    final target = run.current.note;
    data.progress.recordAnswer(
      note: target,
      correctAnswer: correct,
      now: DateTime.now(),
      absCents: cents,
    );

    run.lastTarget = target;
    run.lastCorrect = correct;
    run.lastOctaveError = octaveError;
    run.lastCents = cents;
    run.lastDetected = detected;
    run.awaitingNext = true;

    if (correct) {
      run.correct++;
      run.combo++;
      run.bestCombo = run.bestCombo < run.combo ? run.combo : run.bestCombo;
    } else {
      run.wrong++;
      run.combo = 0;
      run.queueMistake(run.current);
      if (!run.isPractice) {
        run.lives = run.lives > 0 ? run.lives - 1 : 0;
      }
    }

    state = AsyncData(data.copyWith(run: run));
    await _save();
  }

  Future<void> nextExercise() async {
    final data = _data;
    final run = data.run;
    if (run == null || !run.awaitingNext) return;

    if (!run.isPractice && run.outOfLives) {
      await _finish(passed: false);
      return;
    }
    if (run.index >= run.exercises.length - 1 && !run.appendNextMistake()) {
      await _finish(passed: true);
      return;
    }

    run.index++;
    run.awaitingNext = false;
    run.lastCorrect = null;
    run.lastOctaveError = false;
    run.lastCents = null;
    run.lastDetected = null;
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
    var earnedXp = 0;

    if (run.isPractice) {
      if (passed) {
        earnedXp = run.earnedXp;
        data.progress.addXp(earnedXp, now);
      }
    } else if (passed) {
      earnedXp = alreadyCompleted ? 5 : run.earnedXp;
      if (alreadyCompleted && run.wrong == 0) earnedXp += 3;
      data.progress.completeLesson(
        lessonId: run.lesson.id,
        accuracy: accuracy,
        earnedXp: earnedXp,
        answered: answered,
        now: now,
      );
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
      lessonUnlocked: passed && !run.isPractice && !alreadyCompleted,
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
    } else {
      startLesson(result.lessonId, micAvailable: _lastMicAvailable);
    }
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
