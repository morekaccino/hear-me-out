import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/notifications/reminder_experiment.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';

import '../tool/beta/reminder_experiment_report.dart';

class _ReportResult {
  const _ReportResult({
    required this.code,
    required this.out,
    required this.err,
  });

  final int code;
  final String out;
  final String err;
}

_ReportResult _run(List<String> args) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runReminderExperimentReport(args, out, err);
  return _ReportResult(code: code, out: out.toString(), err: err.toString());
}

Map<String, dynamic> _singleJson(_ReportResult result) {
  final lines = result.out
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  expect(lines, hasLength(1), reason: 'stdout must be one JSON object');
  final decoded = jsonDecode(lines.single);
  expect(decoded, isA<Map<String, dynamic>>());
  return decoded as Map<String, dynamic>;
}

const _genericIds = [
  '0123456789abcdef0123456789abcdef',
  'deadbeefdeadbeefdeadbeefdeadbeef',
  '11111111111111111111111111111111',
  '22222222222222222222222222222222',
  '44444444444444444444444444444444',
  '55555555555555555555555555555555',
  '66666666666666666666666666666666',
  '77777777777777777777777777777777',
  'cccccccccccccccccccccccccccccccc',
  'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
];

const _specificIds = [
  '00000000000000000000000000000000',
  '00000000000000000000000000000001',
  '00000000000000000000000000000002',
  '00000000000000000000000000000003',
  '00000000000000000000000000000006',
  '00000000000000000000000000000007',
  '00000000000000000000000000000008',
  '0000000000000000000000000000000e',
  '33333333333333333333333333333333',
  '88888888888888888888888888888888',
];

String _writeLog(
  Directory directory,
  String name,
  String installId,
  DateTime installAtLocal,
  List<(RetentionEventName, DateTime)> events,
) {
  final log = RetentionLog(
    installId: installId,
    installAt: installAtLocal,
    events: [
      for (final (eventName, at) in events)
        RetentionEvent(name: eventName, timestamp: at, installId: installId),
    ],
  );
  final file = File('${directory.path}/$name.json');
  file.writeAsStringSync(log.exportJson());
  return file.path;
}

/// Writes an older export with no `installAt` and no `app_open`, so the log
/// cannot derive one. The protocol falls back to the first event.
String _writeLogWithoutInstallAt(
  Directory directory,
  String name,
  String installId,
  List<(RetentionEventName, DateTime)> events,
) {
  final log = RetentionLog(
    installId: installId,
    events: [
      for (final (eventName, at) in events)
        RetentionEvent(name: eventName, timestamp: at, installId: installId),
    ],
  );
  final file = File('${directory.path}/$name.json');
  file.writeAsStringSync(log.exportJson());
  return file.path;
}

String _iso(DateTime local) => local.toUtc().toIso8601String();

void main() {
  const fixtureDirectory = 'test/fixtures/reminders';
  const specificFixture = '$fixtureDirectory/specific-arm.json';
  const genericFixture = '$fixtureDirectory/generic-arm.json';
  const notExposedFixture = '$fixtureDirectory/not-exposed.json';
  const brokenFixture = '$fixtureDirectory/broken.json';
  const unknownSchemaFixture = '$fixtureDirectory/unknown-schema.json';
  const insufficientNow = '2026-03-05T00:00:00.000Z';

  test('the fixture ids hash to the arms they are labelled with', () {
    for (final id in _genericIds) {
      expect(
        reminderVariantForInstall(id),
        ReminderCopyVariant.generic,
        reason: id,
      );
    }
    for (final id in _specificIds) {
      expect(
        reminderVariantForInstall(id),
        ReminderCopyVariant.specificTask,
        reason: id,
      );
    }
  });

  test('known fixtures classify into both arms and count exposure', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      specificFixture,
      genericFixture,
      notExposedFixture,
    ]);

    expect(result.code, reportExitInsufficientSample);
    final json = _singleJson(result);
    final arms = json['arms'] as Map<String, dynamic>;
    final specific = arms['specificTask'] as Map<String, dynamic>;
    final generic = arms['generic'] as Map<String, dynamic>;

    expect(specific['exposedInstalls'], 1);
    expect(specific['exposedWithFirstSession'], 1);
    expect(specific['returnedWithin48h'], 0);
    expect(generic['exposedInstalls'], 1);
    expect(generic['exposedWithFirstSession'], 1);
    expect(generic['returnedWithin48h'], 1);
    expect((json['installs'] as Map)['analyzed'], 3);
    expect((json['installs'] as Map)['notExposed'], 1);
    expect((json['verdict'] as Map)['result'], 'insufficientSample');
    expect((json['verdict'] as Map)['recommendedCopy'], 'specificTask');
  });

  test('the 48-hour boundary is inclusive and 49 hours does not count', () {
    final directory = Directory.systemTemp.createTempSync('reminder_48h');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final paths = [
        _writeLog(directory, 'at-48h', _specificIds[0], install, [
          (
            RetentionEventName.reminderOptIn,
            first.subtract(const Duration(hours: 1)),
          ),
          (RetentionEventName.sessionComplete, first),
          (
            RetentionEventName.sessionComplete,
            first.add(const Duration(hours: 48)),
          ),
        ]),
        _writeLog(directory, 'at-49h', _specificIds[1], install, [
          (
            RetentionEventName.reminderOptIn,
            first.subtract(const Duration(hours: 1)),
          ),
          (RetentionEventName.sessionComplete, first),
          (
            RetentionEventName.sessionComplete,
            first.add(const Duration(hours: 49)),
          ),
        ]),
        _writeLog(directory, 'no-second', _specificIds[2], install, [
          (
            RetentionEventName.reminderOptIn,
            first.subtract(const Duration(hours: 1)),
          ),
          (RetentionEventName.sessionComplete, first),
        ]),
      ];

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        ...paths,
      ]);

      expect(result.code, reportExitInsufficientSample);
      final specific =
          (_singleJson(result)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(specific['exposedInstalls'], 3);
      expect(specific['exposedWithFirstSession'], 3);
      expect(specific['returnedWithin48h'], 1);
      expect(specific['sessionTwoWindowOpen'], 0);
      expect(
        (specific['sessionTwoWilson95'] as Map)['low'],
        closeTo(0.0615, 0.001),
      );
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('D7 counts only the whole local day seven days after install', () {
    final directory = Directory.systemTemp.createTempSync('reminder_d7');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final optIn = first.subtract(const Duration(hours: 1));
      final paths = [
        _writeLog(directory, 'day-7-start', _specificIds[0], install, [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
          (RetentionEventName.dailyActive, DateTime(2026, 3, 8, 0, 0, 0)),
        ]),
        _writeLog(directory, 'day-7-end', _specificIds[1], install, [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
          (RetentionEventName.dailyActive, DateTime(2026, 3, 8, 23, 59, 59)),
        ]),
        _writeLog(directory, 'day-6-and-8', _specificIds[2], install, [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
          (RetentionEventName.dailyActive, DateTime(2026, 3, 7, 23, 59, 59)),
          (RetentionEventName.dailyActive, DateTime(2026, 3, 9, 0, 0, 0)),
        ]),
      ];

      final complete = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 9, 0, 0, 1)),
        ...paths,
      ]);
      final completeSpecific =
          (_singleJson(complete)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(complete.code, reportExitInsufficientSample);
      expect(completeSpecific['day7Eligible'], 3);
      expect(completeSpecific['activeOnDay7'], 2);
      expect(completeSpecific['day7WindowPending'], 0);

      final during = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 8, 23, 59, 59)),
        ...paths,
      ]);
      final duringSpecific =
          (_singleJson(during)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(duringSpecific['day7Eligible'], 0);
      expect(duringSpecific['day7WindowPending'], 3);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('fewer than eight exposed installs in an arm is insufficient', () {
    final directory = Directory.systemTemp.createTempSync('reminder_small');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final paths = <String>[];
      for (var index = 0; index < 7; index++) {
        paths.add(
          _writeLog(
            directory,
            'specific-$index',
            _specificIds[index],
            install,
            [
              (
                RetentionEventName.reminderOptIn,
                first.subtract(const Duration(hours: 1)),
              ),
              (RetentionEventName.sessionComplete, first),
            ],
          ),
        );
      }
      for (var index = 0; index < 8; index++) {
        paths.add(
          _writeLog(directory, 'generic-$index', _genericIds[index], install, [
            (
              RetentionEventName.reminderOptIn,
              first.subtract(const Duration(hours: 1)),
            ),
            (RetentionEventName.sessionComplete, first),
          ]),
        );
      }

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        ...paths,
      ]);

      expect(result.code, reportExitInsufficientSample);
      final json = _singleJson(result);
      final arms = json['arms'] as Map<String, dynamic>;
      expect((arms['specificTask'] as Map)['exposedInstalls'], 7);
      expect((arms['generic'] as Map)['exposedInstalls'], 8);
      final verdict = json['verdict'] as Map<String, dynamic>;
      expect(verdict['result'], 'insufficientSample');
      expect(verdict['recommendedCopy'], 'specificTask');
      final checks = verdict['checks'] as List;
      expect(
        checks.firstWhere(
          (check) => check['id'] == 'minimum-exposed-installs',
        )['passed'],
        isFalse,
      );
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('eight exposed installs without a session 1 is still insufficient', () {
    final directory = Directory.systemTemp.createTempSync('reminder_session');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final paths = <String>[];
      for (var index = 0; index < 8; index++) {
        paths.add(
          _writeLog(
            directory,
            'specific-$index',
            _specificIds[index],
            install,
            [
              (
                RetentionEventName.reminderOptIn,
                first.subtract(const Duration(hours: 1)),
              ),
              if (index < 7) (RetentionEventName.sessionComplete, first),
            ],
          ),
        );
      }
      for (var index = 0; index < 8; index++) {
        paths.add(
          _writeLog(directory, 'generic-$index', _genericIds[index], install, [
            (
              RetentionEventName.reminderOptIn,
              first.subtract(const Duration(hours: 1)),
            ),
            (RetentionEventName.sessionComplete, first),
          ]),
        );
      }

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        ...paths,
      ]);

      expect(result.code, reportExitInsufficientSample);
      final verdict = _singleJson(result)['verdict'] as Map<String, dynamic>;
      expect(verdict['result'], 'insufficientSample');
      final checks = verdict['checks'] as List;
      expect(
        checks.firstWhere(
          (check) => check['id'] == 'minimum-exposed-installs',
        )['passed'],
        isTrue,
      );
      expect(
        checks.firstWhere(
          (check) => check['id'] == 'minimum-session-one',
        )['passed'],
        isFalse,
      );
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('every pre-registered condition adopts the generic body', () {
    final directory = Directory.systemTemp.createTempSync('reminder_adopt');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final second = first.add(const Duration(hours: 1));
      final paths = <String>[];
      for (var index = 0; index < 10; index++) {
        paths.add(
          _writeLog(
            directory,
            'specific-$index',
            _specificIds[index],
            install,
            [
              (
                RetentionEventName.reminderOptIn,
                first.subtract(const Duration(hours: 1)),
              ),
              (RetentionEventName.sessionComplete, first),
              if (index < 1) (RetentionEventName.sessionComplete, second),
            ],
          ),
        );
        paths.add(
          _writeLog(directory, 'generic-$index', _genericIds[index], install, [
            (
              RetentionEventName.reminderOptIn,
              first.subtract(const Duration(hours: 1)),
            ),
            (RetentionEventName.sessionComplete, first),
            if (index < 9) (RetentionEventName.sessionComplete, second),
          ]),
        );
      }

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        ...paths,
      ]);

      expect(result.code, reportExitUsable);
      final verdict = _singleJson(result)['verdict'] as Map<String, dynamic>;
      expect(verdict['result'], 'adoptGeneric');
      expect(verdict['recommendedCopy'], 'generic');
      for (final check in verdict['checks'] as List) {
        expect(check['passed'], isTrue, reason: '${check['id']}');
      }
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('the decision boundary is exactly fifteen percentage points', () {
    ArmReport armFor(
      ReminderCopyVariant variant,
      int returned, {
      int withSession = 10000,
    }) => ArmReport(
      variant: variant,
      installs: 10000,
      optedInWithAnyEvent: 10000,
      exposedInstalls: 10000,
      exposedWithFirstSession: withSession,
      returnedWithin48h: returned,
      sessionTwoWindowOpen: 0,
      day7Eligible: 0,
      activeOnDay7: 0,
      day7WindowPending: 0,
    );

    final exact = evaluateReminderDecision(
      armFor(ReminderCopyVariant.specificTask, 4000),
      armFor(ReminderCopyVariant.generic, 5500),
    );
    expect(exact.result, ReminderDecisionResult.adoptGeneric);
    expect(exact.recommendedCopy, ReminderCopyVariant.generic);

    final below = evaluateReminderDecision(
      armFor(ReminderCopyVariant.specificTask, 4000),
      armFor(ReminderCopyVariant.generic, 5499),
    );
    expect(below.result, ReminderDecisionResult.inconclusive);
    expect(below.recommendedCopy, ReminderCopyVariant.specificTask);

    final noSession = evaluateReminderDecision(
      armFor(ReminderCopyVariant.specificTask, 0, withSession: 0),
      armFor(ReminderCopyVariant.generic, 0, withSession: 0),
    );
    expect(noSession.result, ReminderDecisionResult.insufficientSample);
  });

  test('a lift with overlapping Wilson intervals keeps the specific copy', () {
    ArmReport arm(ReminderCopyVariant variant, int returned) => ArmReport(
      variant: variant,
      installs: 10,
      optedInWithAnyEvent: 10,
      exposedInstalls: 10,
      exposedWithFirstSession: 10,
      returnedWithin48h: returned,
      sessionTwoWindowOpen: 0,
      day7Eligible: 0,
      activeOnDay7: 0,
      day7WindowPending: 0,
    );

    final decision = evaluateReminderDecision(
      arm(ReminderCopyVariant.specificTask, 5),
      arm(ReminderCopyVariant.generic, 7),
    );

    expect(decision.result, ReminderDecisionResult.inconclusive);
    expect(decision.recommendedCopy, ReminderCopyVariant.specificTask);
    final overlap = decision.checks.firstWhere(
      (check) => check.id == 'wilson-intervals-separate',
    );
    expect(overlap.passed, isFalse);
  });

  test('a malformed file is skipped with a counted warning', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      specificFixture,
      genericFixture,
      brokenFixture,
      unknownSchemaFixture,
    ]);

    expect(result.code, reportExitInsufficientSample);
    final json = _singleJson(result);
    expect((json['files'] as Map)['provided'], 4);
    expect((json['files'] as Map)['parsed'], 2);
    expect((json['files'] as Map)['skipped'], 2);
    expect(result.err, contains('broken.json'));
    expect(result.err, contains('not valid JSON'));
    expect(result.err, contains('unknown-schema.json'));
    expect(result.err, contains('unsupported schemaVersion 2'));
    expect(result.err, contains('skipped 2 of 4 file(s)'));
  });

  test('no usable file returns exit 2 and a JSON error', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      brokenFixture,
      unknownSchemaFixture,
    ]);

    expect(result.code, reportExitBadInput);
    final json = _singleJson(result);
    expect(json['error'], contains('No usable retention log'));
    expect(json['exitCode'], reportExitBadInput);
    expect(result.err, contains('warning: skipped'));
  });

  test('JSON mode prints one pure object and warns only on stderr', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      specificFixture,
      genericFixture,
      brokenFixture,
    ]);

    expect(
      result.out.split('\n').where((line) => line.trim().isNotEmpty),
      hasLength(1),
    );
    expect(result.out, isNot(contains('warning')));
    expect(result.err, contains('warning'));
    final json = _singleJson(result);
    expect(json['schemaVersion'], reminderReportSchemaVersion);
    expect(json['ticket'], 'T5.6');
    expect(json['analysisTime'], insufficientNow);
    expect(json['exitCode'], result.code);
    expect(result.code, reportExitInsufficientSample);
  });

  test('a duplicate install is counted once', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      specificFixture,
      genericFixture,
      genericFixture,
    ]);

    final json = _singleJson(result);
    expect((json['files'] as Map)['parsed'], 3);
    expect((json['files'] as Map)['duplicateInstalls'], 1);
    expect((json['installs'] as Map)['analyzed'], 2);
    expect(((json['arms'] as Map)['generic'] as Map)['exposedInstalls'], 1);
  });

  test('duplicate collapse keeps the longer log in either order', () {
    final directory = Directory.systemTemp.createTempSync('reminder_longer');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final optIn = first.subtract(const Duration(hours: 1));
      final shortPath = _writeLog(
        directory,
        'short',
        _specificIds[0],
        install,
        [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
        ],
      );
      final longPath = _writeLog(directory, 'long', _specificIds[0], install, [
        (RetentionEventName.reminderOptIn, optIn),
        (RetentionEventName.sessionComplete, first),
        (
          RetentionEventName.sessionComplete,
          first.add(const Duration(hours: 1)),
        ),
      ]);

      for (final paths in [
        [shortPath, longPath],
        [longPath, shortPath],
      ]) {
        final result = _run([
          '--json',
          '--now',
          _iso(DateTime(2026, 3, 12, 12)),
          ...paths,
        ]);
        final json = _singleJson(result);
        expect(
          (json['files'] as Map)['duplicateInstalls'],
          1,
          reason: '$paths',
        );
        expect((json['installs'] as Map)['analyzed'], 1, reason: '$paths');
        expect(
          ((json['arms'] as Map)['specificTask'] as Map)['returnedWithin48h'],
          1,
          reason: 'the longer log must win: $paths',
        );
      }
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('the default text report prints the verdict and both arm tables', () {
    final result = _run([
      '--now',
      insufficientNow,
      specificFixture,
      genericFixture,
    ]);

    expect(result.code, reportExitInsufficientSample);
    expect(result.out, contains('Reminder-copy experiment (T5.6)'));
    expect(result.out, contains('D7 activity'));
    expect(result.out, contains('specificTask'));
    expect(result.out, contains('generic'));
    expect(result.out, contains('Verdict: insufficient sample'));
    expect(result.out, contains('Exit 1:'));
    final armRows = result.out
        .split('\n')
        .where(
          (line) =>
              line.startsWith('specificTask') || line.startsWith('generic'),
        )
        .toList();
    expect(armRows, hasLength(4), reason: 'two session rows plus two D7 rows');
    expect(armRows[0], startsWith('specificTask'));
    expect(armRows[1], startsWith('generic'));
    expect(armRows[2], startsWith('specificTask'));
    expect(armRows[3], startsWith('generic'));
    expect(result.err, isEmpty);
  });

  test(
    'events after --now cannot expose an install or enter the opt-in rate',
    () {
      final directory = Directory.systemTemp.createTempSync('reminder_future');
      try {
        final install = DateTime(2026, 3, 1, 9);
        final first = DateTime(2026, 3, 2, 10);
        final futureOptIn = DateTime(2026, 3, 4, 9);
        final specificPath = _writeLog(
          directory,
          'future-specific',
          _specificIds[0],
          install,
          [
            (RetentionEventName.sessionComplete, first),
            (RetentionEventName.reminderOptIn, futureOptIn),
          ],
        );
        final genericPath = _writeLog(
          directory,
          'future-generic',
          _genericIds[0],
          install,
          [(RetentionEventName.reminderOptIn, futureOptIn)],
        );

        final result = _run([
          '--json',
          '--now',
          _iso(DateTime(2026, 3, 3, 12)),
          specificPath,
          genericPath,
        ]);

        final json = _singleJson(result);
        expect((json['installs'] as Map)['notExposed'], 2);
        final specific =
            (json['arms'] as Map)['specificTask'] as Map<String, dynamic>;
        final generic =
            (json['arms'] as Map)['generic'] as Map<String, dynamic>;
        expect(specific['exposedInstalls'], 0);
        expect(specific['optedInWithAnyEvent'], 1);
        expect(specific['reminderOptInRate'], 0.0);
        expect(generic['exposedInstalls'], 0);
        expect(generic['optedInWithAnyEvent'], 0);
        expect(generic['reminderOptInRate'], isNull);
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );

  test(
    'a log without installAt warns and falls back to the first app_open',
    () {
      final result = _run([
        '--json',
        '--now',
        insufficientNow,
        '$fixtureDirectory/missing-install-at.json',
      ]);

      expect(result.code, reportExitInsufficientSample);
      expect(result.err, contains('has no installAt'));
      expect(result.err, contains('first app_open'));
      final specific =
          (_singleJson(result)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(specific['exposedInstalls'], 1);
      expect(specific['exposedWithFirstSession'], 1);
    },
  );

  test('a log without installAt or app_open falls back to the first event', () {
    final directory = Directory.systemTemp.createTempSync('reminder_first');
    try {
      final first = DateTime(2026, 3, 2, 10);
      final path = _writeLogWithoutInstallAt(
        directory,
        'no-install-at',
        _specificIds[0],
        [
          (
            RetentionEventName.reminderOptIn,
            first.subtract(const Duration(hours: 1)),
          ),
          (RetentionEventName.sessionComplete, first),
        ],
      );

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        path,
      ]);

      expect(result.code, reportExitInsufficientSample);
      expect(result.err, contains('has no installAt'));
      expect(result.err, contains('first event'));
      final specific =
          (_singleJson(result)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(specific['exposedInstalls'], 1);
      expect(specific['exposedWithFirstSession'], 1);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('a nonexistent file is skipped without aborting the run', () {
    final result = _run([
      '--json',
      '--now',
      insufficientNow,
      specificFixture,
      '$fixtureDirectory/does-not-exist.json',
    ]);

    expect(result.code, reportExitInsufficientSample);
    expect(result.err, contains('does-not-exist.json'));
    final json = _singleJson(result);
    expect((json['files'] as Map)['parsed'], 1);
    expect((json['files'] as Map)['skipped'], 1);
    expect(((json['arms'] as Map)['generic'] as Map)['exposedInstalls'], 0);
  });

  test('an open 48-hour window requires no session 2 yet', () {
    final directory = Directory.systemTemp.createTempSync('reminder_open');
    try {
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final optIn = first.subtract(const Duration(minutes: 30));
      final returnedPath = _writeLog(
        directory,
        'returned',
        _specificIds[0],
        install,
        [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
          (
            RetentionEventName.sessionComplete,
            first.add(const Duration(minutes: 30)),
          ),
        ],
      );
      final waitingPath = _writeLog(
        directory,
        'waiting',
        _specificIds[1],
        install,
        [
          (RetentionEventName.reminderOptIn, optIn),
          (RetentionEventName.sessionComplete, first),
        ],
      );

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 2, 11)),
        returnedPath,
        waitingPath,
      ]);

      final specific =
          (_singleJson(result)['arms'] as Map)['specificTask']
              as Map<String, dynamic>;
      expect(specific['exposedWithFirstSession'], 2);
      expect(specific['returnedWithin48h'], 1);
      expect(specific['sessionTwoWindowOpen'], 1);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('a foreign-install event is not counted as malformed', () {
    final directory = Directory.systemTemp.createTempSync('reminder_foreign');
    try {
      const installId = '00000000000000000000000000000000';
      final install = DateTime(2026, 3, 1, 9);
      final first = DateTime(2026, 3, 2, 10);
      final log = RetentionLog(
        installId: installId,
        installAt: install,
        events: [
          RetentionEvent(
            name: RetentionEventName.appOpen,
            timestamp: install,
            installId: installId,
          ),
          RetentionEvent(
            name: RetentionEventName.reminderOptIn,
            timestamp: install.add(const Duration(minutes: 5)),
            installId: installId,
          ),
          RetentionEvent(
            name: RetentionEventName.sessionComplete,
            timestamp: first,
            installId: installId,
          ),
          RetentionEvent(
            name: RetentionEventName.sessionComplete,
            timestamp: first.add(const Duration(hours: 1)),
            installId: 'ffffffffffffffffffffffffffffffff',
          ),
        ],
      );
      final file = File('${directory.path}/foreign.json')
        ..writeAsStringSync(log.exportJson());

      final result = _run([
        '--json',
        '--now',
        _iso(DateTime(2026, 3, 12, 12)),
        file.path,
      ]);

      expect(result.code, reportExitInsufficientSample);
      final files = _singleJson(result)['files'] as Map<String, dynamic>;
      expect(files['droppedEvents'], 0);
      expect(files['foreignEvents'], 1);
      expect(result.err, contains('another install id'));
      expect(result.err, isNot(contains('malformed event')));
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('-- ends option parsing', () {
    final result = _run(['--now', insufficientNow, '--', '-missing.json']);

    expect(result.code, reportExitBadInput);
    expect(result.err, isNot(contains('Unknown option')));
    expect(result.err, contains('-missing.json'));
  });

  test('--json after -- is a path, not a mode switch', () {
    final result = _run(['--', '--json']);

    expect(result.code, reportExitBadInput);
    expect(result.out, isEmpty);
    expect(result.err, contains('No usable retention log'));
  });

  test('help exits 0 and documents the exit codes', () {
    final result = _run(['--help']);

    expect(result.code, reportExitUsable);
    expect(result.out, contains('Usage:'));
    expect(result.out, contains('--json'));
    expect(result.out, contains('--now'));
    expect(result.out, contains('Exit codes:'));
  });

  test('bad input returns exit 2', () {
    expect(_run([]).code, reportExitBadInput);
    expect(_run([specificFixture, '--wat']).code, reportExitBadInput);
    expect(
      _run([specificFixture, '--now', 'not-a-date']).code,
      reportExitBadInput,
    );
    expect(_run([specificFixture, '--now']).code, reportExitBadInput);
    expect(
      _run([specificFixture, '--now', '2026-12-01T00:00:00']).code,
      reportExitBadInput,
    );
  });

  test('a bad --now still honors the parsed --json mode', () {
    final result = _run([
      '--json',
      specificFixture,
      '--now',
      '2026-12-01T00:00:00',
    ]);

    expect(result.code, reportExitBadInput);
    final json = _singleJson(result);
    expect(json['error'], contains('explicit offset'));
    expect(json['exitCode'], reportExitBadInput);
  });

  test('the Wilson interval matches the documented 4-of-10 value', () {
    final interval = wilsonInterval(4, 10);

    expect(interval.low, closeTo(0.1682, 0.0001));
    expect(interval.high, closeTo(0.6873, 0.0001));
  });
}
