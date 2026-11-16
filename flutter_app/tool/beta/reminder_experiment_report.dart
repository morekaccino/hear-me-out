// Reminder-copy experiment analysis for the T5.6 beta.
//
// Reads one or more local retention logs exported from
// Profile -> Privacy -> Copy usage log and prints the pre-registered metrics
// per arm. Nothing is uploaded. The arm comes from the same
// `reminderVariantForInstall` function the app uses, so the analysis cannot
// disagree with the delivered copy.
//
// See docs/REMINDER_EXPERIMENT.md for the protocol.
//
// Run `dart run tool/beta/reminder_experiment_report.dart --help` for usage.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:hear_me_out/core/notifications/reminder_experiment.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';
import 'package:hear_me_out/core/retention/return_metrics.dart';

/// Exit code when the sample supports the pre-registered decision.
const int reportExitUsable = 0;

/// Exit code when the analysis ran but either arm is below the sample floor.
const int reportExitInsufficientSample = 1;

/// Exit code for bad input: no usable log, an unknown option, or a bad --now.
const int reportExitBadInput = 2;

/// The JSON report shape. Bump only with a documented change.
const int reminderReportSchemaVersion = 1;

/// The pre-registered sample floor from docs/REMINDER_EXPERIMENT.md.
///
/// The ticket also requires an explicit insufficient-sample result when either
/// arm has fewer than eight exposed installs, so both checks are reported.
const int minimumExposedInstallsPerArm = 8;

/// The decision rule's first condition: eight exposed installs with a session 1.
const int minimumExposedWithSessionPerArm = 8;

/// The minimum generic-arm lift in percentage points.
const double minimumSessionTwoLiftPoints = 15;

/// The reported interval confidence.
const double wilsonConfidence = 0.95;

/// Two-sided 95% normal quantile.
const double _wilsonZ = 1.959963984540054;

Future<void> main(List<String> args) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runReminderExperimentReport(args, out, err);
  stdout.write(out.toString());
  stderr.write(err.toString());
  exitCode = code;
}

/// Runs the report without touching [stdout], [stderr], or [exitCode].
///
/// Returns the process exit code. The function is public so tests can exercise
/// the dispatch, analysis, JSON purity, and exit codes in-process.
int runReminderExperimentReport(
  List<String> args,
  StringSink out,
  StringSink err,
) {
  final jsonMode = args.contains('--json');
  _Options options;
  try {
    options = _Options.parse(args);
  } on _UsageException catch (error) {
    return _writeError(jsonMode, out, err, error.message);
  }

  if (options.help) {
    out.write(_helpText);
    return reportExitUsable;
  }
  if (options.paths.isEmpty) {
    return _writeError(
      jsonMode,
      out,
      err,
      'Provide at least one exported retention JSON file.',
    );
  }

  final now = options.now ?? DateTime.now().toUtc();
  final analysis = _analyze(options.paths, now, err);
  if (analysis == null) {
    return _writeError(
      jsonMode,
      out,
      err,
      'No usable retention log. Fix the skipped files and try again.',
    );
  }

  final decision = evaluateReminderDecision(
    analysis.specific,
    analysis.generic,
  );
  final code = decision.result == ReminderDecisionResult.insufficientSample
      ? reportExitInsufficientSample
      : reportExitUsable;

  if (jsonMode) {
    out.writeln(jsonEncode(_analysisToJson(analysis, decision, code, now)));
  } else {
    _writeTextReport(out, analysis, decision, now);
  }
  return code;
}

/// The pre-registered verdict for the reminder-copy experiment.
enum ReminderDecisionResult {
  /// At least one arm is below the pre-registered sample floor.
  insufficientSample,

  /// The sample is adequate but the generic arm did not clear every condition.
  inconclusive,

  /// Every pre-registered condition holds; the generic body may replace copy.
  adoptGeneric,
}

/// One pre-registered condition, with its real counts for the report.
class ReminderDecisionCheck {
  const ReminderDecisionCheck({
    required this.id,
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String id;
  final String label;
  final bool passed;
  final String detail;
}

/// The verdict plus the evidence for each pre-registered condition.
class ReminderDecision {
  const ReminderDecision({
    required this.result,
    required this.recommendedCopy,
    required this.checks,
    required this.summary,
  });

  final ReminderDecisionResult result;
  final ReminderCopyVariant recommendedCopy;
  final List<ReminderDecisionCheck> checks;
  final String summary;
}

/// A two-sided Wilson score interval for a binomial proportion.
class WilsonInterval {
  const WilsonInterval(this.low, this.high);

  final double low;
  final double high;

  Map<String, double> toJson() => {'low': low, 'high': high};
}

/// The Wilson score interval for [successes] out of [total] at 95%.
///
/// [total] must be positive; callers report `n/a` instead of calling this for
/// an empty denominator.
WilsonInterval wilsonInterval(int successes, int total) {
  if (total <= 0) {
    throw ArgumentError.value(total, 'total', 'must be positive');
  }
  final p = successes / total;
  final zSquared = _wilsonZ * _wilsonZ;
  final denominator = 1 + zSquared / total;
  final center = (p + zSquared / (2 * total)) / denominator;
  final margin =
      _wilsonZ *
      math.sqrt((p * (1 - p) + zSquared / (4 * total)) / total) /
      denominator;
  return WilsonInterval(
    (center - margin).clamp(0.0, 1.0),
    (center + margin).clamp(0.0, 1.0),
  );
}

/// The per-arm metrics the decision reads.
///
/// Every count comes from a real log through `returnMetricsFromLog`. A rate is
/// null when its denominator is zero, so the report never invents a zero
/// denominator.
class ArmReport {
  const ArmReport({
    required this.variant,
    required this.installs,
    required this.optedInWithAnyEvent,
    required this.exposedInstalls,
    required this.exposedWithFirstSession,
    required this.returnedWithin48h,
    required this.sessionTwoWindowOpen,
    required this.day7Eligible,
    required this.activeOnDay7,
    required this.day7WindowPending,
  });

  final ReminderCopyVariant variant;

  /// Every analyzed install whose id hashes to this arm.
  final int installs;

  /// Analyzed installs with at least one event; the opt-in-rate denominator.
  final int optedInWithAnyEvent;

  /// Installs with a `reminder_opt_in` event.
  final int exposedInstalls;

  /// Exposed installs with a real first session.
  final int exposedWithFirstSession;

  /// Exposed installs whose next session fell within 48 elapsed hours.
  final int returnedWithin48h;

  /// Exposed installs whose 48-hour session-2 window is still open.
  final int sessionTwoWindowOpen;

  /// Exposed installs whose D7 local day has finished.
  final int day7Eligible;

  /// Eligible installs active on the D7 local day.
  final int activeOnDay7;

  /// Exposed installs whose D7 local day has not finished.
  final int day7WindowPending;

  double? get sessionTwoRate => exposedWithFirstSession == 0
      ? null
      : returnedWithin48h / exposedWithFirstSession;

  WilsonInterval? get sessionTwoInterval => exposedWithFirstSession == 0
      ? null
      : wilsonInterval(returnedWithin48h, exposedWithFirstSession);

  double? get day7Rate =>
      day7Eligible == 0 ? null : activeOnDay7 / day7Eligible;

  WilsonInterval? get day7Interval =>
      day7Eligible == 0 ? null : wilsonInterval(activeOnDay7, day7Eligible);

  double? get reminderOptInRate =>
      optedInWithAnyEvent == 0 ? null : exposedInstalls / optedInWithAnyEvent;
}

/// Applies the pre-registered decision rule from docs/REMINDER_EXPERIMENT.md.
///
/// The generic copy is adopted only when all of these hold:
///
/// 1. At least eight exposed installs per arm have a session 1.
/// 2. The generic session-2 rate is at least 15 percentage points higher.
/// 3. The 95% Wilson intervals for the two rates do not overlap.
///
/// A sample below eight exposed installs per arm is reported separately as
/// [ReminderDecisionResult.insufficientSample], as the T5.6 ticket requires.
/// Every other failure is inconclusive and keeps the specific-task copy.
ReminderDecision evaluateReminderDecision(
  ArmReport specific,
  ArmReport generic,
) {
  final enoughExposed =
      specific.exposedInstalls >= minimumExposedInstallsPerArm &&
      generic.exposedInstalls >= minimumExposedInstallsPerArm;
  final enoughWithSession =
      specific.exposedWithFirstSession >= minimumExposedWithSessionPerArm &&
      generic.exposedWithFirstSession >= minimumExposedWithSessionPerArm;

  final specificDen = specific.exposedWithFirstSession;
  final genericDen = generic.exposedWithFirstSession;
  // Compare percentages with integer arithmetic so 15 points is exact.
  final liftPasses =
      enoughWithSession &&
      specificDen > 0 &&
      genericDen > 0 &&
      100 *
              (generic.returnedWithin48h * specificDen -
                  specific.returnedWithin48h * genericDen) >=
          minimumSessionTwoLiftPoints * specificDen * genericDen;

  final specificInterval = specific.sessionTwoInterval;
  final genericInterval = generic.sessionTwoInterval;
  final intervalsSeparate =
      enoughWithSession &&
      specificInterval != null &&
      genericInterval != null &&
      specificInterval.high < genericInterval.low;

  final checks = <ReminderDecisionCheck>[
    ReminderDecisionCheck(
      id: 'minimum-exposed-installs',
      label: 'At least $minimumExposedInstallsPerArm exposed installs per arm',
      passed: enoughExposed,
      detail:
          '${specific.variant.name} ${specific.exposedInstalls}, '
          '${generic.variant.name} ${generic.exposedInstalls}',
    ),
    ReminderDecisionCheck(
      id: 'minimum-session-one',
      label:
          'At least $minimumExposedWithSessionPerArm exposed installs with a '
          'session 1 per arm',
      passed: enoughWithSession,
      detail:
          '${specific.variant.name} ${specific.exposedWithFirstSession}, '
          '${generic.variant.name} ${generic.exposedWithFirstSession}',
    ),
    ReminderDecisionCheck(
      id: 'session-two-lift',
      label: 'Generic session-2 rate at least 15 points higher',
      passed: liftPasses,
      detail: !enoughWithSession
          ? 'not evaluated: the sample is insufficient'
          : _liftDetail(specific, generic),
    ),
    ReminderDecisionCheck(
      id: 'wilson-intervals-separate',
      label: '95% Wilson intervals do not overlap',
      passed: intervalsSeparate,
      detail: !enoughWithSession
          ? 'not evaluated: the sample is insufficient'
          : 'specific ${_intervalText(specificInterval)}, '
                'generic ${_intervalText(genericInterval)}; '
                '${intervalsSeparate ? 'separate' : 'overlapping'}',
    ),
  ];

  if (!enoughExposed) {
    return ReminderDecision(
      result: ReminderDecisionResult.insufficientSample,
      recommendedCopy: ReminderCopyVariant.specificTask,
      checks: checks,
      summary:
          'insufficient sample: fewer than '
          '$minimumExposedInstallsPerArm exposed installs in at least one arm. '
          'Keep the specific-task copy.',
    );
  }
  if (!enoughWithSession) {
    return ReminderDecision(
      result: ReminderDecisionResult.insufficientSample,
      recommendedCopy: ReminderCopyVariant.specificTask,
      checks: checks,
      summary:
          'insufficient sample: fewer than '
          '$minimumExposedWithSessionPerArm exposed installs with a session 1 '
          'in at least one arm. Keep the specific-task copy.',
    );
  }
  if (!liftPasses || !intervalsSeparate) {
    return ReminderDecision(
      result: ReminderDecisionResult.inconclusive,
      recommendedCopy: ReminderCopyVariant.specificTask,
      checks: checks,
      summary:
          'inconclusive: the generic arm did not meet every pre-registered '
          'condition. Keep the specific-task copy.',
    );
  }
  return ReminderDecision(
    result: ReminderDecisionResult.adoptGeneric,
    recommendedCopy: ReminderCopyVariant.generic,
    checks: checks,
    summary:
        'adopt generic: every pre-registered condition holds. The generic '
        'body may replace the specific-task copy.',
  );
}

String _liftDetail(ArmReport specific, ArmReport generic) {
  final specificRate = specific.sessionTwoRate;
  final genericRate = generic.sessionTwoRate;
  if (specificRate == null || genericRate == null) {
    return 'not evaluated: a session-2 denominator is zero';
  }
  final lift = (genericRate - specificRate) * 100;
  return 'specific ${_percent(specificRate)} '
      '(${specific.returnedWithin48h}/${specific.exposedWithFirstSession}), '
      'generic ${_percent(genericRate)} '
      '(${generic.returnedWithin48h}/${generic.exposedWithFirstSession}); '
      'lift ${lift.toStringAsFixed(1)} points';
}

String _intervalText(WilsonInterval? interval) => interval == null
    ? 'n/a'
    : '[${_percent(interval.low)}, ${_percent(interval.high)}]';

String _percent(double? value) =>
    value == null ? 'n/a' : '${(value * 100).toStringAsFixed(1)}%';

String _rateWithInterval(double? rate, WilsonInterval? interval) =>
    rate == null ? 'n/a' : '${_percent(rate)} ${_intervalText(interval)}';

class _Options {
  const _Options({
    required this.json,
    required this.help,
    required this.now,
    required this.paths,
  });

  final bool json;
  final bool help;
  final DateTime? now;
  final List<String> paths;

  static _Options parse(List<String> args) {
    var json = false;
    var help = false;
    DateTime? now;
    final paths = <String>[];

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == '--json') {
        json = true;
        continue;
      }
      if (arg == '--help' || arg == '-h') {
        help = true;
        continue;
      }
      if (arg == '--now') {
        if (index + 1 >= args.length) {
          throw const _UsageException('--now needs a UTC ISO-8601 timestamp.');
        }
        final raw = args[++index];
        final parsed = DateTime.tryParse(raw);
        if (parsed == null) {
          throw _UsageException(
            '--now is not a valid ISO-8601 timestamp: $raw',
          );
        }
        now = parsed.toUtc();
        continue;
      }
      if (arg == '--') {
        paths.addAll(args.sublist(index + 1));
        break;
      }
      if (arg.startsWith('-')) {
        throw _UsageException('Unknown option "$arg". Run --help.');
      }
      paths.add(arg);
    }

    return _Options(json: json, help: help, now: now, paths: paths);
  }
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}

class _MalformedFile implements Exception {
  const _MalformedFile(this.message);

  final String message;
}

class _ParsedExport {
  const _ParsedExport({
    required this.log,
    required this.droppedEvents,
    required this.installAtMissing,
  });

  final RetentionLog log;
  final int droppedEvents;
  final bool installAtMissing;
}

class _Analysis {
  const _Analysis({
    required this.filesProvided,
    required this.filesParsed,
    required this.filesSkipped,
    required this.duplicateInstalls,
    required this.droppedEvents,
    required this.installsAnalyzed,
    required this.installsNotExposed,
    required this.specific,
    required this.generic,
  });

  final int filesProvided;
  final int filesParsed;
  final int filesSkipped;
  final int duplicateInstalls;
  final int droppedEvents;
  final int installsAnalyzed;
  final int installsNotExposed;
  final ArmReport specific;
  final ArmReport generic;
}

_Analysis? _analyze(List<String> paths, DateTime now, StringSink err) {
  final parsed = <_ParsedExport>[];
  var skipped = 0;
  var droppedEvents = 0;

  for (final path in paths) {
    try {
      final raw = File(path).readAsStringSync();
      final export = _parseExport(raw);
      droppedEvents += export.droppedEvents;
      if (export.installAtMissing) {
        err.writeln(
          'warning: "$path" has no installAt; D7 falls back to the first '
          'app_open.',
        );
      }
      parsed.add(export);
    } on _MalformedFile catch (error) {
      skipped++;
      err.writeln('warning: skipped "$path": ${error.message}');
    } on FileSystemException catch (error) {
      skipped++;
      err.writeln(
        'warning: skipped "$path": ${error.osError?.message ?? error.message}',
      );
    }
  }

  if (parsed.isEmpty) {
    err.writeln('warning: no usable file out of ${paths.length}.');
    return null;
  }

  final byInstall = <String, _ParsedExport>{};
  var duplicates = 0;
  for (final export in parsed) {
    final key = export.log.installId.trim().toLowerCase();
    final existing = byInstall[key];
    if (existing == null) {
      byInstall[key] = export;
      continue;
    }
    duplicates++;
    if (export.log.length > existing.log.length) {
      byInstall[key] = export;
    }
    err.writeln(
      'warning: collapsed a duplicate install id (kept the log with more '
      'events).',
    );
  }

  final specific = _ArmAccumulator(ReminderCopyVariant.specificTask);
  final generic = _ArmAccumulator(ReminderCopyVariant.generic);
  var notExposed = 0;

  for (final export in byInstall.values) {
    final log = export.log;
    final variant = reminderVariantForInstall(log.installId);
    final arm = variant == ReminderCopyVariant.generic ? generic : specific;
    final metrics = returnMetricsFromLog(log, now: now);
    final exposed = log.hasEvent(RetentionEventName.reminderOptIn);

    arm.installs++;
    if (log.events.isNotEmpty) arm.optedInWithAnyEvent++;
    if (!exposed) {
      notExposed++;
      continue;
    }

    arm.exposedInstalls++;
    if (metrics.hasFirstSession) {
      arm.exposedWithFirstSession++;
      if (metrics.returnedWithin48h) arm.returnedWithin48h++;
      final first = metrics.firstSessionAt;
      if (first != null && now.difference(first) < sessionTwoReturnWindow) {
        arm.sessionTwoWindowOpen++;
      }
    }
    if (metrics.day7WindowComplete) {
      arm.day7Eligible++;
      if (metrics.activeOnDay7) arm.activeOnDay7++;
    } else {
      arm.day7WindowPending++;
    }
  }

  if (skipped > 0) {
    err.writeln(
      'warning: skipped $skipped of ${paths.length} file(s) as malformed or '
      'unreadable.',
    );
  }
  if (droppedEvents > 0) {
    err.writeln(
      'warning: dropped $droppedEvents malformed event(s) while parsing.',
    );
  }
  if (duplicates > 0) {
    err.writeln('warning: collapsed $duplicates duplicate install id(s).');
  }

  final specificReport = specific.build();
  final genericReport = generic.build();
  if (specificReport.sessionTwoWindowOpen + genericReport.sessionTwoWindowOpen >
      0) {
    err.writeln(
      'warning: ${specificReport.sessionTwoWindowOpen + genericReport.sessionTwoWindowOpen} '
      'exposed install(s) have a session-1 less than 48 hours before the '
      'analysis time; their session-2 result is not final.',
    );
  }

  return _Analysis(
    filesProvided: paths.length,
    filesParsed: parsed.length,
    filesSkipped: skipped,
    duplicateInstalls: duplicates,
    droppedEvents: droppedEvents,
    installsAnalyzed: byInstall.length,
    installsNotExposed: notExposed,
    specific: specificReport,
    generic: genericReport,
  );
}

_ParsedExport _parseExport(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw const _MalformedFile('not valid JSON');
  }
  if (decoded is! Map) {
    throw const _MalformedFile('not a JSON object');
  }
  final version = decoded['schemaVersion'];
  if (version is! num) {
    throw const _MalformedFile('missing schemaVersion');
  }
  if (version.toInt() != 1) {
    throw _MalformedFile('unsupported schemaVersion $version');
  }
  final installId = decoded['installId'];
  if (installId is! String || installId.trim().isEmpty) {
    throw const _MalformedFile('missing installId');
  }
  final rawEvents = decoded['events'];
  if (rawEvents is! List) {
    throw const _MalformedFile('missing events array');
  }

  DateTime? installAt;
  var installAtMissing = false;
  final rawInstallAt = decoded['installAt'];
  if (rawInstallAt == null) {
    installAtMissing = true;
  } else if (rawInstallAt is! String) {
    throw const _MalformedFile('installAt is not a string');
  } else {
    installAt = DateTime.tryParse(rawInstallAt);
    if (installAt == null) {
      throw const _MalformedFile('installAt is not an ISO-8601 timestamp');
    }
    installAt = installAt.toUtc();
  }

  var droppedEvents = 0;
  final events = <RetentionEvent>[];
  for (final rawEvent in rawEvents) {
    final event = RetentionEvent.tryFromJson(
      rawEvent,
      expectedInstallId: installId,
    );
    if (event == null) {
      droppedEvents++;
      continue;
    }
    events.add(event);
  }

  return _ParsedExport(
    log: RetentionLog(
      installId: installId,
      events: events,
      installAt: installAt,
    ),
    droppedEvents: droppedEvents,
    installAtMissing: installAtMissing,
  );
}

class _ArmAccumulator {
  _ArmAccumulator(this.variant);

  final ReminderCopyVariant variant;
  int installs = 0;
  int optedInWithAnyEvent = 0;
  int exposedInstalls = 0;
  int exposedWithFirstSession = 0;
  int returnedWithin48h = 0;
  int sessionTwoWindowOpen = 0;
  int day7Eligible = 0;
  int activeOnDay7 = 0;
  int day7WindowPending = 0;

  ArmReport build() => ArmReport(
    variant: variant,
    installs: installs,
    optedInWithAnyEvent: optedInWithAnyEvent,
    exposedInstalls: exposedInstalls,
    exposedWithFirstSession: exposedWithFirstSession,
    returnedWithin48h: returnedWithin48h,
    sessionTwoWindowOpen: sessionTwoWindowOpen,
    day7Eligible: day7Eligible,
    activeOnDay7: activeOnDay7,
    day7WindowPending: day7WindowPending,
  );
}

void _writeTextReport(
  StringSink out,
  _Analysis analysis,
  ReminderDecision decision,
  DateTime now,
) {
  out.writeln('Reminder-copy experiment (T5.6) - local analysis');
  out.writeln('Protocol: docs/REMINDER_EXPERIMENT.md');
  out.writeln(
    'Analysis time: ${now.toUtc().toIso8601String()} '
    '(D7 uses the analysis machine local timezone)',
  );
  out.writeln(
    'Files: ${analysis.filesProvided} provided, ${analysis.filesParsed} '
    'analyzed, ${analysis.filesSkipped} skipped, '
    '${analysis.duplicateInstalls} duplicate install(s), '
    '${analysis.droppedEvents} dropped event(s)',
  );
  out.writeln(
    'Installs: ${analysis.installsAnalyzed} analyzed, '
    '${analysis.installsNotExposed} not exposed',
  );
  out.writeln('');

  const sessionWidths = [14, 8, 10, 13, 30, 12];
  out.writeln(
    _tableRow(const [
      'Arm',
      'Exposed',
      'Session 1',
      'Returned 48h',
      'Session-2 rate',
      'Opt-in',
    ], sessionWidths),
  );
  for (final arm in [analysis.specific, analysis.generic]) {
    out.writeln(
      _tableRow([
        arm.variant.name,
        '${arm.exposedInstalls}',
        '${arm.exposedWithFirstSession}',
        '${arm.returnedWithin48h}/${arm.exposedWithFirstSession}',
        _rateWithInterval(arm.sessionTwoRate, arm.sessionTwoInterval),
        '${arm.exposedInstalls}/${arm.optedInWithAnyEvent}',
      ], sessionWidths),
    );
  }
  out.writeln('');

  const daySevenWidths = [14, 10, 8, 9, 46];
  out.writeln(
    'D7 activity (local calendar day seven days after the install day)',
  );
  out.writeln(
    _tableRow(const [
      'Arm',
      'Eligible',
      'Active',
      'Pending',
      'D7 rate',
    ], daySevenWidths),
  );
  for (final arm in [analysis.specific, analysis.generic]) {
    out.writeln(
      _tableRow([
        arm.variant.name,
        '${arm.day7Eligible}',
        '${arm.activeOnDay7}',
        '${arm.day7WindowPending}',
        _rateWithInterval(arm.day7Rate, arm.day7Interval),
      ], daySevenWidths),
    );
  }
  out.writeln('');

  out.writeln('Pre-registered checks');
  for (final check in decision.checks) {
    out.writeln(
      '[${check.passed ? 'PASS' : 'FAIL'}] ${check.label}: ${check.detail}',
    );
  }
  out.writeln('');
  out.writeln('Verdict: ${decision.summary}');
  if (decision.result == ReminderDecisionResult.insufficientSample) {
    out.writeln(
      'Exit $reportExitInsufficientSample: the sample is not usable for the '
      'pre-registered decision.',
    );
  } else {
    out.writeln(
      'Exit $reportExitUsable: the sample is usable for the pre-registered '
      'decision.',
    );
  }
}

String _tableRow(List<String> cells, List<int> widths) {
  final padded = <String>[];
  for (var index = 0; index < cells.length; index++) {
    padded.add(cells[index].padRight(widths[index]));
  }
  return padded.join(' ').trimRight();
}

Map<String, Object?> _analysisToJson(
  _Analysis analysis,
  ReminderDecision decision,
  int code,
  DateTime now,
) => {
  'schemaVersion': reminderReportSchemaVersion,
  'ticket': 'T5.6',
  'protocol': 'docs/REMINDER_EXPERIMENT.md',
  'analysisTime': now.toUtc().toIso8601String(),
  'minimumExposedInstallsPerArm': minimumExposedInstallsPerArm,
  'minimumExposedWithSessionPerArm': minimumExposedWithSessionPerArm,
  'minimumSessionTwoLiftPoints': minimumSessionTwoLiftPoints,
  'wilsonConfidence': wilsonConfidence,
  'files': {
    'provided': analysis.filesProvided,
    'parsed': analysis.filesParsed,
    'skipped': analysis.filesSkipped,
    'duplicateInstalls': analysis.duplicateInstalls,
    'droppedEvents': analysis.droppedEvents,
  },
  'installs': {
    'analyzed': analysis.installsAnalyzed,
    'notExposed': analysis.installsNotExposed,
  },
  'arms': {
    ReminderCopyVariant.specificTask.name: _armToJson(analysis.specific),
    ReminderCopyVariant.generic.name: _armToJson(analysis.generic),
  },
  'verdict': {
    'result': decision.result.name,
    'recommendedCopy': decision.recommendedCopy.name,
    'summary': decision.summary,
    'checks': [
      for (final check in decision.checks)
        {
          'id': check.id,
          'label': check.label,
          'passed': check.passed,
          'detail': check.detail,
        },
    ],
  },
  'exitCode': code,
};

Map<String, Object?> _armToJson(ArmReport arm) => {
  'variant': arm.variant.name,
  'installs': arm.installs,
  'optedInWithAnyEvent': arm.optedInWithAnyEvent,
  'reminderOptIn': arm.exposedInstalls,
  'reminderOptInRate': arm.reminderOptInRate,
  'exposedInstalls': arm.exposedInstalls,
  'exposedWithFirstSession': arm.exposedWithFirstSession,
  'returnedWithin48h': arm.returnedWithin48h,
  'sessionTwoRate': arm.sessionTwoRate,
  'sessionTwoWilson95': arm.sessionTwoInterval?.toJson(),
  'sessionTwoWindowOpen': arm.sessionTwoWindowOpen,
  'day7Eligible': arm.day7Eligible,
  'activeOnDay7': arm.activeOnDay7,
  'day7Rate': arm.day7Rate,
  'day7Wilson95': arm.day7Interval?.toJson(),
  'day7WindowPending': arm.day7WindowPending,
};

int _writeError(bool jsonMode, StringSink out, StringSink err, String message) {
  if (jsonMode) {
    out.writeln(jsonEncode({'error': message, 'exitCode': reportExitBadInput}));
  } else {
    err.writeln('error: $message');
  }
  return reportExitBadInput;
}

const String _helpText = '''
Usage: dart run tool/beta/reminder_experiment_report.dart [options] <export.json>...

Reads one or more local retention logs copied from Profile -> Privacy ->
Copy usage log and prints the pre-registered T5.6 reminder-copy metrics per
arm. Nothing is uploaded and no data is written.

Options:
  --json          Print one JSON object on stdout.
  --now <time>    UTC ISO-8601 analysis time (default: now). Use a fixed value
                  to reproduce an analysis.
  -h, --help      Show this help.

Exit codes:
  0  The sample is usable for the pre-registered decision.
  1  The analysis ran, but the sample is insufficient.
  2  Bad input: no usable logs or an invalid option.
''';
