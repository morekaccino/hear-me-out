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

  _test('null top-level field is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['takeId'] = null;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.takeId', 'must not be null'),
      'expected a null error at \$.takeId, got ${report.errors}',
    );
  });

  _test('null target object is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['target'] = null;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target', 'must not be null'),
      'expected a null error at \$.target, got ${report.errors}',
    );
  });

  _test('null nested target field is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[0] as Map<String, Object?>)['writtenNote'] = null;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.target[0].writtenNote', 'must not be null'),
      'expected a nested null error, got ${report.errors}',
    );
  });

  _test('null nested expert field is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final expert = label['expert'] as Map<String, Object?>;
    expert['outcome'] = null;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.expert.outcome', 'must not be null'),
      'expected a nested null error, got ${report.errors}',
    );
  });

  _test('null nested consent field is rejected', () {
    final label = _copy(valid) as Map<String, Object?>;
    final consent = label['consent'] as Map<String, Object?>;
    consent['audioCapture'] = null;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.consent.audioCapture', 'must not be null'),
      'expected a nested null error, got ${report.errors}',
    );
  });

  _test('null manifest collections and schemaVersion are rejected', () {
    for (final field in const [
      'schemaVersion',
      'players',
      'devices',
      'takes',
    ]) {
      final copy = _copy(manifest) as Map<String, Object?>;
      copy[field] = null;
      final report = validateManifest(copy);
      _expect(
        _hasError(report, '\$.$field', 'must not be null'),
        'expected a null error at \$.$field, got ${report.errors}',
      );
    }
  });

  _test('low confidence cannot be correct and complete', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[2] as Map<String, Object?>)['confidence'] = 0.4;
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.expert.outcome', 'must be indeterminate'),
      'expected the outcome to be forced indeterminate, got ${report.errors}',
    );
    _expect(
      _hasError(report, r'$.expert.completeness', 'must be incomplete'),
      'expected completeness to be forced incomplete, got ${report.errors}',
    );
    _expect(!report.isValid, 'expected the label to be invalid');
  });

  _test('low confidence is valid as indeterminate and incomplete', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[2] as Map<String, Object?>)['confidence'] = 0.4;
    final expert = label['expert'] as Map<String, Object?>;
    expert['outcome'] = 'indeterminate';
    expert['completeness'] = 'incomplete';
    expert['noteAccuracy'] = 0.875;
    final report = validateLabel(label);
    _expect(
      report.isValid,
      'expected a valid indeterminate take, got ${report.errors}',
    );
    _expect(report.warnings.isNotEmpty, 'expected the confidence warning');
  });

  _test('more than 20% low confidence warns the take is unusable', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[2] as Map<String, Object?>)['confidence'] = 0.4;
    (target[3] as Map<String, Object?>)['confidence'] = 0.4;
    final expert = label['expert'] as Map<String, Object?>;
    expert['outcome'] = 'indeterminate';
    expert['completeness'] = 'incomplete';
    expert['noteAccuracy'] = 0.75;
    final report = validateLabel(label);
    _expect(
      report.warnings.any(
        (warning) => warning.message.contains('more than 20%'),
      ),
      'expected an unusable-take warning, got ${report.warnings}',
    );
  });

  _test('confidence exactly 0.6 is determinate', () {
    final label = _copy(valid) as Map<String, Object?>;
    final target = label['target'] as List<Object?>;
    (target[2] as Map<String, Object?>)['confidence'] = 0.6;
    final report = validateLabel(label);
    _expect(
      report.isValid,
      'expected 0.6 to be determinate, got ${report.errors}',
    );
  });

  _test('takeId must match player/device/condition prefix', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['takeId'] = 'p01-iphone-13-quiet-001';
    final report = validateLabel(label);
    _expect(
      _hasError(report, r'$.takeId', 'must start with'),
      'expected a takeId prefix error, got ${report.errors}',
    );
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

  _test('manifest takeId must match player/device/condition prefix', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['takeId'] = 'p01-iphone-13-quiet-001';
    final report = validateManifest(copy);
    _expect(
      _hasError(report, r'$.takes[0].takeId', 'must start with'),
      'expected a manifest takeId prefix error, got ${report.errors}',
    );
  });

  _test('manifest file paths must match the folder layout', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['labelFile'] =
        'p01/pixel-6a/quiet/other.json';
    final report = validateManifest(copy);
    _expect(
      _hasError(report, r'$.takes[0].labelFile', 'folder layout'),
      'expected a folder-layout error, got ${report.errors}',
    );
  });

  _test('device class must be compatible with platform', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final devices = copy['devices'] as List<Object?>;
    (devices[0] as Map<String, Object?>)['deviceClass'] = 'iphone';
    final report = validateManifest(copy);
    _expect(
      _hasError(report, r'$.devices[0].platform', 'requires platform'),
      'expected a device-class/platform error, got ${report.errors}',
    );
  });

  _test('tablet may use android or ios', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final devices = copy['devices'] as List<Object?>;
    (devices[0] as Map<String, Object?>)['deviceClass'] = 'tablet';
    final report = validateManifest(copy);
    _expect(
      report.isValid,
      'expected a tablet/android manifest to be valid, got ${report.errors}',
    );
  });

  _test('label guitar must match the player registration', () {
    final label = _copy(valid) as Map<String, Object?>;
    label['guitar'] = 'steel';
    final report = validateLabel(label);
    crossCheckLabelAndManifest(label, manifest, report);
    _expect(
      _hasError(report, r'$.guitar', 'registered as'),
      'expected a guitar mismatch, got ${report.errors}',
    );
  });

  _test('a player registered as both accepts either guitar', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final players = copy['players'] as List<Object?>;
    (players[0] as Map<String, Object?>)['guitar'] = 'both';
    final label = _copy(valid) as Map<String, Object?>;
    label['guitar'] = 'steel';
    final report = validateLabel(label);
    crossCheckLabelAndManifest(label, copy, report);
    _expect(
      !report.errors.any((error) => error.path == r'$.guitar'),
      'expected both to accept steel, got ${report.errors}',
    );
  });

  _test('failed manifest status forces indeterminate and incomplete', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final takes = copy['takes'] as List<Object?>;
    (takes[0] as Map<String, Object?>)['status'] = 'failed';
    final report = validateLabel(valid);
    crossCheckLabelAndManifest(valid, copy, report);
    _expect(
      _hasError(report, r'$.expert.outcome', 'must be indeterminate'),
      'expected a failed-status outcome error, got ${report.errors}',
    );
    _expect(
      _hasError(report, r'$.expert.completeness', 'must be incomplete'),
      'expected a failed-status completeness error, got ${report.errors}',
    );
  });

  _test('decimal playing levels still count toward the mix', () {
    final copy = _copy(manifest) as Map<String, Object?>;
    final players = copy['players'] as List<Object?>;
    (players[0] as Map<String, Object?>)['playingLevel'] = 1.0;
    (players[1] as Map<String, Object?>)['playingLevel'] = 2.0;
    players.add({
      'playerId': 'p03',
      'segment': 'returner',
      'guitar': 'nylon',
      'playingLevel': 3.0,
    });
    final report = validateManifest(copy);
    _expect(
      !report.warnings.any(
        (warning) => warning.message.contains('playing levels'),
      ),
      'expected decimal levels to count, got ${report.warnings}',
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

  _test('CLI validates a manifest without a label', () {
    final result = _runCli(root, ['--json', '--manifest', manifestPath]);
    _expect(result.exitCode == 0, 'expected exit 0, got ${result.exitCode}');
    final decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;
    final files = decoded['files'] as List<Object?>;
    final report = files.single as Map<String, Object?>;
    _expect(report['kind'] == 'manifest', 'expected a manifest report');
    _expect(report['valid'] == true, 'expected the manifest to be valid');
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
