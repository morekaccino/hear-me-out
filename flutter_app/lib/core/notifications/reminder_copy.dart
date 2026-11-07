import '../learning/progress.dart';

/// Fixed quiet hours, local time: 21:00 through 07:59.
///
/// Only 08:00–20:59 may be chosen. This is one rule, not a second setting.
const int quietHoursStartHour = 21;
const int quietHoursEndHour = 8;

/// The notification title. The body carries the specific task.
const String reminderNotificationTitle = 'Time to practice';

/// True when [hour] is inside the fixed quiet hours.
bool isQuietHour(int hour) =>
    hour < quietHoursEndHour || hour >= quietHoursStartHour;

/// True when the local clock time is valid and outside quiet hours.
bool isAllowedReminderTime(int hour, int minute) {
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;
  return !isQuietHour(hour);
}

/// Formats a local clock time for the settings row, for example `7:00 PM`.
String formatReminderTime(int hour, int minute) {
  final safeHour = hour.clamp(0, 23);
  final safeMinute = minute.clamp(0, 59);
  final suffix = safeHour >= 12 ? 'PM' : 'AM';
  final displayHour = safeHour % 12 == 0 ? 12 : safeHour % 12;
  return '$displayHour:${safeMinute.toString().padLeft(2, '0')} $suffix';
}

/// The specific, honest task the reminder names.
///
/// The copy comes from real progress only. It never mentions a streak, a lost
/// day, or guilt. When the phrase loop is enabled and a Today phrase target
/// resolves, the caller may pass its title and bar count so the reminder names
/// the real musical task.
String reminderTaskBody(
  ProgressState progress,
  DateTime now, {
  bool phraseLoopEnabled = false,
  String? phraseTitle,
  int? phraseBars,
}) {
  final title = phraseTitle?.trim();
  final bars = phraseBars;
  if (phraseLoopEnabled &&
      title != null &&
      title.isNotEmpty &&
      bars != null &&
      bars > 0) {
    final barCopy = bars == 1 ? '1 bar' : '$bars bars';
    return 'Today: 5 min — $title, $barCopy.';
  }

  final due = progress.dueNotes(now).length;
  if (due > 0) {
    final noteCopy = due == 1 ? '1 note is due' : '$due notes are due';
    return 'Today: 5 min — $noteCopy.';
  }

  if (progress.weeklyPracticeGoalRemaining(now) > 0) {
    return 'Today: 5 min to reach your weekly goal.';
  }

  return 'Today: 5 min of guitar.';
}
