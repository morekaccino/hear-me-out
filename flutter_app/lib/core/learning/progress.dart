import 'dart:math';

import '../music/curriculum.dart';
import '../music/note.dart';
import '../storage/progress_migrations.dart';
import 'note_objective.dart';
import 'phrase_progress.dart';
import 'prompt.dart';
import 'skill.dart';

export 'attempt_outcome.dart';
export 'phrase_progress.dart';
export 'prompt.dart' show AnswerMode, answerModeFromName;

enum AppThemeMode { system, light, dark }

AppThemeMode appThemeModeFromName(String? value) {
  return AppThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeMode.system,
  );
}

class AppSettings {
  const AppSettings({
    this.answerMode = AnswerMode.mixed,
    this.toleranceCents = 30,
    this.a4Hz = 440,
    this.haptics = true,
    this.soundEffects = true,
    this.dailyGoalXp = 20,
    this.onboardingComplete = false,
    this.themeMode = AppThemeMode.system,
  });

  final AnswerMode answerMode;
  final int toleranceCents;
  final double a4Hz;
  final bool haptics;
  final bool soundEffects;
  final int dailyGoalXp;
  final bool onboardingComplete;
  final AppThemeMode themeMode;

  AppSettings copyWith({
    AnswerMode? answerMode,
    int? toleranceCents,
    double? a4Hz,
    bool? haptics,
    bool? soundEffects,
    int? dailyGoalXp,
    bool? onboardingComplete,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      answerMode: answerMode ?? this.answerMode,
      toleranceCents: toleranceCents ?? this.toleranceCents,
      a4Hz: a4Hz ?? this.a4Hz,
      haptics: haptics ?? this.haptics,
      soundEffects: soundEffects ?? this.soundEffects,
      dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'answerMode': answerMode.name,
    'toleranceCents': toleranceCents,
    'a4Hz': a4Hz,
    'haptics': haptics,
    'soundEffects': soundEffects,
    'dailyGoalXp': dailyGoalXp,
    'onboardingComplete': onboardingComplete,
    'themeMode': themeMode.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    return AppSettings(
      answerMode: answerModeFromName(json['answerMode'] as String?),
      toleranceCents: (json['toleranceCents'] as num?)?.toInt() ?? 30,
      a4Hz: (json['a4Hz'] as num?)?.toDouble() ?? 440,
      haptics: json['haptics'] as bool? ?? true,
      soundEffects: json['soundEffects'] as bool? ?? true,
      dailyGoalXp: (json['dailyGoalXp'] as num?)?.toInt() ?? 20,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      themeMode: appThemeModeFromName(json['themeMode'] as String?),
    );
  }
}

/// Spaced-repetition intervals, indexed by the note's box after an answer.
const List<Duration> reviewIntervals = [
  Duration.zero,
  Duration(minutes: 10),
  Duration(days: 1),
  Duration(days: 3),
  Duration(days: 7),
  Duration(days: 21),
];

const int maxHearts = 5;
const Duration heartRegenInterval = Duration(hours: 4);
const int heartRefillCost = 350;
const int streakFreezeCost = 200;
const int maxStreakFreezes = 2;
const int xpBoostCost = 100;
const Duration xpBoostDuration = Duration(minutes: 15);
const int startingGems = 500;

/// Local-only quests. Each one maps to a counter in [DailyCounters].
class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.target,
    required this.rewardGems,
  });

  final String id;
  final String title;
  final String subtitle;
  final String kind;
  final int target;
  final int rewardGems;
}

const List<QuestDefinition> dailyQuestDefinitions = [
  QuestDefinition(
    id: 'lesson',
    title: 'Complete a lesson',
    subtitle: 'Finish one lesson today',
    kind: 'lessons',
    target: 1,
    rewardGems: 10,
  ),
  QuestDefinition(
    id: 'correct',
    title: 'Answer 10 notes',
    subtitle: 'Get ten answers right today',
    kind: 'correct',
    target: 10,
    rewardGems: 10,
  ),
  QuestDefinition(
    id: 'combo',
    title: 'Build a combo',
    subtitle: 'Get five correct answers in a row',
    kind: 'combo',
    target: 5,
    rewardGems: 15,
  ),
];

/// Counters that reset at local midnight. Stored inside [ProgressState].
class DailyCounters {
  DailyCounters({
    this.day,
    this.lessons = 0,
    this.correct = 0,
    this.practice = 0,
    this.bestCombo = 0,
  });

  String? day;
  int lessons;
  int correct;
  int practice;
  int bestCombo;

  void reset(String dayKey) {
    day = dayKey;
    lessons = 0;
    correct = 0;
    practice = 0;
    bestCombo = 0;
  }

  DailyCounters copy() => DailyCounters(
    day: day,
    lessons: lessons,
    correct: correct,
    practice: practice,
    bestCombo: bestCombo,
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'lessons': lessons,
    'correct': correct,
    'practice': practice,
    'bestCombo': bestCombo,
  };

  factory DailyCounters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DailyCounters();
    return DailyCounters(
      day: json['day'] as String?,
      lessons: (json['lessons'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      practice: (json['practice'] as num?)?.toInt() ?? 0,
      bestCombo: (json['bestCombo'] as num?)?.toInt() ?? 0,
    );
  }
}

class NoteProgress {
  NoteProgress({
    this.box = 0,
    this.dueAt,
    this.correct = 0,
    this.incorrect = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastSeenAt,
    Set<String>? correctDays,
    this.centsSamples = 0,
    this.centsTotal = 0,
  }) : correctDays = correctDays ?? <String>{};

  int box;
  DateTime? dueAt;
  int correct;
  int incorrect;
  int streak;
  int bestStreak;
  DateTime? lastSeenAt;
  final Set<String> correctDays;
  int centsSamples;
  double centsTotal;

  int get attempts => correct + incorrect;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  double get averageAbsCents =>
      centsSamples == 0 ? 0 : centsTotal / centsSamples;

  bool get mastered => box >= 4 && correct >= 5 && correctDays.length >= 2;

  bool get isDue => dueAt != null && !dueAt!.isAfter(DateTime.now());

  void recordAnswer({
    required bool correctAnswer,
    required DateTime now,
    double? absCents,
  }) {
    lastSeenAt = now;
    if (absCents != null && absCents.isFinite) {
      centsSamples++;
      centsTotal += absCents;
    }
    if (correctAnswer) {
      correct++;
      streak++;
      bestStreak = max(bestStreak, streak);
      correctDays.add(dayKey(now));
      box = min(5, box + 1);
      dueAt = now.add(reviewIntervals[box]);
    } else {
      incorrect++;
      streak = 0;
      box = max(0, box - 2);
      dueAt = now.add(const Duration(minutes: 1));
    }
  }

  NoteProgress copy() => NoteProgress(
    box: box,
    dueAt: dueAt,
    correct: correct,
    incorrect: incorrect,
    streak: streak,
    bestStreak: bestStreak,
    lastSeenAt: lastSeenAt,
    correctDays: {...correctDays},
    centsSamples: centsSamples,
    centsTotal: centsTotal,
  );

  Map<String, dynamic> toJson() => {
    'box': box,
    'dueAt': dueAt?.toIso8601String(),
    'correct': correct,
    'incorrect': incorrect,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastSeenAt': lastSeenAt?.toIso8601String(),
    'correctDays': correctDays.toList(),
    'centsSamples': centsSamples,
    'centsTotal': centsTotal,
  };

  factory NoteProgress.fromJson(Map<String, dynamic> json) {
    return NoteProgress(
      box: (json['box'] as num?)?.toInt() ?? 0,
      dueAt: _parseDate(json['dueAt']),
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      incorrect: (json['incorrect'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastSeenAt: _parseDate(json['lastSeenAt']),
      correctDays: {
        for (final day in (json['correctDays'] as List<dynamic>? ?? const []))
          if (day is String) day,
      },
      centsSamples: (json['centsSamples'] as num?)?.toInt() ?? 0,
      centsTotal: (json['centsTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SessionSummary {
  const SessionSummary({
    required this.lessonId,
    required this.accuracy,
    required this.xp,
    required this.answered,
    required this.completedAt,
    required this.passed,
  });

  final String lessonId;
  final double accuracy;
  final int xp;
  final int answered;
  final DateTime completedAt;
  final bool passed;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'accuracy': accuracy,
    'xp': xp,
    'answered': answered,
    'completedAt': completedAt.toIso8601String(),
    'passed': passed,
  };

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      lessonId: json['lessonId'] as String? ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      completedAt: _parseDate(json['completedAt']) ?? DateTime.now(),
      passed: json['passed'] as bool? ?? false,
    );
  }
}

class ProgressState {
  static const int currentSchemaVersion = latestProgressSchemaVersion;
  static const int currentCurriculumVersion = 3;

  ProgressState({
    this.schemaVersion = currentSchemaVersion,
    this.curriculumVersion = currentCurriculumVersion,
    this.contentVersion = 1,
    Map<String, NoteProgress>? notes,
    Map<String, SkillProgress>? skills,
    Map<String, PhraseProgress>? phraseProgress,
    Set<String>? completedLessons,
    Set<String>? legacyCompletedLessons,
    Map<String, double>? bestLessonAccuracy,
    Set<String>? completedCheckpoints,
    this.placementUnitId,
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastCompletedDay,
    this.xpToday = 0,
    this.xpDay,
    this.gems = startingGems,
    this.hearts = maxHearts,
    this.nextHeartAt,
    this.streakFreezes = 0,
    this.xpBoostUntil,
    Set<String>? openedChests,
    DailyCounters? daily,
    Set<String>? claimedQuests,
    this.questDay,
    this.settings = const AppSettings(),
    List<SessionSummary>? recentSessions,
    Map<String, dynamic>? extraFields,
  }) : notes = notes ?? <String, NoteProgress>{},
       skills = skills ?? <String, SkillProgress>{},
       phraseProgress = phraseProgress ?? <String, PhraseProgress>{},
       completedLessons = completedLessons ?? <String>{},
       legacyCompletedLessons = legacyCompletedLessons ?? <String>{},
       bestLessonAccuracy = bestLessonAccuracy ?? <String, double>{},
       completedCheckpoints = completedCheckpoints ?? <String>{},
       openedChests = openedChests ?? <String>{},
       daily = daily ?? DailyCounters(),
       claimedQuests = claimedQuests ?? <String>{},
       recentSessions = recentSessions ?? <SessionSummary>[],
       _extraFields = extraFields ?? <String, dynamic>{};

  final int schemaVersion;
  int curriculumVersion;

  /// Version of the bundled content catalogue, separate from the storage
  /// schema and from [curriculumVersion].
  int contentVersion;
  final Map<String, NoteProgress> notes;
  final Map<String, SkillProgress> skills;
  final Map<String, PhraseProgress> phraseProgress;
  final Set<String> completedLessons;
  final Set<String> legacyCompletedLessons;
  final Map<String, double> bestLessonAccuracy;
  final Set<String> completedCheckpoints;
  String? placementUnitId;
  int xp;
  int streak;
  int bestStreak;
  String? lastCompletedDay;
  int xpToday;
  String? xpDay;
  int gems;
  int hearts;
  DateTime? nextHeartAt;
  int streakFreezes;
  DateTime? xpBoostUntil;
  final Set<String> openedChests;
  final DailyCounters daily;
  final Set<String> claimedQuests;
  String? questDay;
  AppSettings settings;
  final List<SessionSummary> recentSessions;

  /// Top-level keys this build does not understand. They are written back so
  /// a newer build's fields survive a load/save through an older one.
  final Map<String, dynamic> _extraFields;

  NoteProgress noteFor(Note note) =>
      notes.putIfAbsent(note.id, () => NoteProgress());

  NoteProgress? progressFor(Note note) => notes[note.id];

  PhraseProgress? phraseProgressFor(String phraseId) =>
      phraseProgress[phraseId];

  SkillProgress? skillProgressFor(String objectiveId) => skills[objectiveId];

  SkillProgress skillFor(String objectiveId, SkillFamily family) =>
      skills.putIfAbsent(
        objectiveId,
        () => SkillProgress(objectiveId: objectiveId, family: family),
      );

  bool isLessonCompleted(String lessonId) =>
      completedLessons.contains(lessonId);

  bool isCheckpointCompleted(String checkpointId) =>
      completedCheckpoints.contains(checkpointId);

  int get masteredCount => notes.values.where((note) => note.mastered).length;

  int get learningCount =>
      notes.values.where((note) => note.attempts > 0 && !note.mastered).length;

  int get totalAttempts =>
      notes.values.fold(0, (sum, note) => sum + note.attempts);

  int get totalCorrect =>
      notes.values.fold(0, (sum, note) => sum + note.correct);

  double get accuracy {
    final attempts = totalAttempts;
    return attempts == 0 ? 0 : totalCorrect / attempts;
  }

  int get effectiveStreak => effectiveStreakAt(DateTime.now());

  int effectiveStreakAt(DateTime now) {
    final last = lastCompletedDay;
    if (last == null) return 0;
    final today = dayKey(now);
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));
    if (last == today || last == yesterday) return streak;
    // An equipped freeze keeps the streak visible until the next completed
    // lesson consumes it.
    if (streakFreezes > 0) return streak;
    return 0;
  }

  int get level => (xp ~/ 100) + 1;

  int get xpIntoLevel => xp % 100;

  int get xpTodayForDisplay {
    if (xpDay != dayKey(DateTime.now())) return 0;
    return xpToday;
  }

  int xpMultiplierAt(DateTime now) =>
      xpBoostUntil != null && xpBoostUntil!.isAfter(now) ? 2 : 1;

  bool get xpBoostActive =>
      xpBoostUntil != null && xpBoostUntil!.isAfter(DateTime.now());

  Duration? timeToNextHeart(DateTime now) {
    if (hearts >= maxHearts || nextHeartAt == null) return null;
    final remaining = nextHeartAt!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void addXp(int amount, DateTime now) {
    if (amount <= 0) return;
    final today = dayKey(now);
    if (xpDay != today) {
      xpDay = today;
      xpToday = 0;
    }
    xp += amount;
    xpToday += amount;
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    gems += amount;
  }

  bool spendGems(int amount) {
    if (amount <= 0) return true;
    if (gems < amount) return false;
    gems -= amount;
    return true;
  }

  void refreshHearts(DateTime now) {
    if (hearts >= maxHearts) {
      hearts = maxHearts;
      nextHeartAt = null;
      return;
    }
    final initial = nextHeartAt;
    if (initial == null) {
      nextHeartAt = now.add(heartRegenInterval);
      return;
    }
    var next = initial;
    while (hearts < maxHearts && !now.isBefore(next)) {
      hearts++;
      next = next.add(heartRegenInterval);
    }
    nextHeartAt = hearts >= maxHearts ? null : next;
  }

  bool loseHeart(DateTime now) {
    refreshHearts(now);
    if (hearts <= 0) return false;
    hearts--;
    nextHeartAt ??= now.add(heartRegenInterval);
    return true;
  }

  void gainHeart(DateTime now) {
    refreshHearts(now);
    if (hearts >= maxHearts) return;
    hearts++;
    if (hearts >= maxHearts) nextHeartAt = null;
  }

  bool refillHearts(DateTime now) {
    refreshHearts(now);
    if (hearts >= maxHearts || gems < heartRefillCost) return false;
    gems -= heartRefillCost;
    hearts = maxHearts;
    nextHeartAt = null;
    return true;
  }

  bool buyStreakFreeze() {
    if (gems < streakFreezeCost || streakFreezes >= maxStreakFreezes) {
      return false;
    }
    gems -= streakFreezeCost;
    streakFreezes++;
    return true;
  }

  bool buyXpBoost(DateTime now) {
    if (gems < xpBoostCost) return false;
    gems -= xpBoostCost;
    xpBoostUntil = now.add(xpBoostDuration);
    return true;
  }

  void refreshDaily(DateTime now) {
    final today = dayKey(now);
    if (daily.day != today) {
      daily.reset(today);
      claimedQuests.clear();
      questDay = today;
    }
  }

  void recordDailyCombo(int combo, DateTime now) {
    refreshDaily(now);
    if (combo > daily.bestCombo) daily.bestCombo = combo;
  }

  int questProgress(QuestDefinition quest) {
    return switch (quest.kind) {
      'lessons' => daily.lessons,
      'correct' => daily.correct,
      'practice' => daily.practice,
      'combo' => daily.bestCombo,
      _ => 0,
    };
  }

  bool isQuestComplete(QuestDefinition quest) =>
      questProgress(quest) >= quest.target;

  bool isQuestClaimed(QuestDefinition quest) =>
      claimedQuests.contains(quest.id);

  bool claimQuest(QuestDefinition quest, DateTime now) {
    refreshDaily(now);
    if (!isQuestComplete(quest) || isQuestClaimed(quest)) return false;
    claimedQuests.add(quest.id);
    addGems(quest.rewardGems);
    return true;
  }

  bool openChest(String chestId, int rewardGems) {
    if (openedChests.contains(chestId)) return false;
    openedChests.add(chestId);
    addGems(rewardGems);
    return true;
  }

  void recordSkillAnswer(SkillAnswer answer) {
    // Indeterminate means retry. Do not refresh the day, count an answer,
    // touch the scheduler, or update the legacy note view.
    if (answer.outcome == AttemptOutcome.indeterminate) return;

    refreshDaily(answer.now);
    if (answer.outcome == AttemptOutcome.correct) daily.correct++;
    final skill = skillFor(answer.objectiveId, answer.family);
    skill.recordAnswer(answer);

    if (answer.family == SkillFamily.noteReading) {
      final note = noteFromObjectiveId(answer.objectiveId);
      if (note != null) {
        noteFor(note).recordAnswer(
          correctAnswer: answer.outcome == AttemptOutcome.correct,
          now: answer.now,
          absCents: answer.absCents,
        );
      }
    }
  }

  /// Records phrase-level evidence only.
  ///
  /// Per-note skills are recorded separately from determinate note evidence;
  /// this method never touches [skills] or [notes], so one take cannot count
  /// as both phrase and note evidence. An indeterminate phrase is a no-op.
  void recordPhraseAttempt(PhraseAttempt attempt) {
    if (attempt.outcome == AttemptOutcome.indeterminate) return;
    final phrase = phraseProgress.putIfAbsent(
      attempt.phraseId,
      () => PhraseProgress(phraseId: attempt.phraseId),
    );
    phrase.recordAttempt(attempt);
  }

  void recordAnswer({
    required Note note,
    required AttemptOutcome outcome,
    required DateTime now,
    double? absCents,
    bool production = false,
    bool transfer = false,
    bool usedHint = false,
    bool revealed = false,
    int responseMs = 0,
    String? templateId,
  }) {
    if (outcome == AttemptOutcome.indeterminate) return;
    recordSkillAnswer(
      SkillAnswer(
        objectiveId: 'note:${note.id}',
        family: SkillFamily.noteReading,
        outcome: outcome,
        now: now,
        absCents: absCents,
        production: production,
        transfer: transfer,
        usedHint: usedHint,
        revealed: revealed,
        responseMs: responseMs,
        templateId: templateId,
      ),
    );
  }

  void completeLesson({
    required String lessonId,
    required double accuracy,
    required int earnedXp,
    required int answered,
    required DateTime now,
  }) {
    refreshDaily(now);
    completedLessons.add(lessonId);
    bestLessonAccuracy[lessonId] = max(
      bestLessonAccuracy[lessonId] ?? 0,
      accuracy,
    );
    daily.lessons++;
    addXp(earnedXp, now);

    final today = dayKey(now);
    if (lastCompletedDay != today) {
      final yesterday = dayKey(now.subtract(const Duration(days: 1)));
      if (lastCompletedDay == yesterday) {
        streak++;
      } else if (lastCompletedDay != null && streakFreezes > 0) {
        streakFreezes--;
        streak++;
      } else {
        streak = 1;
      }
      bestStreak = max(bestStreak, streak);
      lastCompletedDay = today;
    }

    recentSessions.add(
      SessionSummary(
        lessonId: lessonId,
        accuracy: accuracy,
        xp: earnedXp,
        answered: answered,
        completedAt: now,
        passed: true,
      ),
    );
    if (recentSessions.length > 30) {
      recentSessions.removeRange(0, recentSessions.length - 30);
    }
  }

  void recordPractice(DateTime now) {
    refreshDaily(now);
    daily.practice++;
  }

  void recordFailedSession({
    required String lessonId,
    required double accuracy,
    required int answered,
    required DateTime now,
  }) {
    recentSessions.add(
      SessionSummary(
        lessonId: lessonId,
        accuracy: accuracy,
        xp: 0,
        answered: answered,
        completedAt: now,
        passed: false,
      ),
    );
    if (recentSessions.length > 30) {
      recentSessions.removeRange(0, recentSessions.length - 30);
    }
  }

  List<Note> dueNotes(DateTime now, {Iterable<Note>? pool}) {
    final candidates = pool ?? noteCatalog;
    final due = <(Note, NoteProgress)>[];
    for (final note in candidates) {
      final progress = notes[note.id];
      if (progress != null &&
          progress.dueAt != null &&
          !progress.dueAt!.isAfter(now)) {
        due.add((note, progress));
      }
    }
    due.sort((a, b) => a.$2.dueAt!.compareTo(b.$2.dueAt!));
    return [for (final entry in due) entry.$1];
  }

  List<Note> weakNotes({int limit = 20}) {
    final weak =
        notes.entries
            .where(
              (entry) =>
                  entry.value.attempts >= 2 && entry.value.accuracy < 0.75,
            )
            .toList()
          ..sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    return [
      for (final entry in weak.take(limit))
        if (Note.tryParse(entry.key) != null) Note.parse(entry.key),
    ];
  }

  List<SkillProgress> dueSkills(DateTime now, {Iterable<SkillProgress>? pool}) {
    final due = <SkillProgress>[
      for (final skill in pool ?? skills.values)
        if (skill.dueAt != null && !skill.dueAt!.isAfter(now)) skill,
    ]..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return due;
  }

  List<SkillProgress> weakSkills({int limit = 20}) {
    final weak =
        skills.values
            .where(
              (skill) =>
                  skill.attempts >= 2 &&
                  (skill.accuracy < 0.75 || skill.fragile),
            )
            .toList()
          ..sort((a, b) {
            final fragility = (b.fragile ? 1 : 0).compareTo(a.fragile ? 1 : 0);
            if (fragility != 0) return fragility;
            return a.accuracy.compareTo(b.accuracy);
          });
    return weak.take(limit).toList();
  }

  List<SkillProgress> fragileSkills({int limit = 20}) {
    final fragile = skills.values.where((skill) => skill.fragile).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return fragile.take(limit).toList();
  }

  int get masteredSkillCount =>
      skills.values.where((skill) => skill.mastered).length;

  int get totalSkillAttempts =>
      skills.values.fold(0, (sum, skill) => sum + skill.attempts);

  ProgressState copy() => ProgressState(
    schemaVersion: schemaVersion,
    curriculumVersion: curriculumVersion,
    contentVersion: contentVersion,
    notes: {for (final entry in notes.entries) entry.key: entry.value.copy()},
    skills: {for (final entry in skills.entries) entry.key: entry.value.copy()},
    phraseProgress: {
      for (final entry in phraseProgress.entries) entry.key: entry.value.copy(),
    },
    completedLessons: {...completedLessons},
    legacyCompletedLessons: {...legacyCompletedLessons},
    bestLessonAccuracy: {...bestLessonAccuracy},
    completedCheckpoints: {...completedCheckpoints},
    placementUnitId: placementUnitId,
    xp: xp,
    streak: streak,
    bestStreak: bestStreak,
    lastCompletedDay: lastCompletedDay,
    xpToday: xpToday,
    xpDay: xpDay,
    gems: gems,
    hearts: hearts,
    nextHeartAt: nextHeartAt,
    streakFreezes: streakFreezes,
    xpBoostUntil: xpBoostUntil,
    openedChests: {...openedChests},
    daily: daily.copy(),
    claimedQuests: {...claimedQuests},
    questDay: questDay,
    settings: settings,
    recentSessions: [...recentSessions],
    extraFields: {..._extraFields},
  );

  Map<String, dynamic> toJson() => {
    ..._extraFields,
    'schemaVersion': schemaVersion,
    'curriculumVersion': curriculumVersion,
    'contentVersion': contentVersion,
    'notes': {
      for (final entry in notes.entries) entry.key: entry.value.toJson(),
    },
    'skills': {
      for (final entry in skills.entries) entry.key: entry.value.toJson(),
    },
    'phraseProgress': {
      for (final entry in phraseProgress.entries)
        entry.key: entry.value.toJson(),
    },
    'completedLessons': completedLessons.toList(),
    'legacyCompletedLessons': legacyCompletedLessons.toList(),
    'bestLessonAccuracy': bestLessonAccuracy,
    'completedCheckpoints': completedCheckpoints.toList(),
    'placementUnitId': placementUnitId,
    'xp': xp,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastCompletedDay': lastCompletedDay,
    'xpToday': xpToday,
    'xpDay': xpDay,
    'gems': gems,
    'hearts': hearts,
    'nextHeartAt': nextHeartAt?.toIso8601String(),
    'streakFreezes': streakFreezes,
    'xpBoostUntil': xpBoostUntil?.toIso8601String(),
    'openedChests': openedChests.toList(),
    'daily': daily.toJson(),
    'claimedQuests': claimedQuests.toList(),
    'questDay': questDay,
    'settings': settings.toJson(),
    'recentSessions': [for (final session in recentSessions) session.toJson()],
  };

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    final result = migrateProgress(json);
    if (result is MigrationFailure) {
      throw FormatException('Cannot read progress: ${result.reason}');
    }
    try {
      return ProgressState._fromMigratedJson((result as MigrationSuccess).json);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Cannot read progress: $error');
    }
  }

  factory ProgressState._fromMigratedJson(Map<String, dynamic> json) {
    final state = ProgressState(
      schemaVersion: currentSchemaVersion,
      curriculumVersion: (json['curriculumVersion'] as num?)?.toInt() ?? 1,
      contentVersion: (json['contentVersion'] as num?)?.toInt() ?? 1,
      notes: {
        for (final entry
            in (json['notes'] as Map<String, dynamic>? ?? const {}).entries)
          entry.key: NoteProgress.fromJson(entry.value as Map<String, dynamic>),
      },
      skills: {
        for (final entry
            in (json['skills'] as Map<String, dynamic>? ?? const {}).entries)
          if (entry.value is Map<String, dynamic>)
            entry.key: SkillProgress.fromJson(
              entry.value as Map<String, dynamic>,
            ),
      },
      phraseProgress: _parsePhraseProgress(
        json['phraseProgress'] as Map<String, dynamic>?,
      ),
      completedLessons: {
        for (final id
            in (json['completedLessons'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      legacyCompletedLessons: {
        for (final id
            in (json['legacyCompletedLessons'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      bestLessonAccuracy: {
        for (final entry
            in (json['bestLessonAccuracy'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: (entry.value as num?)?.toDouble() ?? 0,
      },
      completedCheckpoints: {
        for (final id
            in (json['completedCheckpoints'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      placementUnitId: json['placementUnitId'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDay: json['lastCompletedDay'] as String?,
      xpToday: (json['xpToday'] as num?)?.toInt() ?? 0,
      xpDay: json['xpDay'] as String?,
      gems: (json['gems'] as num?)?.toInt() ?? startingGems,
      hearts: (json['hearts'] as num?)?.toInt() ?? maxHearts,
      nextHeartAt: _parseDate(json['nextHeartAt']),
      streakFreezes: (json['streakFreezes'] as num?)?.toInt() ?? 0,
      xpBoostUntil: _parseDate(json['xpBoostUntil']),
      openedChests: {
        for (final id in (json['openedChests'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      daily: DailyCounters.fromJson(json['daily'] as Map<String, dynamic>?),
      claimedQuests: {
        for (final id in (json['claimedQuests'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      questDay: json['questDay'] as String?,
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      recentSessions: [
        for (final session
            in (json['recentSessions'] as List<dynamic>? ?? const []))
          if (session is Map<String, dynamic>) SessionSummary.fromJson(session),
      ],
      extraFields: {
        for (final entry in json.entries)
          if (!_progressTopLevelKeys.contains(entry.key))
            entry.key: entry.value,
      },
    );
    state._migrateCurriculum();
    return state;
  }

  void _migrateCurriculum() {
    if (curriculumVersion >= currentCurriculumVersion) return;

    final mappedLessons = <String>{
      for (final id in completedLessons) legacyLessonIdMap[id] ?? id,
    };
    completedLessons
      ..clear()
      ..addAll(mappedLessons);

    final mappedAccuracy = <String, double>{};
    for (final entry in bestLessonAccuracy.entries) {
      final id = legacyLessonIdMap[entry.key] ?? entry.key;
      mappedAccuracy[id] = max(mappedAccuracy[id] ?? 0, entry.value);
    }
    bestLessonAccuracy
      ..clear()
      ..addAll(mappedAccuracy);

    for (var index = 0; index < recentSessions.length; index++) {
      final session = recentSessions[index];
      final mappedId = legacyLessonIdMap[session.lessonId];
      if (mappedId == null) continue;
      recentSessions[index] = SessionSummary(
        lessonId: mappedId,
        accuracy: session.accuracy,
        xp: session.xp,
        answered: session.answered,
        completedAt: session.completedAt,
        passed: session.passed,
      );
    }

    curriculumVersion = currentCurriculumVersion;
  }

  factory ProgressState.fresh({AppSettings settings = const AppSettings()}) =>
      ProgressState(settings: settings);
}

Map<String, PhraseProgress> _parsePhraseProgress(Map<String, dynamic>? json) {
  if (json == null) return <String, PhraseProgress>{};
  final result = <String, PhraseProgress>{};
  for (final entry in json.entries) {
    final value = entry.value;
    if (value is! Map) {
      throw FormatException('phraseProgress.${entry.key} must be an object');
    }
    result[entry.key] = PhraseProgress.fromJson(
      Map<String, dynamic>.from(value),
      phraseId: entry.key,
    );
  }
  return result;
}

/// Every top-level key this build writes. Anything else is preserved as
/// forward-compatible data and re-emitted by [ProgressState.toJson].
const Set<String> _progressTopLevelKeys = {
  'schemaVersion',
  'curriculumVersion',
  'contentVersion',
  'notes',
  'skills',
  'phraseProgress',
  'completedLessons',
  'legacyCompletedLessons',
  'bestLessonAccuracy',
  'completedCheckpoints',
  'placementUnitId',
  'xp',
  'streak',
  'bestStreak',
  'lastCompletedDay',
  'xpToday',
  'xpDay',
  'gems',
  'hearts',
  'nextHeartAt',
  'streakFreezes',
  'xpBoostUntil',
  'openedChests',
  'daily',
  'claimedQuests',
  'questDay',
  'settings',
  'recentSessions',
};

DateTime? _parseDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
