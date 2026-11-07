import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/attempt_outcome.dart';
import 'package:hear_me_out/core/learning/phrase_progress.dart';

void main() {
  PhraseAttempt attempt({
    AttemptOutcome outcome = AttemptOutcome.correct,
    double accuracy = 1,
    int? tempo = 72,
    int? target = 72,
    DateTime? day,
    int? contentVersion,
  }) {
    return PhraseAttempt(
      phraseId: 'study-p1',
      outcome: outcome,
      now: day ?? DateTime(2026, 1, 1, 10),
      accuracy: accuracy,
      tempoBpm: tempo,
      targetTempoBpm: target,
      contentVersion: contentVersion,
    );
  }

  PhraseProgress phrase() => PhraseProgress(phraseId: 'study-p1');

  void recordThreeDays(
    PhraseProgress progress, {
    DateTime? first,
    DateTime? second,
    DateTime? third,
  }) {
    progress.recordAttempt(attempt(day: first ?? DateTime(2026, 1, 1, 10)));
    progress.recordAttempt(attempt(day: second ?? DateTime(2026, 1, 4, 10)));
    progress.recordAttempt(attempt(day: third ?? DateTime(2026, 1, 8, 10)));
  }

  group('mastery days', () {
    test('a correct full-accuracy take at target counts', () {
      final progress = phrase()..recordAttempt(attempt());

      expect(progress.masteryDays, {'2026-01-01'});
      expect(progress.firstMasteryDay, '2026-01-01');
      expect(progress.lastMasteryAt, DateTime(2026, 1, 1, 10));
    });

    test('a take above target still counts', () {
      final progress = phrase()..recordAttempt(attempt(tempo: 80, target: 72));

      expect(progress.masteryDays, {'2026-01-01'});
    });

    test('a slow take does not count', () {
      final progress = phrase()..recordAttempt(attempt(tempo: 60, target: 72));

      expect(progress.masteryDays, isEmpty);
      expect(progress.firstMasteryDay, isNull);
      expect(progress.lastMasteryAt, isNull);
    });

    test('a below-full-accuracy take does not count', () {
      final progress = phrase()..recordAttempt(attempt(accuracy: 0.99));

      expect(progress.masteryDays, isEmpty);
    });

    test('a failed take does not count', () {
      final progress = phrase()
        ..recordAttempt(attempt(outcome: AttemptOutcome.incorrect));

      expect(progress.masteryDays, isEmpty);
      expect(progress.performanceDays, {'2026-01-01'});
    });

    test('an indeterminate take changes nothing', () {
      final progress = phrase()
        ..recordAttempt(attempt(outcome: AttemptOutcome.indeterminate));

      expect(progress.masteryDays, isEmpty);
      expect(progress.performanceDays, isEmpty);
      expect(progress.reps, 0);
    });

    test('a take without a target tempo does not count', () {
      final progress = phrase()..recordAttempt(attempt(target: null));

      expect(progress.masteryDays, isEmpty);
    });

    test('a take without a played tempo does not count', () {
      final progress = phrase()..recordAttempt(attempt(tempo: null));

      expect(progress.masteryDays, isEmpty);
    });

    test('raw performance evidence stays untouched', () {
      final progress = phrase()
        ..recordAttempt(attempt(tempo: 60, target: 72))
        ..recordAttempt(attempt(outcome: AttemptOutcome.incorrect))
        ..recordAttempt(attempt(tempo: 90, target: 72));

      expect(progress.performanceDays, hasLength(1));
      expect(progress.bestTempoBpm, 90);
      expect(progress.bestAccuracy, 1);
      expect(progress.masteryDays, {'2026-01-01'});
    });
  });

  group('isPerformanceMastered', () {
    test('three days at least seven days apart qualifies', () {
      final progress = phrase();
      recordThreeDays(progress);

      expect(progress.isPerformanceMastered(1), isTrue);
    });

    test('two days never qualify', () {
      final progress = phrase()
        ..recordAttempt(attempt(day: DateTime(2026, 1, 1)))
        ..recordAttempt(attempt(day: DateTime(2026, 1, 9)));

      expect(progress.isPerformanceMastered(1), isFalse);
    });

    test('a six-day span never qualifies', () {
      final progress = phrase();
      recordThreeDays(
        progress,
        first: DateTime(2026, 1, 1),
        second: DateTime(2026, 1, 4),
        third: DateTime(2026, 1, 7),
      );

      expect(progress.isPerformanceMastered(1), isFalse);
    });

    test('a stale content version never qualifies', () {
      final progress = phrase();
      recordThreeDays(progress);

      expect(progress.isPerformanceMastered(1), isTrue);
      expect(progress.isPerformanceMastered(2), isFalse);
    });

    test('two mastery days plus one failed day never qualify', () {
      final progress = phrase()
        ..recordAttempt(attempt(day: DateTime(2026, 1, 1)))
        ..recordAttempt(attempt(day: DateTime(2026, 1, 5)))
        ..recordAttempt(
          attempt(
            outcome: AttemptOutcome.incorrect,
            day: DateTime(2026, 1, 12),
          ),
        );

      expect(progress.masteryDays, {'2026-01-01', '2026-01-05'});
      expect(progress.isPerformanceMastered(1), isFalse);
    });

    test('a same-day repeat cannot stand in for a separate day', () {
      final progress = phrase()
        ..recordAttempt(attempt(day: DateTime(2026, 1, 1, 8)))
        ..recordAttempt(attempt(day: DateTime(2026, 1, 1, 20)))
        ..recordAttempt(attempt(day: DateTime(2026, 1, 9)));

      expect(progress.masteryDays, hasLength(2));
      expect(progress.isPerformanceMastered(1), isFalse);
    });
  });

  group('the optional fields serialize honestly', () {
    test('an empty progress document omits the mastery keys', () {
      final json = phrase().toJson();

      expect(json.containsKey('masteryDays'), isFalse);
      expect(json.containsKey('firstMasteryDay'), isFalse);
      expect(json.containsKey('lastMasteryAt'), isFalse);
    });

    test('round-trip keeps the mastery evidence and still qualifies', () {
      final progress = phrase();
      recordThreeDays(progress);

      final restored = PhraseProgress.fromJson(progress.toJson());

      expect(restored.masteryDays, progress.masteryDays);
      expect(restored.firstMasteryDay, '2026-01-01');
      expect(restored.lastMasteryAt, DateTime(2026, 1, 8, 10));
      expect(restored.isPerformanceMastered(1), isTrue);
    });

    test('a document without the new fields defaults them empty', () {
      final restored = PhraseProgress.fromJson(<String, dynamic>{
        'phraseId': 'study-p1',
        'reps': 2,
        'correct': 1,
        'incorrect': 1,
        'performanceDays': <String>['2026-01-01'],
        'firstPerformanceDay': '2026-01-01',
      });

      expect(restored.masteryDays, isEmpty);
      expect(restored.firstMasteryDay, isNull);
      expect(restored.lastMasteryAt, isNull);
      expect(restored.isPerformanceMastered(1), isFalse);
    });
  });
}
