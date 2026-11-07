import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/notifications/reminder_copy.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);

  test('a due note is named by count', () {
    final progress = ProgressState.fresh();
    final note = noteCatalog.first;
    progress.noteFor(note).dueAt = now.subtract(const Duration(hours: 1));

    expect(reminderTaskBody(progress, now), 'Today: 5 min — 1 note is due.');

    progress.noteFor(noteCatalog[1]).dueAt = now.subtract(
      const Duration(hours: 2),
    );
    expect(reminderTaskBody(progress, now), 'Today: 5 min — 2 notes are due.');
  });

  test('an unmet weekly goal is named when nothing is due', () {
    final progress = ProgressState.fresh();
    expect(
      reminderTaskBody(progress, now),
      'Today: 5 min to reach your weekly goal.',
    );
  });

  test('a met weekly goal falls back to plain guitar time', () {
    final progress = ProgressState.fresh();
    progress.recordPracticeSeconds(
      progress.settings.weeklyGoalMinutes * 60,
      now,
    );
    expect(reminderTaskBody(progress, now), 'Today: 5 min of guitar.');
  });

  test('the phrase loop may name the real phrase and bars', () {
    final progress = ProgressState.fresh();
    expect(
      reminderTaskBody(
        progress,
        now,
        phraseLoopEnabled: true,
        phraseTitle: 'Twinkle, Twinkle',
        phraseBars: 4,
      ),
      'Today: 5 min — Twinkle, Twinkle, 4 bars.',
    );
    expect(
      reminderTaskBody(
        progress,
        now,
        phraseLoopEnabled: false,
        phraseTitle: 'Twinkle, Twinkle',
        phraseBars: 4,
      ),
      'Today: 5 min to reach your weekly goal.',
    );
  });

  test('copy never uses guilt or streak language', () {
    final progress = ProgressState.fresh();
    progress.noteFor(noteCatalog.first).dueAt = now.subtract(
      const Duration(minutes: 1),
    );
    final copies = <String>[
      reminderTaskBody(progress, now),
      reminderTaskBody(ProgressState.fresh(), now),
      reminderTaskBody(
        ProgressState.fresh()..recordPracticeSeconds(
          ProgressState.fresh().settings.weeklyGoalMinutes * 60,
          now,
        ),
        now,
      ),
      reminderTaskBody(
        progress,
        now,
        phraseLoopEnabled: true,
        phraseTitle: 'Twinkle',
        phraseBars: 2,
      ),
    ];
    for (final copy in copies) {
      final lower = copy.toLowerCase();
      expect(lower, isNot(contains('streak')));
      expect(lower, isNot(contains('lost')));
      expect(lower, isNot(contains("don't break")));
      expect(lower, isNot(contains('guilt')));
    }
  });

  test('quiet hours are 21:00 through 07:59', () {
    expect(isQuietHour(7), isTrue);
    expect(isQuietHour(8), isFalse);
    expect(isQuietHour(20), isFalse);
    expect(isQuietHour(21), isTrue);
    expect(isQuietHour(23), isTrue);
    expect(isQuietHour(0), isTrue);

    expect(isAllowedReminderTime(8, 0), isTrue);
    expect(isAllowedReminderTime(20, 59), isTrue);
    expect(isAllowedReminderTime(21, 0), isFalse);
    expect(isAllowedReminderTime(7, 59), isFalse);
    expect(isAllowedReminderTime(-1, 0), isFalse);
    expect(isAllowedReminderTime(24, 0), isFalse);
    expect(isAllowedReminderTime(8, 60), isFalse);
  });

  test('time formatting is local-friendly 12-hour copy', () {
    expect(formatReminderTime(0, 0), '12:00 AM');
    expect(formatReminderTime(7, 5), '7:05 AM');
    expect(formatReminderTime(12, 0), '12:00 PM');
    expect(formatReminderTime(19, 0), '7:00 PM');
    expect(formatReminderTime(20, 59), '8:59 PM');
    expect(formatReminderTime(23, 59), '11:59 PM');
  });
}
