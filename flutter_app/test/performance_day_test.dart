import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/performance_day.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final now = DateTime(2026, 11, 6, 10, 30);

  ProgressState progressWithPracticeDays(List<int> offsetsFromToday) {
    final days = <String, int>{};
    for (final offset in offsetsFromToday) {
      days[dayKey(DateTime(now.year, now.month, now.day - offset))] = 300;
    }
    return ProgressState(
      settings: const AppSettings(onboardingComplete: true),
      practiceSecondsByDay: days,
    );
  }

  /// A saved-take timestamp that lands on a given local day.
  ///
  /// Noon local time keeps the day stable when the policy converts it back to
  /// local time, regardless of the test machine's timezone. Storage writes UTC,
  /// so the test passes UTC to match the recording index.
  DateTime takeOnLocalDay(int offsetFromToday) {
    return DateTime(now.year, now.month, now.day - offsetFromToday, 12).toUtc();
  }

  group('isPerformanceDay', () {
    test('a brand-new learner is never on stage on day one', () {
      expect(isPerformanceDay(ProgressState(), const [], now), isFalse);
    });

    test('three practice days with no take history opens the stage', () {
      final progress = progressWithPracticeDays([0, 1, 2]);

      expect(isPerformanceDay(progress, const [], now), isTrue);
    });

    test('two practice days are not enough, even with no take history', () {
      final progress = progressWithPracticeDays([0, 1]);

      expect(isPerformanceDay(progress, const [], now), isFalse);
    });

    test('a take yesterday is a rest day, not another performance day', () {
      final progress = progressWithPracticeDays([0, 1, 2]);

      expect(isPerformanceDay(progress, [takeOnLocalDay(1)], now), isFalse);
    });

    test('two performance days in the last seven close the stage', () {
      final progress = progressWithPracticeDays([0, 1, 2]);
      final takes = [takeOnLocalDay(1), takeOnLocalDay(3)];

      // The latest take is three days ago (rest satisfied), but two days in
      // the window is already the weekly cap.
      expect(isPerformanceDay(progress, takes, now), isFalse);
    });

    test('a take three days ago with a practice habit opens the stage', () {
      final progress = progressWithPracticeDays([0, 1, 2]);

      expect(isPerformanceDay(progress, [takeOnLocalDay(3)], now), isTrue);
    });

    test('two takes on one local day still count as one performance day', () {
      final progress = progressWithPracticeDays([0, 1, 2]);
      final takes = [takeOnLocalDay(3), takeOnLocalDay(3)];

      expect(isPerformanceDay(progress, takes, now), isTrue);
    });

    test('a take older than the window does not force a rest day', () {
      final progress = progressWithPracticeDays([0, 1, 2]);

      expect(isPerformanceDay(progress, [takeOnLocalDay(8)], now), isTrue);
    });

    test('future timestamps are ignored and never invent a stage day', () {
      final progress = progressWithPracticeDays([0, 1, 2]);
      final future = now.add(const Duration(days: 4)).toUtc();

      expect(isPerformanceDay(progress, [future], now), isTrue);
    });

    test('malformed practice-day keys are ignored without crashing', () {
      final progress = ProgressState(
        practiceSecondsByDay: {
          'not-a-day': 999,
          '2026-13-40': 999,
          dayKey(DateTime(now.year, now.month, now.day)): 300,
          dayKey(DateTime(now.year, now.month, now.day - 1)): 300,
          dayKey(DateTime(now.year, now.month, now.day - 2)): 300,
        },
      );

      expect(isPerformanceDay(progress, const [], now), isTrue);
      expect(isPerformanceDay(progress, [takeOnLocalDay(3)], now), isTrue);
    });

    test('the window is local and inclusive of today', () {
      // Six days ago is inside the seven-day window; seven days ago is not.
      final aroundEdge = progressWithPracticeDays([0, 3, 6, 7]);

      expect(aroundEdge.activePracticeDays(now, days: 7), 3);
      expect(isPerformanceDay(aroundEdge, const [], now), isTrue);
    });
  });
}
