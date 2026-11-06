import 'dart:convert';
import 'dart:io';

import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/score.dart';

const String usage = '''
Usage: dart run tool/content/validate_piece.dart <piece.json> [options]

Validates a hand-authored score against the V1 monophonic content rules.

Options:
  --json      Print one JSON object: {valid, errors, warnings, issues}.
  --strict    Treat warnings as errors (exit 1).
  --summary   Print piece title, tier/stage, phrase count, bars, tempo,
              range, and note count.
  --help, -h  Show this help.

Exit codes:
  0  No errors (warnings are allowed unless --strict is set).
  1  The score has errors, a warning under --strict, or cannot be parsed.
  2  Usage or file-read error.
''';

void main(List<String> args) {
  exitCode = runCli(args);
}

/// Runs the validator without touching Flutter or process globals.
///
/// Tests call this with [StringBuffer] sinks. [out] receives normal output and
/// [err] receives usage or file-read errors.
int runCli(List<String> args, {StringSink? out, StringSink? err}) {
  final sink = out ?? stdout;
  final errorSink = err ?? stderr;

  var jsonOutput = false;
  var strict = false;
  var summary = false;
  String? path;

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      sink.writeln(usage);
      return 0;
    } else if (arg == '--json') {
      jsonOutput = true;
    } else if (arg == '--strict') {
      strict = true;
    } else if (arg == '--summary') {
      summary = true;
    } else if (arg.startsWith('-')) {
      errorSink.writeln('Unknown option: $arg');
      errorSink.writeln(usage);
      return 2;
    } else if (path != null) {
      errorSink.writeln('Only one score file can be validated per run.');
      return 2;
    } else {
      path = arg;
    }
  }

  if (path == null) {
    errorSink.writeln('Missing score file.');
    errorSink.writeln(usage);
    return 2;
  }

  final String source;
  try {
    source = File(path).readAsStringSync();
  } on FileSystemException catch (error) {
    errorSink.writeln('Cannot read $path: ${error.message}');
    return 2;
  } on FormatException catch (error) {
    errorSink.writeln('Cannot read $path: ${error.message}');
    return 2;
  }

  AuthoringDocument? document;
  ScoreIssue? parseIssue;
  Object? decoded;
  var decodedOk = false;
  try {
    decoded = jsonDecode(source);
    decodedOk = true;
  } on FormatException catch (error) {
    parseIssue = ScoreIssue(
      severity: ScoreIssueSeverity.error,
      code: 'authoring.invalidJson',
      message: error.message.toString(),
      path: '<document>',
    );
  }

  if (decodedOk) {
    try {
      if (decoded is! Map) {
        parseIssue = const ScoreIssue(
          severity: ScoreIssueSeverity.error,
          code: 'authoring.invalidDocument',
          message: 'The score file must contain a JSON object.',
          path: '<document>',
        );
      } else {
        final json = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        document = parseAuthoringDocument(json);
      }
    } on AuthoringFormatException catch (error) {
      parseIssue = ScoreIssue(
        severity: ScoreIssueSeverity.error,
        code: error.code,
        message: error.message,
        path: error.path,
      );
    } on FormatException catch (error) {
      parseIssue = ScoreIssue(
        severity: ScoreIssueSeverity.error,
        code: 'authoring.parseError',
        message: _stripPath(error.message.toString()),
        path: _pathFrom(error),
      );
    }
  }

  final issues = <ScoreIssue>[];
  if (parseIssue != null) issues.add(parseIssue);

  _ScoreSummary? summaryResult;
  if (document != null) {
    issues.addAll(AuthoringValidator(document.score).validate());
    if (summary) {
      final phraseCountIssue = _phraseCountIssue(document);
      if (phraseCountIssue != null) issues.add(phraseCountIssue);
      summaryResult = _ScoreSummary.from(document);
    }
  }

  final errors = issues.where((issue) => issue.isError).length;
  final warnings = issues.where((issue) => issue.isWarning).length;
  final valid = errors == 0 && (!strict || warnings == 0);

  if (jsonOutput) {
    final payload = <String, dynamic>{
      'valid': valid,
      'errors': errors,
      'warnings': warnings,
      'issues': <Map<String, dynamic>>[
        for (final issue in issues) _issueToJson(issue),
      ],
      if (summaryResult != null) 'summary': summaryResult.toJson(),
    };
    sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    return valid ? 0 : 1;
  }

  if (summaryResult != null) {
    summaryResult.writeTo(sink);
  }
  for (final issue in issues) {
    sink.writeln(
      '${issue.severity.name} ${issue.code} at ${issue.path}: '
      '${issue.message}',
    );
  }
  sink.writeln(
    '${valid ? 'PASS' : 'FAIL'} $path: $errors error(s), '
    '$warnings warning(s).',
  );
  return valid ? 0 : 1;
}

Map<String, dynamic> _issueToJson(ScoreIssue issue) {
  return <String, dynamic>{
    'severity': issue.severity.name,
    'code': issue.code,
    'path': issue.path,
    'message': issue.message,
    if (issue.phraseId != null) 'phraseId': issue.phraseId,
    if (issue.eventIndex != null) 'eventIndex': issue.eventIndex,
  };
}

String _pathFrom(FormatException error) {
  final match = RegExp(r' at ([A-Za-z0-9_\[\]\.]+)$')
      .firstMatch(error.message.toString());
  return match?.group(1) ?? '<document>';
}

String _stripPath(String message) {
  final match = RegExp(r' at ([A-Za-z0-9_\[\]\.]+)$').firstMatch(message);
  if (match == null) return message;
  return message.substring(0, match.start);
}

ScoreIssue? _phraseCountIssue(AuthoringDocument document) {
  if (document.meta?.isEtude ?? false) return null;
  final count = document.score.phrases.length;
  if (count == 4) return null;
  return ScoreIssue(
    severity: ScoreIssueSeverity.warning,
    code: 'authoring.phraseCount',
    message:
        'V1 pieces use four phrases; this score has $count. '
        'Etudes may use fewer.',
    path: 'phrases',
  );
}

class _ScoreSummary {
  const _ScoreSummary({
    required this.title,
    required this.id,
    required this.composer,
    required this.kind,
    required this.tier,
    required this.stage,
    required this.phraseCount,
    required this.bars,
    required this.minTempo,
    required this.maxTempo,
    required this.minWrittenNote,
    required this.maxWrittenNote,
    required this.noteCount,
    required this.restCount,
  });

  final String title;
  final String id;
  final String composer;
  final String? kind;
  final String? tier;
  final int? stage;
  final int phraseCount;
  final int bars;
  final int? minTempo;
  final int? maxTempo;
  final Note? minWrittenNote;
  final Note? maxWrittenNote;
  final int noteCount;
  final int restCount;

  factory _ScoreSummary.from(AuthoringDocument document) {
    final score = document.score;
    var bars = 0;
    int? minTempo;
    int? maxTempo;
    Note? minWrittenNote;
    Note? maxWrittenNote;
    var noteCount = 0;
    var restCount = 0;

    for (final phrase in score.phrases) {
      if (phrase.bars > 0) bars += phrase.bars;
      final tempo = phrase.targetTempoBpm;
      minTempo = minTempo == null || tempo < minTempo ? tempo : minTempo;
      maxTempo = maxTempo == null || tempo > maxTempo ? tempo : maxTempo;
      for (final event in phrase.events) {
        if (event.isRest) {
          restCount++;
          continue;
        }
        noteCount++;
        final written = event.writtenNote;
        if (written == null) continue;
        if (minWrittenNote == null || written.midi < minWrittenNote.midi) {
          minWrittenNote = written;
        }
        if (maxWrittenNote == null || written.midi > maxWrittenNote.midi) {
          maxWrittenNote = written;
        }
      }
    }

    return _ScoreSummary(
      title: score.piece.title,
      id: score.piece.id,
      composer: score.piece.composer,
      kind: document.meta?.kind,
      tier: document.meta?.tier,
      stage: document.meta?.stage,
      phraseCount: score.phrases.length,
      bars: bars,
      minTempo: minTempo,
      maxTempo: maxTempo,
      minWrittenNote: minWrittenNote,
      maxWrittenNote: maxWrittenNote,
      noteCount: noteCount,
      restCount: restCount,
    );
  }

  String get tempoText {
    if (minTempo == null || maxTempo == null) return '-';
    if (minTempo == maxTempo) return '$minTempo BPM';
    return '$minTempo-$maxTempo BPM';
  }

  /// The sounding note keeps the authored letter and accidental so a B-flat
  /// exercise never prints A-sharp.
  Note _soundingNote(Note written) =>
      Note.spelledFromMidi(written.midi - 12, written.letter);

  String get writtenRangeText {
    if (minWrittenNote == null || maxWrittenNote == null) return '-';
    final low = minWrittenNote!.id;
    final high = maxWrittenNote!.id;
    return low == high ? low : '$low-$high';
  }

  String get soundingRangeText {
    if (minWrittenNote == null || maxWrittenNote == null) return '-';
    final low = _soundingNote(minWrittenNote!).id;
    final high = _soundingNote(maxWrittenNote!).id;
    return low == high ? low : '$low-$high';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'id': id,
      'composer': composer,
      'kind': kind,
      'tier': tier,
      'stage': stage,
      'phrases': phraseCount,
      'bars': bars,
      'tempoBpm': <String, dynamic>{'min': minTempo, 'max': maxTempo},
      'range': <String, dynamic>{
        'written': <String, dynamic>{
          'min': minWrittenNote?.id,
          'max': maxWrittenNote?.id,
        },
        'sounding': <String, dynamic>{
          'min': minWrittenNote == null
              ? null
              : _soundingNote(minWrittenNote!).id,
          'max': maxWrittenNote == null
              ? null
              : _soundingNote(maxWrittenNote!).id,
        },
      },
      'notes': noteCount,
      'rests': restCount,
    };
  }

  void writeTo(StringSink sink) {
    sink.writeln('Piece: $title');
    sink.writeln('Id: $id');
    sink.writeln('Composer: $composer');
    sink.writeln('Kind: ${kind ?? '-'}');
    sink.writeln('Tier: ${tier ?? '-'}');
    sink.writeln('Stage: ${stage ?? '-'}');
    sink.writeln('Phrases: $phraseCount');
    sink.writeln('Bars: $bars');
    sink.writeln('Tempo: $tempoText');
    sink.writeln(
      'Range: written $writtenRangeText, sounding $soundingRangeText',
    );
    sink.writeln('Notes: $noteCount');
    sink.writeln('Rests: $restCount');
    sink.writeln('');
  }
}
