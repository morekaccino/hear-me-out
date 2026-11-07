import 'reminder_scheduler.dart';

/// Creates the scheduler for platforms without local notifications.
///
/// The web build resolves to this file through the conditional export, so the
/// platform notification plugin is never imported there.
ReminderScheduler createReminderScheduler() => const NoopReminderScheduler();

/// A scheduler that never schedules anything.
///
/// This is a real answer, not a pretend success: the settings UI shows
/// "Reminders are available on mobile." and keeps the switch off.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<ReminderPermissionStatus> requestPermission() async =>
      ReminderPermissionStatus.unsupported;

  @override
  Future<ReminderScheduleResult> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async => const ReminderScheduleResult.unsupported(
    'Local reminders are available on mobile.',
  );

  @override
  Future<ReminderScheduleResult> cancelDaily() async =>
      const ReminderScheduleResult.unsupported();

  @override
  Future<ReminderScheduleResult> showBeforeAfterReady(String pieceId) async =>
      const ReminderScheduleResult.unsupported();

  @override
  Future<void> dispose() async {}
}
