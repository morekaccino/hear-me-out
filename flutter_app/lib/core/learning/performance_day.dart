import 'progress.dart';

/// The rolling local-day window the performance cadence reads.
const int performancePracticeWindowDays = 7;

/// Distinct practice days required before a learner is put on stage.
const int performanceMinimumPracticeDays = 3;

/// The most performance days (days with a saved take) allowed in one window.
const int performanceMaximumPerformancesInWindow = 2;

/// Local calendar days that must pass after the most recent performance day.
const int performanceRestDays = 2;

/// Whether [now] is a performance day for this learner.
///
/// A performance day is a recital day: one take, no score while playing, and
/// feedback after. The cadence is deliberately sparse so recording is a weekly
/// event, not a per-session obligation:
///
/// 1. At least [performanceMinimumPracticeDays] distinct local days with real
///    guitar time in the last [performancePracticeWindowDays] days.
/// 2. At most [performanceMaximumPerformancesInWindow] local days with a saved
///    take in the same window.
/// 3. At least [performanceRestDays] local calendar days since the most recent
///    saved take.
/// 4. A learner who has never recorded is eligible once rule 1 passes.
///
/// [recordingTimes] are the real take timestamps from the recording index, not
/// phrase-progress evidence: the scored phrase loop is gated, so its
/// `performanceDays` cannot be the cadence source. They are converted to local
/// days; duplicate days count once, and future timestamps are ignored. The
/// practice-day count comes from [ProgressState.practiceSecondsByDay], so a
/// brand-new learner is never put on stage on day one.
///
/// This function is pure: no clock, storage, or widgets. It never invents a
/// stage day, and malformed practice-day keys simply never match a real day.
bool isPerformanceDay(
  ProgressState progress,
  Iterable<DateTime> recordingTimes,
  DateTime now,
) {
  if (progress.activePracticeDays(now, days: performancePracticeWindowDays) <
      performanceMinimumPracticeDays) {
    return false;
  }

  final today = _localDay(now);
  final performed = _performanceDays(recordingTimes, today);
  final windowStart = today.subtract(
    const Duration(days: performancePracticeWindowDays - 1),
  );
  final recent = performed.where((day) => !day.isBefore(windowStart)).length;
  if (recent >= performanceMaximumPerformancesInWindow) return false;
  if (performed.isEmpty) return true;
  return today.difference(performed.last).inDays >= performanceRestDays;
}

/// Distinct, past-or-today local days with a saved take, oldest first.
///
/// A malformed or future timestamp is ignored rather than thrown. The cadence
/// must never crash on bad data or stage a day that has not happened.
List<DateTime> _performanceDays(
  Iterable<DateTime> recordingTimes,
  DateTime today,
) {
  final days = <DateTime>{};
  for (final time in recordingTimes) {
    final day = _localDay(time);
    if (day.isAfter(today)) continue;
    days.add(day);
  }
  final sorted = days.toList()..sort();
  return sorted;
}

DateTime _localDay(DateTime time) {
  final local = time.toLocal();
  // UTC midnight keeps day subtraction exact across DST transitions.
  return DateTime.utc(local.year, local.month, local.day);
}
