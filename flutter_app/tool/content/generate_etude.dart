import 'dart:convert';
import 'dart:io';

import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/content/sight_reading/etude_generator.dart';
import 'package:hear_me_out/core/music/playability.dart';

const String usage = '''
Usage: dart run tool/content/generate_etude.dart --level <1-5> --seed <int> [options]

Generates one deterministic sight-reading etude candidate and writes it to a
scratch folder. It never writes to the reviewed assets under
assets/content/etudes/.

Options:
  --level <1-5>   Level grammar to use. Required.
  --seed <int>    Non-negative seed. Required. The same level and seed always
                  produce the same candidate.
  --out <dir>     Output folder. Default: build/generated_etudes
  --help, -h      Show this help.

Exit codes:
  0  Candidate written and valid.
  1  Candidate failed validation; nothing was written.
  2  Usage, invalid level/seed, or file-system error.
''';

void main(List<String> args) {
  exitCode = runCli(args);
}

/// Runs the generator without touching process globals so tests can call it.
///
/// [out] receives normal output, [err] receives usage and file errors.
/// [workingDirectory] overrides `Directory.current` for tests. Candidates are
/// always validated before the file is written.
int runCli(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  String? workingDirectory,
}) {
  final sink = out ?? stdout;
  final errorSink = err ?? stderr;

  int? level;
  int? seed;
  String? outPath;

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--help' || arg == '-h') {
      sink.writeln(usage);
      return 0;
    }
    if (arg == '--level' || arg == '-l') {
      if (index + 1 >= args.length) {
        errorSink.writeln('Missing value for $arg.');
        errorSink.writeln(usage);
        return 2;
      }
      level = int.tryParse(args[++index]);
      if (level == null) {
        errorSink.writeln('Invalid --level value: ${args[index]}');
        return 2;
      }
      continue;
    }
    if (arg == '--seed' || arg == '-s') {
      if (index + 1 >= args.length) {
        errorSink.writeln('Missing value for $arg.');
        errorSink.writeln(usage);
        return 2;
      }
      seed = int.tryParse(args[++index]);
      if (seed == null) {
        errorSink.writeln('Invalid --seed value: ${args[index]}');
        return 2;
      }
      continue;
    }
    if (arg == '--out' || arg == '-o') {
      if (index + 1 >= args.length) {
        errorSink.writeln('Missing value for $arg.');
        errorSink.writeln(usage);
        return 2;
      }
      outPath = args[++index];
      continue;
    }
    errorSink.writeln('Unknown option: $arg');
    errorSink.writeln(usage);
    return 2;
  }

  if (level == null || seed == null) {
    errorSink.writeln('Both --level and --seed are required.');
    errorSink.writeln(usage);
    return 2;
  }

  final EtudeGenerator generator;
  try {
    generator = EtudeGenerator(level: level, seed: seed);
  } on ArgumentError catch (error) {
    errorSink.writeln(error.message);
    return 2;
  }

  final targetPath = outPath ?? 'build/generated_etudes';
  if (_isReviewedAssetPath(targetPath, workingDirectory)) {
    errorSink.writeln(
      'Refusing to write into $targetPath: generated candidates must not '
      'enter the reviewed asset library.',
    );
    return 2;
  }

  final GeneratedEtude etude;
  try {
    etude = generator.generate();
  } on StateError catch (error) {
    errorSink.writeln('Generation failed: ${error.message}');
    return 1;
  }

  final issues = <String>[
    for (final issue in etude.score.validate())
      if (issue.isError) issue.toString(),
    for (final issue in AuthoringValidator(etude.score).validate())
      if (issue.isError || issue.isWarning) issue.toString(),
    for (final issue in PlayabilityValidator(
      etude.score,
      limits: etude.spec.playabilityLimits,
    ).validate())
      if (issue.isError || issue.isWarning) issue.toString(),
  ];
  if (issues.isNotEmpty) {
    errorSink.writeln('Candidate ${etude.candidateId} failed validation:');
    for (final issue in issues) {
      errorSink.writeln('  $issue');
    }
    errorSink.writeln('Nothing was written.');
    return 1;
  }

  final root = workingDirectory ?? Directory.current.path;
  final directory = Directory(_join(root, targetPath));
  final file = File(
    '${directory.path}${Platform.pathSeparator}${etude.candidateId}.json',
  );
  try {
    directory.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(etude.toAuthoringJson()),
    );
  } on FileSystemException catch (error) {
    errorSink.writeln('Cannot write ${file.path}: ${error.message}');
    return 2;
  }

  final score = etude.score;
  final bars = score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.bars);
  sink.writeln('Candidate: ${etude.candidateId}');
  sink.writeln(
    'Level: ${etude.level} (stage ${etude.spec.stage}, ${etude.spec.tier})',
  );
  sink.writeln('Seed: ${etude.seed}');
  sink.writeln('Key: ${score.piece.key}');
  sink.writeln('Meter: ${score.piece.timeSignature}');
  sink.writeln('Phrases: ${score.phrases.length}');
  sink.writeln('Bars: $bars');
  sink.writeln('Tempo: ${score.phrases.first.targetTempoBpm} BPM');
  sink.writeln('Status: pending-human (awaiting human pedagogue review)');
  sink.writeln('Wrote: ${file.path}');
  sink.writeln(
    'This is a candidate, not reviewed library content. The 60 reviewed '
    'etudes remain the shipped core. A human pedagogue must approve it before '
    'promotion.',
  );
  return 0;
}

/// Joins paths without importing `package:path`.
String _join(String root, String relative) {
  if (relative.isEmpty) return root;
  if (relative.startsWith('/') ||
      relative.startsWith('\\') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(relative)) {
    return relative;
  }
  final separator = Platform.pathSeparator;
  final trimmedRoot = root.endsWith(separator)
      ? root.substring(0, root.length - 1)
      : root;
  return '$trimmedRoot$separator$relative';
}

bool _isReviewedAssetPath(String path, String? workingDirectory) {
  final root = workingDirectory ?? Directory.current.path;
  final absolute = File(_join(root, path)).absolute.path;
  final normalized = absolute.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/assets/') ||
      normalized.endsWith('/assets') ||
      normalized.contains('/assets/content/etudes');
}
