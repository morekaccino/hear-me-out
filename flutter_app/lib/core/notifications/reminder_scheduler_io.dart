import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_copy.dart';
import 'reminder_scheduler.dart';

/// Stable notification ids. One daily reminder and one before/after alert.
const int dailyReminderNotificationId = 2901;
const int beforeAfterNotificationId = 2902;

const String _channelId = 'practice_reminders';
const String _channelName = 'Practice reminders';
const String _channelDescription =
    'Local practice reminders chosen in Profile. Never sent over a network.';

ReminderScheduler createReminderScheduler() => LocalReminderScheduler();

/// Local notification scheduler for mobile and desktop IO builds.
///
/// The plugin is initialized lazily on the first real request. Every expected
/// platform failure becomes a typed [ReminderScheduleResult]; nothing is thrown
/// into the widget tree. Scheduling uses an inexact daily alarm, so the app
/// never asks for exact-alarm permission.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static bool get _platformSupported => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    _ => false,
  };

  @override
  bool get isSupported => _platformSupported;

  @override
  Future<ReminderPermissionStatus> requestPermission() async {
    if (!isSupported) return ReminderPermissionStatus.unsupported;
    try {
      await _ensureInitialized();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return granted == false
            ? ReminderPermissionStatus.denied
            : ReminderPermissionStatus.granted;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true);
        return granted == false
            ? ReminderPermissionStatus.denied
            : ReminderPermissionStatus.granted;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true);
        return granted == false
            ? ReminderPermissionStatus.denied
            : ReminderPermissionStatus.granted;
      }
      return ReminderPermissionStatus.unsupported;
    } catch (_) {
      return ReminderPermissionStatus.denied;
    }
  }

  @override
  Future<ReminderScheduleResult> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!isSupported) {
      return const ReminderScheduleResult.unsupported(
        'Local reminders are available on mobile.',
      );
    }
    if (!isAllowedReminderTime(hour, minute)) {
      return const ReminderScheduleResult.failed(
        'Choose a time between 8:00 AM and 9:00 PM.',
      );
    }
    try {
      await _ensureInitialized();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return const ReminderScheduleResult.scheduled();
    } catch (_) {
      return const ReminderScheduleResult.failed(
        'Could not schedule the reminder on this device.',
      );
    }
  }

  @override
  Future<ReminderScheduleResult> cancelDaily() async {
    if (!isSupported) {
      return const ReminderScheduleResult.unsupported(
        'Local reminders are available on mobile.',
      );
    }
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: dailyReminderNotificationId);
      return const ReminderScheduleResult.cancelled();
    } catch (_) {
      return const ReminderScheduleResult.failed(
        'Could not cancel the reminder on this device.',
      );
    }
  }

  @override
  Future<ReminderScheduleResult> showBeforeAfterReady(String pieceId) async {
    if (!isSupported) {
      return const ReminderScheduleResult.unsupported(
        'Local reminders are available on mobile.',
      );
    }
    try {
      await _ensureInitialized();
      await _plugin.show(
        id: beforeAfterNotificationId,
        title: 'Your before/after is ready',
        body: 'Two takes are saved. Listen to the difference.',
        notificationDetails: _details(),
        payload: pieceId,
      );
      return const ReminderScheduleResult.scheduled();
    } catch (_) {
      return const ReminderScheduleResult.failed(
        'Could not show the before/after reminder on this device.',
      );
    }
  }

  @override
  Future<void> dispose() async {}

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Do not fall back to the timezone package's default (UTC): scheduling a
    // "19:00" reminder at 19:00 UTC is worse than reporting a failure. The
    // caller turns this into a typed failure and keeps the switch off.
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw StateError('Local notifications did not initialize.');
    }
    _initialized = true;
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );
}
