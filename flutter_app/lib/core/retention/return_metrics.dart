import 'retention_event.dart';
import 'retention_log.dart';

/// The elapsed window in which the next session counts as session 2.
///
/// This is 48 elapsed hours, not two calendar days: a session at 09:00 and one
/// at 21:00 the next day is 36 hours, while two sessions 49 hours apart do not
/// count even when they fall on adjacent local dates. KC-03 anchors the window
/// on session 1's `session_start`, never on its completion or on the install.
const Duration sessionTwoReturnWindow = Duration(hours: 48);

/// The minimum gap between session 1's completion and session 2's start.
///
/// KC-03 measures this from session 1's `session_complete` to session 2's
/// `session_start`, so two lessons in one sitting are not a return.
const Duration sessionTwoSittingGap = Duration(minutes: 60);

/// D7 is the local calendar day seven days after the install day.
const int daySevenOffset = 7;

/// The return signals the reminder experiment reads from a local log.
///
/// Every field is derived from real events. Nothing is estimated, and a missing
/// signal stays false instead of being filled with a placeholder.
class ReturnMetrics {
  const ReturnMetrics({
    required this.hasFirstSession,
    required this.returnedWithin48h,
    required this.activeOnDay7,
    required this.day7WindowComplete,
    this.installDay,
    this.firstSessionAt,
    this.firstSessionCompleteAt,
    this.secondSessionAt,
  });

  /// Whether a `session_start` event exists at or after the install.
  ///
  /// This is the KC-03 denominator. A first start without a completion is a
  /// dropout: it stays in the denominator and counts as no return.
  final bool hasFirstSession;

  /// Whether a `session_start` met both KC-03 boundaries: within
  /// [sessionTwoReturnWindow] of session 1's start and at least
  /// [sessionTwoSittingGap] after session 1's completion.
  final bool returnedWithin48h;

  /// Whether any `session_complete` or `daily_active` event landed on the local
  /// calendar day seven days after the install day.
  final bool activeOnDay7;

  /// Whether [now] is past the end of the D7 local calendar day.
  ///
  /// When this is false, [activeOnDay7] is not yet final: the day has not
  /// finished, so a false value means "not observed yet", not "did not return".
  final bool day7WindowComplete;

  /// The local `yyyy-MM-dd` install day, or null when the log has no usable
  /// install event.
  final String? installDay;

  /// The timestamp of session 1's `session_start`, or null when it has not
  /// happened.
  final DateTime? firstSessionAt;

  /// The timestamp of session 1's `session_complete`, or null when session 1
  /// never completed.
  ///
  /// A completion belongs to the most recent preceding start. If another
  /// `session_start` happens before session 1 completes, the next completion
  /// belongs to that later sitting and session 1 stays incomplete.
  final DateTime? firstSessionCompleteAt;

  /// The `session_start` that qualified as session 2, or null when no start
  /// met both boundaries. A start inside the sitting gap or outside the window
  /// is not session 2.
  final DateTime? secondSessionAt;

  /// The elapsed time between session 1 and session 2, when both exist.
  Duration? get timeToSecondSession {
    final first = firstSessionAt;
    final second = secondSessionAt;
    if (first == null || second == null) return null;
    return second.difference(first);
  }
}

/// Computes [ReturnMetrics] from a local retention log.
///
/// Rules, in order:
///
/// 1. Events whose `installId` differs from [RetentionLog.installId] are
///    ignored. A synthetic or mixed log cannot move the result.
/// 2. Events timestamped after [now] are ignored, so a forward clock jump
///    cannot manufacture a return. [now] defaults to the current UTC time.
/// 3. The install day comes from [RetentionLog.installAt] when it is pinned and
///    the log is not made only of foreign events. Otherwise it falls back to
///    the first matching `app_open`, then to the first matching event.
/// 4. Session 1 is the first `session_start` at or after the install. Its
///    completion is the first `session_complete` after that start with no
///    intervening `session_start`; a completion after another start belongs to
///    that later sitting, so session 1 stays incomplete. Session 2 is the first
///    `session_start` that is at least [sessionTwoSittingGap] after session 1's
///    completion and at most [sessionTwoReturnWindow] after session 1's start.
///    A session 1 with no completion stays in the denominator but cannot have
///    a session 2.
/// 5. D7 is the whole local calendar day seven days after the install day,
///    from 00:00 through 23:59 local. Any `session_complete` or `daily_active`
///    event on that day counts. The window is inclusive of its end.
///
/// The function is total: an empty, malformed, or out-of-order log returns
/// false signals instead of throwing.
ReturnMetrics returnMetricsFromLog(RetentionLog log, {DateTime? now}) {
  final at = (now ?? DateTime.now()).toUtc();
  final events = <RetentionEvent>[
    for (final event in log.events)
      if (event.installId == log.installId && !event.timestamp.isAfter(at))
        event,
  ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final installAt = _resolveInstallAt(log, events, at);
  final firstSession = _firstSession(events, installAt);
  final firstSessionComplete = firstSession == null
      ? null
      : _firstSessionComplete(events, firstSession);
  final secondSession = firstSession == null || firstSessionComplete == null
      ? null
      : _sessionTwo(events, firstSession, firstSessionComplete);

  final returnedWithin48h = secondSession != null;

  final installDay = installAt == null ? null : localDayKey(installAt);
  final day7 = installDay == null
      ? null
      : shiftLocalDay(installDay, daySevenOffset);
  final activeOnDay7 =
      day7 != null &&
      events.any(
        (event) =>
            (event.name == RetentionEventName.sessionComplete ||
                event.name == RetentionEventName.dailyActive) &&
            localDayKey(event.timestamp) == day7,
      );

  return ReturnMetrics(
    hasFirstSession: firstSession != null,
    returnedWithin48h: returnedWithin48h,
    activeOnDay7: activeOnDay7,
    day7WindowComplete: day7 != null && _isLocalDayOver(day7, at),
    installDay: installDay,
    firstSessionAt: firstSession,
    firstSessionCompleteAt: firstSessionComplete,
    secondSessionAt: secondSession,
  );
}

DateTime? _resolveInstallAt(
  RetentionLog log,
  List<RetentionEvent> events,
  DateTime now,
) {
  // A log whose every event belongs to another install is inconsistent. Its
  // pinned installAt would come from those foreign events, so it is ignored.
  final onlyForeignEvents = log.events.isNotEmpty && events.isEmpty;
  var pinned = onlyForeignEvents ? null : log.installAt?.toUtc();
  if (pinned != null && pinned.isAfter(now)) pinned = null;
  if (pinned != null) return pinned;

  for (final event in events) {
    if (event.name == RetentionEventName.appOpen) return event.timestamp;
  }
  return events.isEmpty ? null : events.first.timestamp;
}

DateTime? _firstSession(List<RetentionEvent> events, DateTime? installAt) {
  for (final event in events) {
    if (event.name != RetentionEventName.sessionStart) continue;
    if (installAt != null && event.timestamp.isBefore(installAt)) continue;
    return event.timestamp;
  }
  return null;
}

DateTime? _firstSessionComplete(
  List<RetentionEvent> events,
  DateTime firstSession,
) {
  for (final event in events) {
    if (event.timestamp.isBefore(firstSession)) continue;
    if (event.name == RetentionEventName.sessionStart &&
        event.timestamp.isAfter(firstSession)) {
      // The completion that follows belongs to this later sitting, not to
      // session 1.
      return null;
    }
    if (event.name == RetentionEventName.sessionComplete) {
      return event.timestamp;
    }
  }
  return null;
}

/// The first `session_start` that satisfies both KC-03 boundaries.
DateTime? _sessionTwo(
  List<RetentionEvent> events,
  DateTime firstSession,
  DateTime firstSessionComplete,
) {
  final earliest = firstSessionComplete.add(sessionTwoSittingGap);
  final latest = firstSession.add(sessionTwoReturnWindow);
  for (final event in events) {
    if (event.name != RetentionEventName.sessionStart) continue;
    if (event.timestamp.isBefore(earliest)) continue;
    if (event.timestamp.isAfter(latest)) return null;
    return event.timestamp;
  }
  return null;
}

/// Whether [now] is at or past the end of the local [dayKey] day.
bool _isLocalDayOver(String dayKey, DateTime now) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return false;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return false;
  final endExclusive = DateTime(year, month, day + 1);
  return !now.toLocal().isBefore(endExclusive);
}
