// Standalone tests for tool/corpus/validate_labels.dart.
//
// Run from the repository root:
//
//     dart run test/corpus_label_test.dart
//
// The repository has no root pubspec and this ticket must not add a package
// dependency, so this file uses a small self-contained harness instead of
// package:test. It still fails with a non-zero exit code when an assertion
// fails.

import 'dart:convert';
import 'dart:io';

import '../tool/corpus/validate_labels.dart';

int _passed = 0;
int _failed = 0;

void main() {
  final root = _repoRoot();
  final validPath = '$root/test/fixtures/corpus/valid_labels.json';
  final invalidPath = '$root/test/fixtures/corpus/invalid_labels.json';
  final manifestPath = '$root/test/fixtures/corpus/manifest.json';
  final valid = _readJson(validPath);
  final manifest = _readJson(manifestPath);

  _test('valid fixture passes', () {
    final report = validateLabel(valid, source: validPath);
    _expect(report.isValid, 'expected no errors, got ${report.errors}');
    _expect(report.takeId == 'p01-pixel-6a-quiet-001', 'takeId not read');
    _expect(report.warnings.isEmpty, 'expected no warnings');
  });

  _test('missing required field is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    label.remove('tempoBpm');
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.tempoBpm', 'missing required field'),
      'expected a missing-field error at \$.tempoBpm, got ${report.errors}',
    );
  });

  _test('overlapping monophonic events are rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    final second = target[1] as Map<String, Object?>;
    second['onsetSeconds'] = 4.5;
    second['onsetSample'] = 216000;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[1].onsetSeconds', 'overlaps'),
      'expected an overlap error, got ${report.errors}',
    );
  });

  _test('wrong written/sounding pair is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['soundingMidi'] = 64;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].soundingMidi', 'one octave below'),
      'expected an octave error, got ${report.errors}',
    );
  });

  _test('out-of-range fret is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['fret'] = 99;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].fret', 'at most 24'),
      'expected a fret error, got ${report.errors}',
    );
  });

  _test('string/fret combination must sound the labelled MIDI note', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['fret'] = 1;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].soundingMidi', 'string 4 fret 1'),
      'expected a string/fret error, got ${report.errors}',
    );
  });

  _test('written note must match the string/fret octave', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    final first = target[0] as Map<String, Object?>;
    first['writtenNote'] = 'E5';
    first['soundingMidi'] = 52;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].writtenNote', 'written MIDI'),
      'expected a written/position mismatch, got ${report.errors}',
    );
  });

  _test('out-of-range string is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['string'] = 7;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].string', 'at most 6'),
      'expected a string error, got ${report.errors}',
    );
  });

  _test('NaN onset time is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['onsetSeconds'] = double.nan;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].onsetSeconds', 'finite number'),
      'expected a non-finite error, got ${report.errors}',
    );
  });

  _test('infinite duration is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['durationSeconds'] = double.infinity;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].durationSeconds', 'finite number'),
      'expected a non-finite error, got ${report.errors}',
    );
  });

  _test('onsetSeconds must agree with onsetSample', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['onsetSeconds'] = 4.3;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].onsetSeconds', 'onsetSample'),
      'expected a sample/second mismatch, got ${report.errors}',
    );
  });

  _test('unknown note id is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['writtenNote'] = 'H4';
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].writtenNote', 'written pitch'),
      'expected a note-id error, got ${report.errors}',
    );
  });

  _test('non-contiguous target indices are rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[3] as Map<String, Object?>)['index'] = 9;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[3].index', 'list position 3'),
      'expected an index error, got ${report.errors}',
    );
  });

  _test('phraseNoteCount must match target length', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['phraseNoteCount'] = 4;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.phraseNoteCount', 'target has 8 events'),
      'expected a phrase-count error, got ${report.errors}',
    );
  });

  _test('unsupported schema version is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['schemaVersion'] = 2;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.schemaVersion', 'unsupported'),
      'expected a schema-version error, got ${report.errors}',
    );
  });

  _test('reviewer must differ from the primary labeler', () {
    final label = _copy(valid) as Map<String, Object?>;
    final expert = label['expert'] as Map<String, Object?>;
    expert['reviewedBy'] = 'expert-a';
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.expert.reviewedBy', 'must differ'),
      'expected an independent-review error, got ${report.errors}',
    );
  });

  _test('correct outcome cannot fail timing', () {
    final label = _copy(valid) as Map<String, Object?>;
    final expert = label['expert'] as Map<String, Object?>;
    expert['timingOk'] = false;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.expert.timingOk', 'must be true'),
      'expected a timing error, got ${report.errors}',
    );
  });

  _test('incomplete take cannot be labelled incorrect', () {
    final label = _copy(valid) as Map<String, Object?>;
    final expert = label['expert'] as Map<String, Object?>;
    expert['outcome'] = 'incorrect';
    expert['completeness'] = 'incomplete';
    expert['noteAccuracy'] = 0.5;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.expert.outcome', 'indeterminate'),
      'expected an incomplete-take error, got ${report.errors}',
    );
  });

  _test('keepRawAudio requires audioCapture', () {
    final label = _copy(valid) as Map<String, Object?>;
    final consent = label['consent'] as Map<String, Object?>;
    consent['audioCapture'] = false;
    consent['keepRawAudio'] = true;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.consent.keepRawAudio', 'cannot be true'),
      'expected a consent error, got ${report.errors}',
    );
  });

  _test('unknown fields are rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['extra'] = 'not in schema v1';
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.extra', 'unknown field'),
      'expected an unknown-field error, got ${report.errors}',
    );
  });

  _test('valid manifest passes with warnings', () {
    final report = validateManifest(manifest, source: manifestPath);
    _expect(report.isValid, 'expected no errors, got ${report.errors}');
    _expect(
      report.summary['acceptedTakeCount'] == 1,
      'expected one accepted take',
    );
    _expect(
      report.warnings.isNotEmpty,
      'fixture should warn about corpus size',
    );
  });

  _test('manifest rejects an unknown player reference', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['playerId'] = 'p99';
    final report = validateManifest(copy);
    _expect(
      _hasError(report, r'$.takes[0].playerId', 'unknown player'),
      'expected an unknown-player error, got ${report.errors}',
    );
  });

  _test('manifest rejects absolute or escaping file paths', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['labelFile'] = '../labels/x.json';
    final report = validateManifest(copy);
    _expect(
      _hasError(report, r'$.takes[0].labelFile', '..'),
      'expected a relative-path error, got ${report.errors}',
    );
  });

  _test('label must be listed in the manifest', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['takeId'] = 'p01-pixel-6a-quiet-999';
    final report = validateLabel(valid);
    crossCheckLabelAndManifest(valid, copy, report);
    _expect(
      _hasError(report, r'$.takeId', 'not listed in the manifest'),
      'expected a manifest membership error, got ${report.errors}',
    );
  });

  _test('label and manifest fields must agree', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['condition'] = 'room-noise';
    final report = validateLabel(valid);
    crossCheckLabelAndManifest(valid, copy, report);
    _expect(
      _hasError(report, r'$.condition', 'manifest says'),
      'expected a manifest mismatch, got ${report.errors}',
    );
  });

  _test('CLI --json prints clean JSON for a valid label', () {
    final result = _runCli(root, ['--json', validPath]);
    _expect(result.exitCode == 0, 'expected exit 0, got ${result.exitCode}');
    final output = result.stdout as String;
    _expect(!output.contains('ERROR'), 'stdout must not mix human text');
    final decoded = jsonDecode(output) as Map<String, Object?>;
    _expect(decoded['valid'] == true, 'expected valid true');
    final files = decoded['files'] as List<Object?>;
    final file = files.single as Map<String, Object?>;
    _expect(file['kind'] == 'label', 'expected a label file report');
    _expect((file['errors'] as List<Object?>).isEmpty, 'expected no errors');
  });

  _test('CLI exits non-zero and prints errors for an invalid label', () {
    final result = _runCli(root, ['--json', invalidPath]);
    _expect(result.exitCode == 1, 'expected exit 1, got ${result.exitCode}');
    final decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;
    _expect(decoded['valid'] == false, 'expected valid false');
    final files = decoded['files'] as List<Object?>;
    final file = files.single as Map<String, Object?>;
    _expect(
      (file['errors'] as List<Object?>).isNotEmpty,
      'expected errors in JSON output',
    );
  });

  _test('CLI validates a label together with a manifest', () {
    final result = _runCli(root, [
      '--json',
      validPath,
      '--manifest',
      manifestPath,
    ]);
    _expect(result.exitCode == 0, 'expected exit 0, got ${result.exitCode}');
    final decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;
    final files = decoded['files'] as List<Object?>;
    _expect(files.length == 2, 'expected label and manifest reports');
    final manifestReport = files.cast<Map<String, Object?>>().firstWhere(
      (file) => file['kind'] == 'manifest',
    );
    final summary = manifestReport['summary'] as Map<String, Object?>;
    _expect(summary['acceptedTakeCount'] == 1, 'expected one accepted take');
  });

  _test('CLI --help exits successfully', () {
    final result = _runCli(root, ['--help']);
    _expect(result.exitCode == 0, 'expected exit 0, got ${result.exitCode}');
    _expect(
      (result.stdout as String).contains('Usage:'),
      'expected usage text',
    );
  });

  _test('CLI without arguments exits with a usage error', () {
    final result = _runCli(root, const []);
    _expect(result.exitCode == 2, 'expected exit 2, got ${result.exitCode}');
  });

  _test('CLI reports a missing file as an I/O error', () {
    final result = _runCli(root, ['$root/test/fixtures/corpus/missing.json']);
    _expect(result.exitCode == 2, 'expected exit 2, got ${result.exitCode}');
    _expect(
      (result.stdout as String).contains('cannot read file'),
      'expected a readable I/O error',
    );
  });

  stdout.writeln('\n$_passed passed, $_failed failed');
  if (_failed > 0) {
    exitCode = 1;
  }
}

void _test(String name, void Function() body) {
  try {
    body();
    _passed++;
    stdout.writeln('PASS  $name');
  } on _TestFailure catch (error) {
    _failed++;
    stdout.writeln('FAIL  $name');
    stdout.writeln('      $error');
  } catch (error, stack) {
    _failed++;
    stdout.writeln('FAIL  $name');
    stdout.writeln('      unexpected error: $error');
    stdout.writeln(stack);
  }
}

class _TestFailure implements Exception {
  const _TestFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

void _expect(bool condition, String message) {
  if (!condition) throw _TestFailure(message);
}

bool _hasError(ValidationReport report, String path, String messagePart) {
  return report.errors.any(
    (error) => error.path == path && error.message.contains(messagePart),
  );
}

String _repoRoot() {
  final current = Directory.current.absolute.path;
  if (File('$current/test/fixtures/corpus/valid_labels.json').existsSync()) {
    return current;
  }
  final scriptDirectory = File.fromUri(Platform.script).parent.parent.path;
  if (File('$scriptDirectory/test/fixtures/corpus/valid_labels.json')
      .existsSync()) {
    return scriptDirectory;
  }
  throw StateError('Run this test from the repository root.');
}

Map<String, Object?> _readJson(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  return (decoded as Map).cast<String, Object?>();
}

Object? _copy(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _copy(entry.value),
    };
  }
  if (value is List) {
    return <Object?>[for (final item in value) _copy(item)];
  }
  return value;
}

ProcessResult _runCli(String root, List<String> arguments) {
  return Process.runSync(Platform.resolvedExecutable, [
    'run',
    '$root/tool/corpus/validate_labels.dart',
    ...arguments,
  ], workingDirectory: root);
}
