import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/notifications/reminder_experiment.dart';
import 'package:hear_me_out/core/notifications/reminder_scheduler.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/home_shell.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp({
    required MemoryProgressStore progressStore,
    required FakeReminderScheduler scheduler,
    MemoryRetentionStore? retentionStore,
  }) {
    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        retentionStoreProvider.overrideWithValue(
          retentionStore ?? MemoryRetentionStore(optIn: true),
        ),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        mediaBackupStatusProvider.overrideWithValue(
          const AsyncData(BackupExclusionResult.notRequired('widget test')),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeShell()),
    );
  }

  MemoryProgressStore profileStore({bool reminderEnabled = false}) =>
      MemoryProgressStore(
        ProgressState.fresh(
          settings: AppSettings(
            onboardingComplete: true,
            reminderEnabled: reminderEnabled,
            reminderHour: 19,
            reminderMinute: 0,
          ),
        ),
      );

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Practice reminder'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('turning reminders on persists, schedules, and logs once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = profileStore();
    final retention = MemoryRetentionStore(optIn: true);
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(
      buildApp(
        progressStore: store,
        scheduler: scheduler,
        retentionStore: retention,
      ),
    );
    await tester.pumpAndSettle();
    await openProfile(tester);

    final switchFinder = find.byKey(const ValueKey('reminder-enabled-switch'));
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(find.text('Reminder time'), findsNothing);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(store.value!.settings.reminderEnabled, isTrue);
    expect(scheduler.permissionRequests, 1);
    expect(scheduler.schedules, hasLength(1));
    expect(scheduler.schedules.single.hour, 19);
    expect(scheduler.schedules.single.minute, 0);
    expect(scheduler.schedules.single.body, contains('Today: 5 min'));
    expect(find.text('7:00 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    int optIns() => retention.value.log.events
        .where((event) => event.name == RetentionEventName.reminderOptIn)
        .length;
    expect(optIns(), 1);

    // Toggling off and on again does not write the event twice.
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(store.value!.settings.reminderEnabled, isFalse);
    expect(scheduler.cancelCalls, 1);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(optIns(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied permission keeps the switch off and schedules nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = profileStore();
    final scheduler = FakeReminderScheduler(
      permission: ReminderPermissionStatus.denied,
    );
    await tester.pumpWidget(
      buildApp(progressStore: store, scheduler: scheduler),
    );
    await tester.pumpAndSettle();
    await openProfile(tester);

    final switchFinder = find.byKey(const ValueKey('reminder-enabled-switch'));
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(store.value!.settings.reminderEnabled, isFalse);
    expect(scheduler.schedules, isEmpty);
    expect(find.textContaining('Notifications are turned off'), findsOneWidget);
  });

  testWidgets('a quiet-hour time is rejected and the stored time is kept', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = profileStore(reminderEnabled: true);
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(
      buildApp(progressStore: store, scheduler: scheduler),
    );
    await tester.pumpAndSettle();
    await openProfile(tester);

    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);

    // Switch to keyboard entry and choose 21:00, inside quiet hours.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '09');
    await tester.enterText(fields.at(1), '00');
    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('between 8:00 AM and 9:00 PM'), findsOneWidget);
    expect(store.value!.settings.reminderHour, 19);
    expect(store.value!.settings.reminderMinute, 0);
    expect(scheduler.schedules, isEmpty);
  });

  testWidgets('the reminder rows fit 1200 px without overflow', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        progressStore: profileStore(reminderEnabled: true),
        scheduler: FakeReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Practice reminder'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice reminder'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an opted-in generic install schedules the generic body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pinned fixture: this id hashes to the generic arm.
    const installId = '0123456789abcdef0123456789abcdef';
    expect(reminderVariantForInstall(installId), ReminderCopyVariant.generic);

    final store = profileStore();
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(
      buildApp(
        progressStore: store,
        scheduler: scheduler,
        retentionStore: MemoryRetentionStore(optIn: true, installId: installId),
      ),
    );
    await tester.pumpAndSettle();
    await openProfile(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-enabled-switch')));
    await tester.pumpAndSettle();

    expect(scheduler.schedules, hasLength(1));
    expect(scheduler.schedules.single.title, 'Time to practice');
    expect(scheduler.schedules.single.body, 'Time to practice!');

    // Changing the time re-schedules with the same assigned variant. The
    // assignment is a function of the install id, not the clock.
    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '08');
    await tester.enterText(fields.at(1), '00');
    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(scheduler.schedules, hasLength(2));
    expect(scheduler.schedules.last.hour, 8);
    expect(scheduler.schedules.last.minute, 0);
    expect(scheduler.schedules.last.body, 'Time to practice!');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a non-opted-in install keeps the specific body', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The same id would be generic for an opted-in install. Without consent
    // the reminder keeps the current specific-task copy.
    const installId = '0123456789abcdef0123456789abcdef';
    expect(reminderVariantForInstall(installId), ReminderCopyVariant.generic);

    final store = profileStore();
    final scheduler = FakeReminderScheduler();
    await tester.pumpWidget(
      buildApp(
        progressStore: store,
        scheduler: scheduler,
        retentionStore: MemoryRetentionStore(
          optIn: false,
          installId: installId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openProfile(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-enabled-switch')));
    await tester.pumpAndSettle();

    expect(scheduler.schedules, hasLength(1));
    expect(
      scheduler.schedules.single.body,
      'Today: 5 min to reach your weekly goal.',
    );
    expect(tester.takeException(), isNull);
  });
}
