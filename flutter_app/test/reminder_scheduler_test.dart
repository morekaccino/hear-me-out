import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/notifications/reminder_scheduler.dart';
import 'package:hear_me_out/core/notifications/reminder_scheduler_noop.dart';

import 'support/fakes.dart';

void main() {
  test('the fake receives the exact daily schedule', () async {
    final scheduler = FakeReminderScheduler();

    final result = await requestAndScheduleDaily(
      scheduler,
      hour: 19,
      minute: 30,
      title: 'Time to practice',
      body: 'Today: 5 min of guitar.',
    );

    expect(result.ok, isTrue);
    expect(scheduler.permissionRequests, 1);
    expect(scheduler.schedules, hasLength(1));
    final schedule = scheduler.schedules.single;
    expect(schedule.hour, 19);
    expect(schedule.minute, 30);
    expect(schedule.title, 'Time to practice');
    expect(schedule.body, 'Today: 5 min of guitar.');
  });

  test('cancel calls the scheduler once', () async {
    final scheduler = FakeReminderScheduler();
    final result = await scheduler.cancelDaily();
    expect(result.status, ReminderScheduleStatus.cancelled);
    expect(scheduler.cancelCalls, 1);
  });

  test('a denied permission schedules nothing', () async {
    final scheduler = FakeReminderScheduler(
      permission: ReminderPermissionStatus.denied,
    );

    final result = await requestAndScheduleDaily(
      scheduler,
      hour: 19,
      minute: 0,
      title: 'Time to practice',
      body: 'Today: 5 min of guitar.',
    );

    expect(result.status, ReminderScheduleStatus.permissionDenied);
    expect(scheduler.permissionRequests, 1);
    expect(scheduler.schedules, isEmpty);
  });

  test('a scheduling failure is typed, not thrown', () async {
    final scheduler = FakeReminderScheduler(
      scheduleResult: const ReminderScheduleResult.failed('No alarm service'),
    );

    final result = await requestAndScheduleDaily(
      scheduler,
      hour: 19,
      minute: 0,
      title: 'Time to practice',
      body: 'Today: 5 min of guitar.',
    );

    expect(result.status, ReminderScheduleStatus.failed);
    expect(result.message, 'No alarm service');
    expect(scheduler.schedules, hasLength(1));
  });

  test('the before/after alert carries the piece id', () async {
    final scheduler = FakeReminderScheduler();
    await scheduler.showBeforeAfterReady('twinkle');
    expect(scheduler.beforeAfterPieceIds, <String>['twinkle']);
  });

  test('the no-op scheduler reports web as unavailable', () async {
    const scheduler = NoopReminderScheduler();
    expect(scheduler.isSupported, isFalse);
    expect(
      await scheduler.requestPermission(),
      ReminderPermissionStatus.unsupported,
    );
    final result = await scheduler.scheduleDaily(
      hour: 19,
      minute: 0,
      title: 't',
      body: 'b',
    );
    expect(result.status, ReminderScheduleStatus.unsupported);
    expect(
      (await scheduler.cancelDaily()).status,
      ReminderScheduleStatus.unsupported,
    );
    expect(
      (await scheduler.showBeforeAfterReady('piece')).status,
      ReminderScheduleStatus.unsupported,
    );
    await scheduler.dispose();
  });
}
