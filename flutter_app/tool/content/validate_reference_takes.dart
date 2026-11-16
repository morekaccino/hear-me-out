import 'dart:convert';
import 'dart:io';

import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/content/reference_take.dart';
import 'package:hear_me_out/core/content/reference_take_validator.dart';

const String usage = '''
Usage: dart run tool/content/validate_reference_takes.dart <manifest.json> [options]

Validates a human reference-take manifest against the ten launch pieces.

Options:
  --json              Print one JSON object: {valid, errors, warnings, issues}.
  --require-complete  Require one target and one slow take for every launch
                      phrase (10 pieces x 4 phrases x 2 variants = 80 takes).
                      The default accepts a subset so recordings can arrive
                      incrementally.
  --help, -h          Show this help.

Exit codes:
  0  No errors.
  1  The manifest has errors or cannot be parsed.
  2  Usage error, unreadable file, or unreadable piece registry.
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
  var requireComplete = false;
  String? path;

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      sink.writeln(usage);
      return 0;
    } else if (arg == '--json') {
      jsonOutput = true;
    } else if (arg == '--require-complete') {
      requireComplete = true;
    } else if (arg.startsWith('-')) {
      errorSink.writeln('Unknown option: $arg');
      errorSink.writeln(usage);
      return 2;
    } else if (path != null) {
      errorSink.writeln('Only one manifest file can be validated per run.');
      return 2;
    } else {
      path = arg;
    }
  }

  if (path == null) {
    errorSink.writeln('Missing manifest file.');
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

  ReferenceTakeManifest? manifest;
  ReferenceTakeIssue? parseIssue;
  Object? decoded;
  var decodedOk = false;
  try {
    decoded = jsonDecode(source);
    decodedOk = true;
  } on FormatException catch (error) {
    parseIssue = ReferenceTakeIssue(
      code: 'referenceTake.invalidJson',
      path: '<document>',
      message: error.message.toString(),
    );
  }

  if (decodedOk) {
    if (decoded is! Map) {
      parseIssue = const ReferenceTakeIssue(
        code: 'referenceTake.invalidDocument',
        path: '<document>',
        message: 'The manifest must contain a JSON object.',
      );
    } else {
      try {
        final json = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
        manifest = ReferenceTakeManifest.fromJson(json);
      } on ReferenceTakeFormatException catch (error) {
        parseIssue = ReferenceTakeIssue(
          code: error.code,
          path: error.path,
          message: error.message.toString(),
        );
      }
    }
  }

  final issues = <ReferenceTakeIssue>[];
  if (parseIssue != null) issues.add(parseIssue);

  if (manifest != null) {
    final ReferenceTakeCatalog catalog;
    try {
      catalog = _loadCatalog();
    } on FileSystemException catch (error) {
      errorSink.writeln('Cannot read the piece registry: ${error.message}');
      return 2;
    } on FormatException catch (error) {
      errorSink.writeln('Cannot read the piece registry: ${error.message}');
      return 2;
    }
    issues.addAll(
      ReferenceTakeValidator(catalog)
          .validate(manifest, requireComplete: requireComplete),
    );
  }

  final errors = issues.length;
  final valid = errors == 0;

  if (jsonOutput) {
    sink.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'valid': valid,
        'errors': errors,
        'warnings': 0,
        'issues': <Map<String, dynamic>>[
          for (final issue in issues)
            <String, dynamic>{
              'severity': 'error',
              'code': issue.code,
              'path': issue.path,
              'message': issue.message,
            },
        ],
      }),
    );
    return valid ? 0 : 1;
  }

  for (final issue in issues) {
    sink.writeln('error ${issue.code} at ${issue.path}: ${issue.message}');
  }
  sink.writeln(
    '${valid ? 'PASS' : 'FAIL'} $path: $errors error(s), 0 warning(s).',
  );
  return valid ? 0 : 1;
}

/// Builds the catalog from the ten launch arrangements, never from a copy of
/// the phrase list. A missing or mismatched arrangement is a tool error.
ReferenceTakeCatalog _loadCatalog() {
  final phrases = <ReferenceTakePhrase>[];
  for (final launch in launchPieces) {
    final path =
        'assets/content/pieces/${launch.tier.wireName}/${launch.piece.id}.json';
    final source = File(path).readAsStringSync();
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw FormatException('$path is not a JSON object');
    }
    final document = parseAuthoringDocument(Map<String, dynamic>.from(decoded));
    if (document.score.piece.id != launch.piece.id) {
      throw FormatException(
        '$path declares piece "${document.score.piece.id}", expected '
        '"${launch.piece.id}"',
      );
    }
    for (final phrase in document.score.phrases) {
      phrases.add(
        ReferenceTakePhrase(
          pieceId: launch.piece.id,
          phraseId: phrase.id,
          targetTempoBpm: phrase.targetTempoBpm,
        ),
      );
    }
  }
  return MapReferenceTakeCatalog(phrases);
}
