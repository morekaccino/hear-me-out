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
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(
          RetentionEventName.sessionComplete,
          install.add(const Duration(hours: 1)),
        ),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isTrue);
    expect(metrics.returnedWithin48h, isFalse);
    expect(metrics.secondSessionAt, isNull);
    expect(metrics.installDay, '2026-03-01');
  });

  test('a return at 47 hours counts and one at 49 hours does not', () {
    final first = install.add(const Duration(hours: 1));

    ReturnMetrics at(Duration gap) => returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionComplete, first),
        event(RetentionEventName.sessionComplete, first.add(gap)),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(at(const Duration(hours: 47)).returnedWithin48h, isTrue);
    expect(at(const Duration(hours: 48)).returnedWithin48h, isTrue);
    expect(at(const Duration(hours: 49)).returnedWithin48h, isFalse);
    expect(
      at(const Duration(hours: 49)).secondSessionAt,
      first.add(const Duration(hours: 49)).toUtc(),
    );
    expect(
      at(const Duration(hours: 47)).timeToSecondSession,
      const Duration(hours: 47),
    );
  });

  test('two sessions on the same local day count as a return', () {
    final first = DateTime(2026, 3, 1, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.appOpen, install),
        event(RetentionEventName.sessionComplete, first),
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 1, 20)),
      ], installAt: install),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.returnedWithin48h, isTrue);
    expect(metrics.timeToSecondSession, const Duration(hours: 10));
  });

  test('two sessions at the same instant are not a return', () {
    final same = DateTime(2026, 3, 2, 10);
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionComplete, same),
        event(RetentionEventName.sessionComplete, same),
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
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 2, 10)),
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 10, 10)),
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
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 20, 10)),
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
          RetentionEventName.sessionComplete,
          DateTime(2026, 3, 2, 10),
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
        event(RetentionEventName.sessionComplete, first),
        event(
          RetentionEventName.sessionComplete,
          first.add(const Duration(minutes: 30)),
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
        event(RetentionEventName.sessionComplete, second),
        event(RetentionEventName.sessionComplete, first),
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
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 1, 10)),
        event(RetentionEventName.sessionComplete, first),
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
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 1, 10)),
      ], installAt: DateTime(2026, 3, 2, 9)),
      now: DateTime(2026, 3, 10, 12),
    );

    expect(metrics.hasFirstSession, isFalse);
  });

  test('a pinned install day survives when the app open is trimmed', () {
    final metrics = returnMetricsFromLog(
      logWith([
        event(RetentionEventName.sessionComplete, DateTime(2026, 3, 2, 10)),
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
          RetentionEventName.sessionComplete,
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
