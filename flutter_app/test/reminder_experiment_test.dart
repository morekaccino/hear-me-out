import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/notifications/reminder_copy.dart';
import 'package:hear_me_out/core/notifications/reminder_experiment.dart';

void main() {
  final now = DateTime(2026, 11, 7, 12);

  group('assignment', () {
    test('the same install id always gets the same variant', () {
      const ids = [
        '0123456789abcdef0123456789abcdef',
        'deadbeefdeadbeefdeadbeefdeadbeef',
        '00000000000000000000000000000000',
        'ffffffffffffffffffffffffffffffff',
      ];
      for (final id in ids) {
        final first = reminderVariantForInstall(id);
        for (var attempt = 0; attempt < 5; attempt++) {
          expect(reminderVariantForInstall(id), first, reason: id);
        }
      }
    });

    test('case and surrounding whitespace do not move the assignment', () {
      const id = '0123456789abcdef0123456789abcdef';
      final variant = reminderVariantForInstall(id);
      expect(reminderVariantForInstall(id.toUpperCase()), variant);
      expect(reminderVariantForInstall('  $id\n'), variant);
    });

    test('well-formed ids split roughly 50/50 on a fixture set', () {
      // 256 ids built from every leading hex pair. The exact split is fixed by
      // the documented hash, so this range only catches a badly skewed rule.
      final counts = <ReminderCopyVariant, int>{
        ReminderCopyVariant.specificTask: 0,
        ReminderCopyVariant.generic: 0,
      };
      for (final leading in _leadingHexPairs) {
        final variant = reminderVariantForInstall(leading * 16);
        counts[variant] = counts[variant]! + 1;
      }

      expect(counts[ReminderCopyVariant.specificTask], greaterThan(0));
      expect(counts[ReminderCopyVariant.generic], greaterThan(0));
      // 256 * 0.35 = 89.6 and 256 * 0.65 = 166.4. A fair hash stays inside
      // these bounds with room to spare; a broken split does not.
      for (final entry in counts.entries) {
        expect(
          entry.value,
          inInclusiveRange(90, 166),
          reason: '${entry.key} count ${entry.value} is not near half of 256',
        );
      }
    });

    test('empty and malformed ids fall back to the specific-task copy', () {
      const malformed = [
        '',
        '   ',
        'not-an-install-id',
        'abc', // shorter than the assignment width
        'zzzzzzzz', // not hex
        '0123456789abcdef0123456789abcde!',
      ];
      for (final id in malformed) {
        expect(
          reminderVariantForInstall(id),
          ReminderCopyVariant.specificTask,
          reason: id,
        );
      }
    });

    test('the documented rule maps the pinned fixture ids', () {
      expect(
        reminderVariantForInstall('0123456789abcdef0123456789abcdef'),
        ReminderCopyVariant.generic,
      );
      expect(
        reminderVariantForInstall('00000000000000000000000000000000'),
        ReminderCopyVariant.specificTask,
      );
      expect(
        reminderVariantForInstall('deadbeefdeadbeefdeadbeefdeadbeef'),
        ReminderCopyVariant.generic,
      );
    });
  });

  group('bodies', () {
    test('the generic body is exactly the plain copy', () {
      final progress = ProgressState.fresh();
      progress.noteFor(noteCatalog.first).dueAt = now.subtract(
        const Duration(hours: 1),
      );
      expect(
        reminderBodyForVariant(
          progress,
          now,
          variant: ReminderCopyVariant.generic,
          phraseLoopEnabled: true,
          phraseTitle: 'Twinkle, Twinkle',
          phraseBars: 4,
        ),
        'Time to practice!',
      );
      expect(
        reminderBodyForVariant(
          ProgressState.fresh(),
          now,
          variant: ReminderCopyVariant.generic,
        ),
        genericReminderBody,
      );
      expect(genericReminderBody, 'Time to practice!');
    });

    test('the specific body names a real phrase and bar count', () {
      final progress = ProgressState.fresh();
      expect(
        reminderBodyForVariant(
          progress,
          now,
          variant: ReminderCopyVariant.specificTask,
          phraseLoopEnabled: true,
          phraseTitle: 'Twinkle, Twinkle',
          phraseBars: 4,
        ),
        'Today: 5 min — Twinkle, Twinkle, 4 bars.',
      );
      expect(
        reminderBodyForVariant(
          progress,
          now,
          variant: ReminderCopyVariant.specificTask,
          phraseLoopEnabled: true,
          phraseTitle: 'Twinkle, Twinkle',
          phraseBars: 1,
        ),
        'Today: 5 min — Twinkle, Twinkle, 1 bar.',
      );
    });

    test('the specific body names the real due-note count', () {
      final progress = ProgressState.fresh();
      progress.noteFor(noteCatalog.first).dueAt = now.subtract(
        const Duration(hours: 1),
      );
      progress.noteFor(noteCatalog[1]).dueAt = now.subtract(
        const Duration(hours: 2),
      );
      expect(
        reminderBodyForVariant(
          progress,
          now,
          variant: ReminderCopyVariant.specificTask,
        ),
        'Today: 5 min — 2 notes are due.',
      );
    });

    test('the specific body falls back to the real weekly goal', () {
      final progress = ProgressState.fresh();
      expect(
        reminderBodyForVariant(progress, now),
        'Today: 5 min to reach your weekly goal.',
      );
      progress.recordPracticeSeconds(
        progress.settings.weeklyGoalMinutes * 60,
        now,
      );
      expect(reminderBodyForVariant(progress, now), 'Today: 5 min of guitar.');
    });

    test('the default variant keeps the existing copy', () {
      final progress = ProgressState.fresh();
      progress.noteFor(noteCatalog.first).dueAt = now.subtract(
        const Duration(hours: 1),
      );
      expect(
        reminderBodyForVariant(progress, now),
        reminderTaskBody(progress, now),
      );
    });
  });

  test('quiet hours are unchanged by the experiment', () {
    for (var hour = 0; hour < 24; hour++) {
      final allowed = isAllowedReminderTime(hour, 0);
      expect(allowed, hour >= 8 && hour < 21, reason: 'hour $hour');
    }
    expect(isAllowedReminderTime(8, 0), isTrue);
    expect(isAllowedReminderTime(20, 59), isTrue);
    expect(isAllowedReminderTime(21, 0), isFalse);
    expect(isAllowedReminderTime(7, 59), isFalse);
    expect(isAllowedReminderTime(24, 0), isFalse);
    expect(isAllowedReminderTime(12, 60), isFalse);
  });

  test('neither variant uses guilt, streak loss, or a fake deadline', () {
    final dueProgress = ProgressState.fresh();
    dueProgress.noteFor(noteCatalog.first).dueAt = now.subtract(
      const Duration(hours: 1),
    );
    final metGoalProgress = ProgressState.fresh()
      ..recordPracticeSeconds(
        ProgressState.fresh().settings.weeklyGoalMinutes * 60,
        now,
      );
    final bodies = <String>[
      for (final variant in ReminderCopyVariant.values) ...[
        reminderBodyForVariant(dueProgress, now, variant: variant),
        reminderBodyForVariant(ProgressState.fresh(), now, variant: variant),
        reminderBodyForVariant(metGoalProgress, now, variant: variant),
        reminderBodyForVariant(
          dueProgress,
          now,
          variant: variant,
          phraseLoopEnabled: true,
          phraseTitle: 'Twinkle, Twinkle',
          phraseBars: 4,
        ),
      ],
    ];

    const banned = [
      'streak',
      'lost',
      'lose',
      "don't",
      'missed',
      'guilt',
      'last chance',
      'hurry',
      'deadline',
      'expire',
      'now or never',
      'disappoint',
    ];
    for (final body in bodies) {
      final lower = body.toLowerCase();
      for (final phrase in banned) {
        expect(lower, isNot(contains(phrase)), reason: body);
      }
    }
  });

  test('the shared notification title does not change', () {
    expect(reminderNotificationTitle, 'Time to practice');
  });
}

/// Every two-character hex prefix, used to build 256 distinct fixture ids.
final List<String> _leadingHexPairs = [
  for (final first in _hexDigits)
    for (final second in _hexDigits) '$first$second',
];

const List<String> _hexDigits = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
];
