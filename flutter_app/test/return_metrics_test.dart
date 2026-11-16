import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';
import 'package:hear_me_out/core/retention/return_metrics.dart';

void main() {
  final install = DateTime(2026, 3, 1, 9);

  RetentionEvent event(
    RetentionEventName name,
    DateTime at, {
    String installId = 'install-a',
  }) => RetentionEvent(name: name, timestamp: at, installId: installId);

  RetentionLog logWith(
    Iterable<RetentionEvent> events, {
    DateTime? installAt,
    String installId = 'install-a',
  }) =>
      RetentionLog(installId: installId, events: events, installAt: installAt);

  test('an empty log has no signals', () {
    final metrics = returnMetricsFromLog(
      RetentionLog(installId: 'install-a'),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.activeOnDay7, isFalse);
    expect(metrics.day7WindowComplete, isFalse);
    expect(metrics.installDay, isNull);
    expect(metrics.firstSessionAt, isNull);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.timeToSecondSession, isNull);
  });

  test('one session has a first session but no return', () {
    final start = install.add(const Duration(hours: 1));
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionStart, start),
        event(
          RetentionEventName.sessionComplete,
          start.add(const Duration(minutes: 30)),
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.firstSessionAt, start.toUtc());
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.installDay, '2026-03-01');
  });

  test('a return at 47 hours counts and one at 49 hours does not', () {
    final first = install.add(const Duration(hours: 1));
    final firstComplete = first.add(const Duration(minutes: 30));

    ReturnMetrics at(Duration gap) => returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionStart, first),
        event(RetentionEventName.sessionComplete, firstComplete),
        event(RetentionEventName.sessionStart, first.add(gap)),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(at(const Duration(hours: 47)).returnedWithin48h, isTrue);
    expect(at(const Duration(hours: 48)).returnedWithin48h, isTrue);
    expect(at(const Duration(hours: 49)).returnedWithin48h, isFalse);
    expect(at(const Duration(hours: 49)).secondSessionAt, isNull);
    expect(at(const Duration(hours: 49)).timeToSecondSession, isNull);
    expect(
      at(const Duration(hours: 47)).secondSessionAt,
      first.add(const Duration(hours: 47)).toUtc(),
    );
    expect(
      at(const Duration(hours: 47)).timeToSecondSession,
      const Duration(hours: 47),
    );
  });

  test('two lessons in one sitting are not a session-2 return', () {
    final first = DateTime(2026, 3, 1, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionStart, first),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(minutes: 30)),
        ),
        event(
          RetentionEventName.sessionStart,
          first.add(const Duration(minutes: 50)),
        ),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(hours: 1, minutes: 30)),
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.secondSessionAt, isNull);
  });

  test('a second sitting 60 minutes after session 1 counts', () {
    final first = DateTime(2026, 3, 1, 10);
    final firstComplete = first.add(const Duration(minutes: 30));

    ReturnMetrics sittingAfter(Duration gap) => returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, first),
        event(RetentionEventName.sessionComplete, firstComplete),
        event(RetentionEventName.sessionStart, firstComplete.add(gap)),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(
      sittingAfter(const Duration(minutes: 59)).returnedWithin48h,
      isFalse,
      reason: 'the sitting boundary is measured from the completion',
    );
    expect(sittingAfter(const Duration(minutes: 60)).returnedWithin48h, isTrue);
    expect(
      sittingAfter(const Duration(minutes: 60)).secondSessionAt,
      firstComplete.add(const Duration(minutes: 60)).toUtc(),
    );
  });

  test('the 48-hour window is anchored to session 1 start, not completion', () {
    final first = DateTime(2026, 3, 1, 10);
    final firstComplete = first.add(const Duration(hours: 2));
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, first),
        event(RetentionEventName.sessionComplete, firstComplete),
        event(
          RetentionEventName.sessionStart,
          first.add(const Duration(hours: 49)),
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(
      metrics.returnedWithin48h,
      isFalse,
      reason:
          'session 2 is 49 hours after session 1 start even though it is 47 '
          'hours after its completion',
    );
    expect(metrics.secondSessionAt, isNull);
  });

  test('an incomplete first session stays in the denominator', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(
          RetentionEventName.sessionStart,
          install.add(const Duration(hours: 1)),
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.secondSessionAt, isNull);
  });

  test('duplicate starts at the same instant are not a return', () {
    final same = DateTime(2026, 3, 2, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, same),
        event(RetentionEventName.sessionComplete, same),
        event(RetentionEventName.sessionStart, same),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.returnedWithin48h, isFalse);
  });

  group('D7', () {
    final daySeven = DateTime(2026, 3, 8);

    ReturnMetrics daySevenMetrics(Iterable<RetentionEvent> events) =>
        returnMetricsFromLog(
          logWith([
            event(RetentionEventName.appOpen, install),
            ...events,
          ], installAt: install),
          now: DateTime(2026, 3, 10, 12),
        );

    test('a session on install day + 7 is active', () {
      expect(
        daySevenMetrics([
          event(RetentionEventName.sessionComplete, DateTime(2026, 3, 8, 12)),
        ]).activeOnDay7,
        isTrue,
      );
    });

    test('a daily-active event on install day + 7 is active', () {
      expect(
        daySevenMetrics([
          event(RetentionEventName.dailyActive, DateTime(2026, 3, 8, 0, 5)),
        ]).activeOnDay7,
        isTrue,
      );
    });

    test('the last minute of the D7 local day is included', () {
      expect(
        daySevenMetrics([
          event(
            RetentionEventName.dailyActive,
            DateTime(daySeven.year, daySeven.month, daySeven.day, 23, 59, 59),
          ),
        ]).activeOnDay7,
        isTrue,
      );
    });

    test('day 6, day 8, and a mere app open do not count', () {
      expect(
        daySevenMetrics([
          event(RetentionEventName.dailyActive, DateTime(2026, 3, 7, 23, 59)),
        ]).activeOnDay7,
        isFalse,
      );
      expect(
        daySevenMetrics([
          event(RetentionEventName.dailyActive, DateTime(2026, 3, 9, 0, 1)),
        ]).activeOnDay7,
        isFalse,
      );
      expect(
        daySevenMetrics([
          event(RetentionEventName.appOpen, DateTime(2026, 3, 8, 12)),
        ]).activeOnDay7,
        isFalse,
      );
    });

    test('the window is not complete until the D7 local day ends', () {
      final log = logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.dailyActive, DateTime(2026, 3, 8, 10)),
      ], installAt: install);

      final during = returnMetricsFromLog(
        log,
        now: DateTime(2026, 3, 8, 23, 59),
      );
      expect(during.activeOnDay7, isTrue);
      expect(during.day7WindowComplete, isFalse);

      final after = returnMetricsFromLog(log, now: DateTime(2026, 3, 9));
      expect(after.day7WindowComplete, isTrue);
    });
  });

  test('future timestamps are ignored and never throw', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 2, 10)),
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 2, 10, 30)),
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 10, 10)),
      ], installAt: install),
      now: DateTime(2026, 3, 5, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.day7WindowComplete, isFalse);
  });

  test('a future install date does not create a session or a D7 day', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, DateTime(2026, 3, 20, 9)),
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 20, 10)),
        event(
          RetentionEventName.sessionComplete,
          DateTime(2026, 3, 20, 10, 30),
        ),
      ], installAt: DateTime(2026, 3, 20, 9)),
      now: DateTime(2026, 3, 5, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
    expect(metrics.installDay, isNull);
    expect(metrics.activeOnDay7, isFalse);
    expect(metrics.day7WindowComplete, isFalse);
  });

  test('events with another install id are ignored', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install, installId: 'install-b'),
        event(
          RetentionEventName.sessionStart,
          DateTime(2026, 3, 2, 10),
          installId: 'install-b',
        ),
        event(
          RetentionEventName.sessionComplete,
          DateTime(2026, 3, 2, 10, 30),
          installId: 'install-b',
        ),
        event(
          RetentionEventName.dailyActive,
          DateTime(2026, 3, 8, 10),
          installId: 'install-b',
        ),
      ]),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
    expect(metrics.installDay, isNull);
    expect(metrics.activeOnDay7, isFalse);
  });

  test('a foreign event cannot become session 2 in a mixed log', () {
    final first = DateTime(2026, 3, 2, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionStart, first),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(minutes: 30)),
        ),
        event(
          RetentionEventName.sessionStart,
          first.add(const Duration(hours: 2)),
          installId: 'install-b',
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.returnedWithin48h, isFalse);
  });

  test('out-of-order insertion is sorted before sessions are chosen', () {
    final first = DateTime(2026, 3, 2, 10);
    final second = first.add(const Duration(hours: 20));
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, second),
        event(RetentionEventName.sessionStart, first),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(minutes: 30)),
        ),
        event(RetentionEventName.appOpen, install),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.firstSessionAt, first.toUtc());
    expect(metrics.secondSessionAt, second.toUtc());
    expect(metrics.returnedWithin48h, isTrue);
  });

  test('a session before the pinned install is not session 1', () {
    final installAt = DateTime(2026, 3, 2, 9);
    final first = DateTime(2026, 3, 3, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 1, 10)),
        event(RetentionEventName.sessionStart, first),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(minutes: 30)),
        ),
      ], installAt: installAt),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.firstSessionAt, first.toUtc());
    expect(metrics.returnedWithin48h, isFalse);
  });

  test('only a session before the install leaves no first session', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 1, 10)),
      ], installAt: DateTime(2026, 3, 2, 9)),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
  });

  test('a pinned install day survives when the app open is trimmed', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionStart, DateTime(2026, 3, 2, 10)),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.installDay, '2026-03-01');
  });

  test('a malformed event install id is ignored without throwing', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(
          RetentionEventName.sessionStart,
          DateTime(2026, 3, 2, 10),
          installId: '',
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
    expect(metrics.installDay, '2026-03-01');
  });
}
