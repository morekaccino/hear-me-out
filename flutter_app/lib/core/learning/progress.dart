import 'dart:math';

import '../music/curriculum.dart';
import '../music/note.dart';

enum AnswerMode { mixed, name, play }

AnswerMode answerModeFromName(String? value) {
  return AnswerMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AnswerMode.mixed,
  );
}

class AppSettings {
  const AppSettings({
    this.answerMode = AnswerMode.mixed,
    this.toleranceCents = 30,
    this.a4Hz = 440,
    this.haptics = true,
    this.dailyGoalXp = 20,
    this.onboardingComplete = false,
  });

  final AnswerMode answerMode;
  final int toleranceCents;
  final double a4Hz;
  final bool haptics;
  final int dailyGoalXp;
  final bool onboardingComplete;

  AppSettings copyWith({
    AnswerMode? answerMode,
    int? toleranceCents,
    double? a4Hz,
    bool? haptics,
    int? dailyGoalXp,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      answerMode: answerMode ?? this.answerMode,
      toleranceCents: toleranceCents ?? this.toleranceCents,
      a4Hz: a4Hz ?? this.a4Hz,
      haptics: haptics ?? this.haptics,
      dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'answerMode': answerMode.name,
    'toleranceCents': toleranceCents,
    'a4Hz': a4Hz,
    'haptics': haptics,
    'dailyGoalXp': dailyGoalXp,
    'onboardingComplete': onboardingComplete,
  };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    return AppSettings(
      answerMode: answerModeFromName(json['answerMode'] as String?),
      toleranceCents: (json['toleranceCents'] as num?)?.toInt() ?? 30,
      a4Hz: (json['a4Hz'] as num?)?.toDouble() ?? 440,
      haptics: json['haptics'] as bool? ?? true,
      dailyGoalXp: (json['dailyGoalXp'] as num?)?.toInt() ?? 20,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
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
  ProgressState({
    this.schemaVersion = 1,
    Map<String, NoteProgress>? notes,
    Set<String>? completedLessons,
    Map<String, double>? bestLessonAccuracy,
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastCompletedDay,
    this.xpToday = 0,
    this.xpDay,
    this.settings = const AppSettings(),
    List<SessionSummary>? recentSessions,
  }) : notes = notes ?? <String, NoteProgress>{},
       completedLessons = completedLessons ?? <String>{},
       bestLessonAccuracy = bestLessonAccuracy ?? <String, double>{},
       recentSessions = recentSessions ?? <SessionSummary>[];

  final int schemaVersion;
  final Map<String, NoteProgress> notes;
  final Set<String> completedLessons;
  final Map<String, double> bestLessonAccuracy;
  int xp;
  int streak;
  int bestStreak;
  String? lastCompletedDay;
  int xpToday;
  String? xpDay;
  AppSettings settings;
  final List<SessionSummary> recentSessions;

  NoteProgress noteFor(Note note) =>
      notes.putIfAbsent(note.id, () => NoteProgress());

  NoteProgress? progressFor(Note note) => notes[note.id];

  bool isLessonCompleted(String lessonId) =>
      completedLessons.contains(lessonId);

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
    return (last == today || last == yesterday) ? streak : 0;
  }

  int get level => (xp ~/ 100) + 1;

  int get xpIntoLevel => xp % 100;

  int get xpTodayForDisplay {
    if (xpDay != dayKey(DateTime.now())) return 0;
    return xpToday;
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

  void recordAnswer({
    required Note note,
    required bool correctAnswer,
    required DateTime now,
    double? absCents,
  }) {
    noteFor(
      note,
    ).recordAnswer(correctAnswer: correctAnswer, now: now, absCents: absCents);
  }

  void completeLesson({
    required String lessonId,
    required double accuracy,
    required int earnedXp,
    required int answered,
    required DateTime now,
  }) {
    completedLessons.add(lessonId);
    bestLessonAccuracy[lessonId] = max(
      bestLessonAccuracy[lessonId] ?? 0,
      accuracy,
    );
    addXp(earnedXp, now);

    final today = dayKey(now);
    if (lastCompletedDay != today) {
      final yesterday = dayKey(now.subtract(const Duration(days: 1)));
      streak = lastCompletedDay == yesterday ? streak + 1 : 1;
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

  ProgressState copy() => ProgressState(
    schemaVersion: schemaVersion,
    notes: {for (final entry in notes.entries) entry.key: entry.value.copy()},
    completedLessons: {...completedLessons},
    bestLessonAccuracy: {...bestLessonAccuracy},
    xp: xp,
    streak: streak,
    bestStreak: bestStreak,
    lastCompletedDay: lastCompletedDay,
    xpToday: xpToday,
    xpDay: xpDay,
    settings: settings,
    recentSessions: [...recentSessions],
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'notes': {
      for (final entry in notes.entries) entry.key: entry.value.toJson(),
    },
    'completedLessons': completedLessons.toList(),
    'bestLessonAccuracy': bestLessonAccuracy,
    'xp': xp,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastCompletedDay': lastCompletedDay,
    'xpToday': xpToday,
    'xpDay': xpDay,
    'settings': settings.toJson(),
    'recentSessions': [for (final session in recentSessions) session.toJson()],
  };

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    return ProgressState(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      notes: {
        for (final entry
            in (json['notes'] as Map<String, dynamic>? ?? const {}).entries)
          entry.key: NoteProgress.fromJson(entry.value as Map<String, dynamic>),
      },
      completedLessons: {
        for (final id
            in (json['completedLessons'] as List<dynamic>? ?? const []))
          if (id is String) id,
      },
      bestLessonAccuracy: {
        for (final entry
            in (json['bestLessonAccuracy'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: (entry.value as num?)?.toDouble() ?? 0,
      },
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDay: json['lastCompletedDay'] as String?,
      xpToday: (json['xpToday'] as num?)?.toInt() ?? 0,
      xpDay: json['xpDay'] as String?,
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      recentSessions: [
        for (final session
            in (json['recentSessions'] as List<dynamic>? ?? const []))
          if (session is Map<String, dynamic>) SessionSummary.fromJson(session),
      ],
    );
  }

  factory ProgressState.fresh({AppSettings settings = const AppSettings()}) =>
      ProgressState(settings: settings);
}

DateTime? _parseDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
