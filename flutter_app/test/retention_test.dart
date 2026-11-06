import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';

void main() {
  group('RetentionEventName', () {
    test('wire names stay stable', () {
      expect(
        {for (final name in RetentionEventName.values) name: name.wireName},
        {
          RetentionEventName.appOpen: 'app_open',
          RetentionEventName.onboardingStart: 'onboarding_start',
          RetentionEventName.onboardingComplete: 'onboarding_complete',
          RetentionEventName.firstNote: 'first_note',
          RetentionEventName.firstPhrase: 'first_phrase',
          RetentionEventName.firstRecording: 'first_recording',
          RetentionEventName.sessionStart: 'session_start',
          RetentionEventName.sessionComplete: 'session_complete',
          RetentionEventName.dailyActive: 'daily_active',
        },
      );
    });

    test('unknown wire names are rejected', () {
      expect(
        RetentionEventName.fromWireName('app_open'),
        RetentionEventName.appOpen,
      );
      expect(RetentionEventName.fromWireName('email'), isNull);
    });
  });

  group('RetentionLog', () {
    test('the event bound drops the oldest events', () {
      var log = RetentionLog(installId: 'install-1');
      final start = DateTime.utc(2026, 1, 1, 9);
      for (var index = 0; index < retentionEventLimit + 5; index++) {
        log = log.record(
          RetentionEventName.sessionStart,
          at: start.add(Duration(minutes: index)),
        );
      }

      expect(log.events, hasLength(retentionEventLimit));
      expect(log.events.first.timestamp, start.add(const Duration(minutes: 5)));
      expect(
        log.events.last.timestamp,
        start.add(Duration(minutes: retentionEventLimit + 4)),
      );
    });

    test('funnel reports the first occurrence of each step', () {
      final day = DateTime.utc(2026, 2, 1, 9);
      var log = RetentionLog(installId: 'install-1');
      final events = <(RetentionEventName, DateTime)>[
        (RetentionEventName.appOpen, day),
        (
          RetentionEventName.onboardingStart,
          day.add(const Duration(minutes: 2)),
        ),
        (
          RetentionEventName.onboardingComplete,
          day.add(const Duration(minutes: 5)),
        ),
        (RetentionEventName.firstNote, day.add(const Duration(minutes: 7))),
        (
          RetentionEventName.firstPhrase,
          day.add(const Duration(days: 1, hours: 1)),
        ),
        (
          RetentionEventName.firstRecording,
          day.add(const Duration(days: 2, hours: 1)),
        ),
        (RetentionEventName.appOpen, day.add(const Duration(days: 3))),
      ];
      for (final (name, at) in events) {
        log = log.record(name, at: at);
      }

      final funnel = log.funnel();
      expect(funnel.keys, retentionFunnelSteps);
      expect(funnel[RetentionEventName.appOpen], day);
      expect(
        funnel[RetentionEventName.onboardingStart],
        day.add(const Duration(minutes: 2)),
      );
      expect(
        funnel[RetentionEventName.onboardingComplete],
        day.add(const Duration(minutes: 5)),
      );
      expect(
        funnel[RetentionEventName.firstNote],
        day.add(const Duration(minutes: 7)),
      );
      expect(
        funnel[RetentionEventName.firstPhrase],
        day.add(const Duration(days: 1, hours: 1)),
      );
      expect(
        funnel[RetentionEventName.firstRecording],
        day.add(const Duration(days: 2, hours: 1)),
      );
    });

    test('D1, D7, and D30 use local calendar days', () {
      final install = DateTime(2026, 3, 1, 10);
      var log = RetentionLog(installId: 'install-1')
          .record(RetentionEventName.appOpen, at: install);

      expect(log.installDay, '2026-03-01');
      expect(log.activeDays, {'2026-03-01'});
      expect(log.retainedOnDay(0), isTrue);
      expect(log.d1Retained, isFalse);
      expect(log.d7Retained, isFalse);
      expect(log.d30Retained, isFalse);

      log = log.record(
        RetentionEventName.sessionStart,
        at: DateTime(2026, 3, 2, 8),
      );
      expect(log.d1Retained, isTrue);
      expect(log.d7Retained, isFalse);

      log = log.record(
        RetentionEventName.sessionStart,
        at: DateTime(2026, 3, 8, 23),
      );
      expect(log.d7Retained, isTrue);
      expect(log.d30Retained, isFalse);

      log = log.record(
        RetentionEventName.sessionStart,
        at: DateTime(2026, 3, 31, 0),
      );
      expect(log.d30Retained, isTrue);
      expect(log.activeDays, hasLength(4));
    });

    test('missing app open falls back to the first event day', () {
      final log = RetentionLog(
        installId: 'install-1',
      ).record(RetentionEventName.sessionStart, at: DateTime(2026, 4, 1, 12));
      expect(log.installDay, '2026-04-01');
      expect(log.d1Retained, isFalse);
    });

    test('export JSON has only name, timestamp, and install id', () {
      final at = DateTime(2026, 5, 1, 12);
      final log = RetentionLog(installId: 'install-1')
          .record(RetentionEventName.appOpen, at: at)
          .record(RetentionEventName.firstNote, at: at);

      final decoded = jsonDecode(log.exportJson()) as Map<String, dynamic>;
      expect(decoded.keys.toSet(), {'schemaVersion', 'installId', 'events'});
      expect(decoded['installId'], 'install-1');
      final events = decoded['events'] as List<dynamic>;
      expect(events, hasLength(2));
      for (final raw in events) {
        final event = raw as Map<String, dynamic>;
        expect(event.keys.toSet(), {'name', 'at', 'installId'});
        expect(event['installId'], 'install-1');
        expect(DateTime.parse(event['at'] as String).isUtc, isTrue);
      }

      final lower = log.exportJson().toLowerCase();
      for (final forbidden in [
        'audio',
        'piece',
        'title',
        'email',
        'device',
        'fingerprint',
      ]) {
        expect(lower, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('clear keeps the install id and the bound', () {
      final log = RetentionLog(installId: 'install-1')
          .record(RetentionEventName.appOpen, at: DateTime.utc(2026, 1, 1));
      final cleared = log.clear();
      expect(cleared.installId, 'install-1');
      expect(cleared.events, isEmpty);
      expect(cleared.maxEvents, retentionEventLimit);
    });
  });

  test(
    'the retention domain has no Flutter, storage, IO, or network imports',
    () {
      final imports = RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );
      final forbidden = <String>[
        'package:flutter',
        'package:flutter_riverpod',
        'package:shared_preferences',
        'package:http',
        'package:dio',
        'package:web',
        'dart:io',
        'dart:html',
        'dart:js',
        'dart:js_interop',
      ];
      final violations = <String>[];

      for (final entity in Directory(
        'lib/core/retention',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final match in imports.allMatches(source)) {
          final uri = match.group(1)!;
          for (final prefix in forbidden) {
            if (uri.startsWith(prefix)) {
              violations.add('${entity.path} -> $uri');
            }
          }
        }
      }

      expect(violations, isEmpty);
    },
  );
}
