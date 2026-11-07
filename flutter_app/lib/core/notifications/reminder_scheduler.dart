/// Permission answer from the platform notification service.
enum ReminderPermissionStatus { granted, denied, unsupported }

/// Typed outcome for scheduling or cancelling a local reminder.
///
/// Expected plugin, platform, and permission failures are returned here
/// instead of thrown, so the settings UI can show a calm message.
enum ReminderScheduleStatus {
  scheduled,
  cancelled,
  unsupported,
  permissionDenied,
  failed,
}

class ReminderScheduleResult {
  const ReminderScheduleResult._(this.status, [this.message]);

  const ReminderScheduleResult.scheduled()
    : this._(ReminderScheduleStatus.scheduled);

  const ReminderScheduleResult.cancelled()
    : this._(ReminderScheduleStatus.cancelled);

  const ReminderScheduleResult.unsupported([String? message])
    : this._(ReminderScheduleStatus.unsupported, message);

  const ReminderScheduleResult.permissionDenied([String? message])
    : this._(ReminderScheduleStatus.permissionDenied, message);

  const ReminderScheduleResult.failed([String? message])
    : this._(ReminderScheduleStatus.failed, message);

  final ReminderScheduleStatus status;

  /// Optional human-readable diagnostic. Never shown as raw plugin text.
  final String? message;

  bool get ok =>
      status == ReminderScheduleStatus.scheduled ||
      status == ReminderScheduleStatus.cancelled;
}

/// The platform seam for opt-in, local-only practice reminders.
///
/// Implementations must never add a network call, an account, or a push
/// service. Web gets a no-op implementation so the platform plugin is not
/// imported there.
/// Requests permission, then schedules only when it is granted.
///
/// A denied or unsupported permission returns a typed result and never calls
/// [ReminderScheduler.scheduleDaily]. Tests use this to prove the denial path
/// schedules nothing.
Future<ReminderScheduleResult> requestAndScheduleDaily(
  ReminderScheduler scheduler, {
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {
  final permission = await scheduler.requestPermission();
  if (permission != ReminderPermissionStatus.granted) {
    return permission == ReminderPermissionStatus.denied
        ? const ReminderScheduleResult.permissionDenied(
            'Notifications are turned off for this app.',
          )
        : const ReminderScheduleResult.unsupported(
            'Reminders are available on mobile.',
          );
  }
  return scheduler.scheduleDaily(
    hour: hour,
    minute: minute,
    title: title,
    body: body,
  );
}

abstract interface class ReminderScheduler {
  /// False on web and on platforms without a local notification service.
  bool get isSupported;

  Future<ReminderPermissionStatus> requestPermission();

  Future<ReminderScheduleResult> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  Future<ReminderScheduleResult> cancelDaily();

  Future<ReminderScheduleResult> showBeforeAfterReady(String pieceId);

  Future<void> dispose();
}
