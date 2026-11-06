import 'dart:convert';

import 'retention_event.dart';

/// The maximum number of events kept on the device.
///
/// The lapsed time plus this bound is the retention window: old events fall off
/// in insertion order, so the log cannot grow without limit.
const int retentionEventLimit = 500;

/// The ordered funnel steps reported by [RetentionLog.funnel].
const List<RetentionEventName> retentionFunnelSteps = [
  RetentionEventName.appOpen,
  RetentionEventName.onboardingStart,
  RetentionEventName.onboardingComplete,
  RetentionEventName.firstNote,
  RetentionEventName.firstPhrase,
  RetentionEventName.firstRecording,
];

/// An immutable, bounded local event log for one pseudonymous install.
///
/// This is pure Dart. It has no Flutter, storage, I/O, or network dependency.
class RetentionLog {
  RetentionLog({
    required this.installId,
    Iterable<RetentionEvent> events = const [],
    this.maxEvents = retentionEventLimit,
  }) : _events = List<RetentionEvent>.unmodifiable(
         events.length > maxEvents
             ? events.skip(events.length - maxEvents)
             : events,
       );

  final String installId;
  final int maxEvents;
  final List<RetentionEvent> _events;

  /// Events in insertion order, oldest first.
  List<RetentionEvent> get events => _events;

  int get length => _events.length;

  bool get isEmpty => _events.isEmpty;

  /// Appends [name] at [at] and drops the oldest events over [maxEvents].
  RetentionLog record(RetentionEventName name, {required DateTime at}) {
    final next = [
      ..._events,
      RetentionEvent(name: name, timestamp: at, installId: installId),
    ];
    final overflow = next.length - maxEvents;
    if (overflow > 0) next.removeRange(0, overflow);
    return RetentionLog(
      installId: installId,
      events: next,
      maxEvents: maxEvents,
    );
  }

  /// Removes every event but keeps the install id and the bound.
  RetentionLog clear() =>
      RetentionLog(installId: installId, maxEvents: maxEvents);

  RetentionEvent? firstEvent(RetentionEventName name) {
    for (final event in _events) {
      if (event.name == name) return event;
    }
    return null;
  }

  bool hasEvent(RetentionEventName name) => firstEvent(name) != null;

  bool hasEventOnLocalDay(RetentionEventName name, DateTime day) {
    final key = localDayKey(day);
    return _events.any(
      (event) => event.name == name && localDayKey(event.timestamp) == key,
    );
  }

  /// The first timestamp of each funnel step, or null when it never happened.
  Map<RetentionEventName, DateTime?> funnel() => {
    for (final step in retentionFunnelSteps) step: firstEvent(step)?.timestamp,
  };

  /// Local `yyyy-MM-dd` keys with at least one event.
  Set<String> get activeDays => {
    for (final event in _events) localDayKey(event.timestamp),
  };

  /// The local day of the first app open, or of the first event if the install
  /// event is missing. Null when the log is empty.
  String? get installDay {
    final firstOpen = firstEvent(RetentionEventName.appOpen);
    if (firstOpen != null) return localDayKey(firstOpen.timestamp);
    if (_events.isEmpty) return null;
    return localDayKey(_events.first.timestamp);
  }

  /// Whether the user was active on [dayOffset] local days after install.
  ///
  /// D1 is the day after install, D7 is seven days after, and D30 is thirty.
  bool retainedOnDay(int dayOffset) {
    final start = installDay;
    if (start == null || dayOffset < 0) return false;
    return activeDays.contains(shiftLocalDay(start, dayOffset));
  }

  bool get d1Retained => retainedOnDay(1);

  bool get d7Retained => retainedOnDay(7);

  bool get d30Retained => retainedOnDay(30);

  /// A JSON document suitable for the user-initiated copy action.
  ///
  /// Every event carries only its name, UTC timestamp, and install id. The
  /// app never uploads this document; the user controls what happens to it.
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'installId': installId,
    'events': [for (final event in _events) event.toJson()],
  });
}

/// Formats a timestamp as a local calendar day key.
String localDayKey(DateTime timestamp) {
  final local = timestamp.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Adds whole calendar days to a `yyyy-MM-dd` key without DST drift.
String shiftLocalDay(String dayKey, int dayOffset) {
  final parts = dayKey.split('-');
  final date = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  ).add(Duration(days: dayOffset));
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
