/// The production reminder scheduler.
///
/// The web build resolves to a no-op implementation so the platform plugin is
/// never imported there. IO platforms resolve to the local notification
/// implementation.
library;

export 'reminder_scheduler_noop.dart'
    if (dart.library.io) 'reminder_scheduler_io.dart';
