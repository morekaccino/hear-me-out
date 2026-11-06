// Latency, clock, and bleed test rig for Hear Me Out.
//
// This tool is deliberately app-independent: it reads WAV files, measures
// them, and prints a pass/fail decision. It never opens a microphone.
//
// Run `dart run tool/latency_rig.dart --help` for the full contract.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:hear_me_out/core/audio/calibration.dart';
import 'package:hear_me_out/core/audio/wav.dart';

const int _exitPass = 0;
const int _exitGateFailure = 1;
const int _exitBadInput = 2;

Future<void> main(List<String> args) async {
  final jsonMode = args.contains('--json');
  try {
    final code = _run(args);
    exitCode = code;
  } on _UsageException catch (error) {
    _reportError(error.message, jsonMode);
    exitCode = _exitBadInput;
  } on FormatException catch (error) {
    _reportError(error.message, jsonMode);
    exitCode = _exitBadInput;
  } on ArgumentError catch (error) {
    _reportError(error.toString(), jsonMode);
    exitCode = _exitBadInput;
  } on FileSystemException catch (error) {
    _reportError('${error.message}: ${error.path}', jsonMode);
    exitCode = _exitBadInput;
  } on JsonUnsupportedObjectError catch (error) {
    _reportError('Invalid JSON: $error', jsonMode);
    exitCode = _exitBadInput;
  }
}

int _run(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _writeHelp();
    return _exitPass;
  }

  final command = args.first;
  final options = _Options(args.sublist(1));
  switch (command) {
    case 'loopback':
      return _runLoopback(options);
    case 'recall':
      return _runRecall(options);
    case 'bleed':
      return _runBleed(options);
    case 'generate':
      return _runGenerate(options);
    case 'simulate':
      return _runSimulate(options);
    default:
      throw _UsageException(
        'Unknown command "$command". Run --help to see the commands.',
      );
  }
}

int _runLoopback(_Options options) {
  options.rejectUnknown(const {
    'reference',
    'recorded',
    'json',
    'max-offset-ms',
    'max-drift-ms',
    'max-false-onsets',
    'max-recall-drop',
  });
  final referencePath = options.required('reference');
  final recordedPath = options.required('recorded');
  final gates = _gates(options);
  final reference = _readWav(referencePath);
  final recorded = _readWav(recordedPath);
  final report = analyzeLoopback(
    reference: reference,
    recorded: recorded,
    gates: gates,
  );

  if (options.flag('json')) {
    _writeJson({
      'command': 'loopback',
      'reference': referencePath,
      'recorded': recordedPath,
      ...report.toJson(),
      'gates': _gatesJson(gates),
    });
  } else {
    _writeLine('Hear Me Out latency rig - loopback');
    _writeLine('');
    _writeLine(_fileSummary('Reference', referencePath, reference));
    _writeLine(_fileSummary('Recorded', recordedPath, recorded));
    _writeLine(
      'Matched clicks: ${report.matchedOnsets}/${report.expectedOnsets} '
      '(${report.detectedOnsets} detected)',
    );
    _writeLine('');
    _writeLine(_tableHeader());
    _writeLine(
      _tableRow(
        'offset',
        '${_fmt(report.offsetMs)} ms',
        '<= ${_fmt(gates.maxOffsetMs)} ms',
        _passFail(_inside(report.offsetMs.abs(), gates.maxOffsetMs)),
      ),
    );
    _writeLine(
      _tableRow(
        'drift',
        '${_fmt(report.driftMsPer60s)} ms/60s',
        '<= ${_fmt(gates.maxDriftMsPer60s)} ms/60s',
        _passFail(_inside(report.driftMsPer60s.abs(), gates.maxDriftMsPer60s)),
      ),
    );
    _writeLine(
      _tableRow(
        'false onsets',
        '${_fmt(report.falseOnsetsPerMinute)} /min',
        'report only',
        '-',
      ),
    );
    _writeLine(
      _tableRow('note recall', _fmt(report.noteRecall, 3), 'report only', '-'),
    );
    _writeLine('');
    _writeLine(
      'timingUsable: ${report.timingUsable ? 'YES' : 'NO'} '
      '(offset + drift; bleed is a separate gate)',
    );
    if (report.failures.isNotEmpty) {
      _writeLine('Failures:');
      for (final failure in report.failures) {
        _writeLine('  - $failure');
      }
    }
  }

  return report.timingUsable ? _exitPass : _exitGateFailure;
}

int _runRecall(_Options options) {
  options.rejectUnknown(const {
    'recorded',
    'expected',
    'json',
    'max-false-onsets',
    'max-recall-drop',
    'match-window-ms',
  });
  final recordedPath = options.required('recorded');
  final expectedPath = options.required('expected');
  final gates = _gates(options);
  final recorded = _readWav(recordedPath);
  final expected = _readExpected(expectedPath);
  final report = analyzeNoteRecall(
    recorded: recorded,
    expectedOnsetSeconds: expected,
    gates: gates,
    matchWindowMs: options.number('match-window-ms', 50),
  );

  if (options.flag('json')) {
    _writeJson({
      'command': 'recall',
      'recorded': recordedPath,
      'expected': expectedPath,
      ...report.toJson(),
      'gates': _gatesJson(gates),
    });
  } else {
    final minimumRecall = 1.0 - gates.maxRecallDrop;
    _writeLine('Hear Me Out latency rig - note recall');
    _writeLine('');
    _writeLine(_fileSummary('Recorded', recordedPath, recorded));
    _writeLine('Expected onsets: ${expected.length}');
    _writeLine(
      'Matched onsets: ${report.matchedOnsets} '
      '(${report.detectedOnsets} detected)',
    );
    _writeLine('');
    _writeLine(_tableHeader());
    _writeLine(
      _tableRow(
        'note recall',
        _fmt(report.noteRecall, 4),
        '>= ${_fmt(minimumRecall, 3)}',
        _passFail(_atLeast(report.noteRecall, minimumRecall)),
      ),
    );
    _writeLine(
      _tableRow(
        'false onsets',
        '${_fmt(report.falseOnsetsPerMinute)} /min',
        '<= ${_fmt(gates.maxFalseOnsetsPerMinute)} /min',
        _passFail(
          _inside(report.falseOnsetsPerMinute, gates.maxFalseOnsetsPerMinute),
        ),
      ),
    );
    _writeLine(
      _tableRow(
        'mean latency',
        '${_fmt(report.meanLatencyMs)} ms',
        'report only',
        '-',
      ),
    );
    _writeLine('');
    _writeLine('recallUsable: ${report.recallUsable ? 'YES' : 'NO'}');
    if (report.failures.isNotEmpty) {
      _writeLine('Failures:');
      for (final failure in report.failures) {
        _writeLine('  - $failure');
      }
    }
  }

  return report.recallUsable ? _exitPass : _exitGateFailure;
}

int _runBleed(_Options options) {
  options.rejectUnknown(const {
    'speaker',
    'headphones',
    'expected',
    'json',
    'max-false-onsets',
    'max-recall-drop',
    'match-window-ms',
  });
  final speakerPath = options.required('speaker');
  final headphonePath = options.required('headphones');
  final expectedPath = options.required('expected');
  final gates = _gates(options);
  final speaker = _readWav(speakerPath);
  final headphones = _readWav(headphonePath);
  final expected = _readExpected(expectedPath);
  final report = analyzeBleed(
    speaker: speaker,
    headphones: headphones,
    expectedOnsetSeconds: expected,
    gates: gates,
    matchWindowMs: options.number('match-window-ms', 50),
  );

  if (options.flag('json')) {
    _writeJson({
      'command': 'bleed',
      'speaker': speakerPath,
      'headphones': headphonePath,
      'expected': expectedPath,
      ...report.toJson(),
      'gates': _gatesJson(gates),
    });
  } else {
    _writeLine('Hear Me Out latency rig - speaker vs headphone bleed');
    _writeLine('');
    _writeLine('Expected onsets: ${expected.length} (manifest $expectedPath)');
    _writeLine('');
    _writeLine(_tableHeader());
    _writeLine(
      _tableRow(
        'speaker recall',
        _fmt(report.speakerRecall, 4),
        'report only',
        '-',
      ),
    );
    _writeLine(
      _tableRow(
        'headphone recall',
        _fmt(report.headphoneRecall, 4),
        'report only',
        '-',
      ),
    );
    _writeLine(
      _tableRow(
        'recall drop',
        _fmt(report.recallDrop, 4),
        '<= ${_fmt(gates.maxRecallDrop, 3)}',
        _passFail(_inside(report.recallDrop, gates.maxRecallDrop)),
      ),
    );
    _writeLine(
      _tableRow(
        'speaker false onsets',
        '${_fmt(report.speakerFalseOnsetsPerMinute)} /min',
        '<= ${_fmt(gates.maxFalseOnsetsPerMinute)} /min',
        _passFail(
          _inside(
            report.speakerFalseOnsetsPerMinute,
            gates.maxFalseOnsetsPerMinute,
          ),
        ),
      ),
    );
    _writeLine('');
    _writeLine(
      'headphonesRequired: ${report.headphonesRequired ? 'YES' : 'NO'}',
    );
    if (report.failures.isNotEmpty) {
      _writeLine('Failures:');
      for (final failure in report.failures) {
        _writeLine('  - $failure');
      }
    }
  }

  return report.headphonesRequired ? _exitGateFailure : _exitPass;
}

int _runGenerate(_Options options) {
  options.rejectUnknown(const {
    'out',
    'expected-out',
    'duration',
    'interval',
    'sample-rate',
    'json',
  });
  final outputPath = options.required('out');
  final duration = options.number('duration', 30);
  final interval = options.number('interval', 1.0);
  final sampleRate = options.integer('sample-rate', 48000);
  if (sampleRate < 1000 || sampleRate > 384000) {
    throw _UsageException('--sample-rate must be between 1000 and 384000.');
  }
  if (duration <= 0) {
    throw _UsageException('--duration must be positive.');
  }
  if (interval <= 0.05) {
    throw _UsageException('--interval must be at least 0.05 seconds.');
  }

  final onsets = <double>[];
  final frames = (duration * sampleRate).round();
  final samples = Float64List(frames);
  for (var time = 0.5; time < duration - 0.1; time += interval) {
    onsets.add(_round(time, 6));
    _addClick(samples, sampleRate, (time * sampleRate).round());
  }
  final wav = WavData(sampleRate: sampleRate, channels: 1, samples: samples);
  File(outputPath).writeAsBytesSync(encodeWavPcm16(wav));

  final expectedPath = options.value('expected-out');
  if (expectedPath != null) {
    File(expectedPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({'onsetsSeconds': onsets})}\n',
    );
  }

  if (options.flag('json')) {
    _writeJson({
      'command': 'generate',
      'out': outputPath,
      'expectedOut': expectedPath,
      'onsets': onsets.length,
      'durationSeconds': _round(duration, 3),
      'intervalSeconds': _round(interval, 3),
      'sampleRate': sampleRate,
    });
  } else {
    _writeLine(
      'Wrote $outputPath: ${onsets.length} clicks, '
      '${_fmt(duration)} s, $sampleRate Hz.',
    );
    if (expectedPath != null) {
      _writeLine('Wrote $expectedPath.');
    }
  }
  return _exitPass;
}

int _runSimulate(_Options options) {
  options.rejectUnknown(const {
    'reference',
    'out',
    'offset-ms',
    'drift-ms-per-60s',
    'noise',
    'json',
  });
  final referencePath = options.required('reference');
  final outputPath = options.required('out');
  final offsetMs = options.number('offset-ms', 0);
  final driftMsPer60s = options.number('drift-ms-per-60s', 0);
  final noise = options.number('noise', 0);
  if (noise < 0) throw _UsageException('--noise must not be negative.');

  final reference = _readWav(referencePath);
  final simulated = _simulateTake(
    reference,
    offsetMs: offsetMs,
    driftMsPer60s: driftMsPer60s,
    noise: noise,
  );
  File(outputPath).writeAsBytesSync(encodeWavPcm16(simulated));

  if (options.flag('json')) {
    _writeJson({
      'command': 'simulate',
      'out': outputPath,
      'offsetMs': offsetMs,
      'driftMsPer60s': driftMsPer60s,
      'noise': noise,
    });
  } else {
    _writeLine(
      'Wrote $outputPath: offset ${_fmt(offsetMs)} ms, '
      'drift ${_fmt(driftMsPer60s)} ms/60s, noise ${_fmt(noise, 4)}.',
    );
  }
  return _exitPass;
}

WavData _simulateTake(
  WavData reference, {
  required double offsetMs,
  required double driftMsPer60s,
  required double noise,
}) {
  final rate = reference.sampleRate;
  final channels = reference.channels;
  final referenceFrames = reference.frameCount;
  final referenceDuration = referenceFrames / rate;
  final driftFactor = 1.0 + driftMsPer60s / 60000.0;
  if (driftFactor <= 0.5 || driftFactor >= 1.5) {
    throw _UsageException('--drift-ms-per-60s is outside the supported range.');
  }
  final offsetSeconds = offsetMs / 1000.0;
  final outputDuration =
      referenceDuration * driftFactor + offsetSeconds.abs() + 0.05;
  final outputFrames = (outputDuration * rate).round();
  final output = Float64List(outputFrames * channels);

  var seed = 987654321;
  for (var frame = 0; frame < outputFrames; frame++) {
    final time = frame / rate;
    final sourceTime = (time - offsetSeconds) / driftFactor;
    if (sourceTime >= 0 && sourceTime < referenceDuration) {
      final sourceIndex = sourceTime * rate;
      final low = sourceIndex.floor();
      final high = math.min(low + 1, referenceFrames - 1);
      final fraction = sourceIndex - low;
      for (var channel = 0; channel < channels; channel++) {
        final lowValue = reference.samples[low * channels + channel];
        final highValue = reference.samples[high * channels + channel];
        output[frame * channels + channel] =
            lowValue * (1 - fraction) + highValue * fraction;
      }
    }
    if (noise > 0) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final value = (seed / 0x3fffffff - 1.0) * noise;
      for (var channel = 0; channel < channels; channel++) {
        output[frame * channels + channel] += value;
      }
    }
  }

  return WavData(sampleRate: rate, channels: channels, samples: output);
}

void _addClick(Float64List samples, int sampleRate, int start) {
  final length = (0.010 * sampleRate).round();
  for (var index = 0; index < length; index++) {
    final position = start + index;
    if (position < 0 || position >= samples.length) break;
    final time = index / sampleRate;
    samples[position] +=
        0.8 * math.exp(-time / 0.0015) * math.sin(2 * math.pi * 2500 * time);
  }
}

WavData _readWav(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw _UsageException('File not found: $path');
  }
  return parseWav(file.readAsBytesSync());
}

List<double> _readExpected(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw _UsageException('File not found: $path');
  }
  final String contents;
  try {
    contents = file.readAsStringSync();
  } on FileSystemException catch (error) {
    throw _UsageException('Cannot read $path: ${error.message}');
  }
  dynamic decoded;
  try {
    decoded = jsonDecode(contents);
  } on FormatException catch (error) {
    throw _UsageException('Invalid JSON in $path: ${error.message}');
  }
  final values = <double>[];

  void addValue(dynamic value, String where) {
    if (value is! num || !value.isFinite || value < 0) {
      throw _UsageException(
        'Expected onset at $where must be a finite non-negative number.',
      );
    }
    values.add(value.toDouble());
  }

  if (decoded is List) {
    for (var index = 0; index < decoded.length; index++) {
      addValue(decoded[index], 'index $index');
    }
  } else if (decoded is Map<String, dynamic>) {
    final list =
        decoded['onsetsSeconds'] ??
        decoded['expectedOnsetSeconds'] ??
        decoded['onsets'];
    if (list is List) {
      for (var index = 0; index < list.length; index++) {
        addValue(list[index], 'index $index');
      }
    } else if (decoded['notes'] is List) {
      final notes = decoded['notes'] as List;
      for (var index = 0; index < notes.length; index++) {
        final note = notes[index];
        if (note is num) {
          addValue(note, 'notes[$index]');
        } else if (note is Map) {
          final onset = note['onsetSeconds'] ?? note['onset'];
          if (onset == null) {
            throw _UsageException('notes[$index] is missing onsetSeconds.');
          }
          addValue(onset, 'notes[$index]');
        } else {
          throw _UsageException('notes[$index] must be a number or an object.');
        }
      }
    } else {
      throw _UsageException(
        'Expected manifest must be a JSON array or an object with '
        '"onsetsSeconds".',
      );
    }
  } else {
    throw _UsageException('Expected manifest must be a JSON array or object.');
  }

  if (values.isEmpty) {
    throw _UsageException('Expected manifest has no onsets.');
  }
  return values;
}

CalibrationGates _gates(_Options options) {
  const defaults = CalibrationGates();
  final offset = options.number('max-offset-ms', defaults.maxOffsetMs);
  final drift = options.number('max-drift-ms', defaults.maxDriftMsPer60s);
  final falseOnsets = options.number(
    'max-false-onsets',
    defaults.maxFalseOnsetsPerMinute,
  );
  final recallDrop = options.number('max-recall-drop', defaults.maxRecallDrop);
  if (offset < 0 || drift < 0 || falseOnsets < 0 || recallDrop < 0) {
    throw _UsageException('Gate values must not be negative.');
  }
  return CalibrationGates(
    maxOffsetMs: offset,
    maxDriftMsPer60s: drift,
    maxFalseOnsetsPerMinute: falseOnsets,
    maxRecallDrop: recallDrop,
  );
}

Map<String, dynamic> _gatesJson(CalibrationGates gates) => {
  'maxOffsetMs': gates.maxOffsetMs,
  'maxDriftMsPer60s': gates.maxDriftMsPer60s,
  'maxFalseOnsetsPerMinute': gates.maxFalseOnsetsPerMinute,
  'maxRecallDrop': gates.maxRecallDrop,
};

String _fileSummary(String label, String path, WavData data) {
  final pad = label.padRight(10);
  return '$pad$path (${data.sampleRate} Hz, '
      '${data.channels == 1 ? 'mono' : '${data.channels} ch'}, '
      '${_fmt(data.duration.inMicroseconds / 1000000.0, 2)} s)';
}

String _tableHeader() {
  return '${'Metric'.padRight(22)}${'Measured'.padRight(16)}'
      '${'Gate'.padRight(20)}Result';
}

String _tableRow(String metric, String measured, String gate, String result) {
  return '${metric.padRight(22)}${measured.padRight(16)}'
      '${gate.padRight(20)}$result';
}

String _passFail(bool pass) => pass ? 'PASS' : 'FAIL';

const double _gateEpsilon = 1e-9;

bool _inside(double value, double limit) => value <= limit + _gateEpsilon;

bool _atLeast(double value, double floor) => value + _gateEpsilon >= floor;

void _writeHelp() {
  _writeLine('''
Hear Me Out latency rig

Measures output-to-input latency, clock drift, note recall, and
speaker/headphone bleed from WAV files. No microphone or running app is
required.

Usage:
  dart run tool/latency_rig.dart loopback --reference <ref.wav> \\
      --recorded <take.wav> [options]
  dart run tool/latency_rig.dart recall --recorded <take.wav> \\
      --expected <expected.json> [options]
  dart run tool/latency_rig.dart bleed --speaker <speaker.wav> \\
      --headphones <hp.wav> --expected <expected.json> [options]
  dart run tool/latency_rig.dart generate --out <ref.wav> \\
      [--expected-out <expected.json>] [options]
  dart run tool/latency_rig.dart simulate --reference <ref.wav> \\
      --out <take.wav> [options]

Measurement options:
  --json                 Print one JSON object on stdout and nothing else.
  --max-offset-ms <n>    Offset gate in milliseconds (default 10).
  --max-drift-ms <n>     Drift gate in ms per 60 s (default 20).
  --max-false-onsets <n> False-onset gate per minute (default 1).
  --max-recall-drop <n>  Allowed speaker recall drop, 0..1 (default 0.05).
  --match-window-ms <n>  Expected-onset match window (default 50).

Generate options:
  --duration <s>         Reference length in seconds (default 30).
  --interval <s>         Click interval in seconds (default 1).
  --sample-rate <hz>     Sample rate (default 48000).
  --expected-out <path>  Also write the onset manifest.

Simulate options (test signals only, not measurements):
  --offset-ms <ms>           Shift the take later (default 0).
  --drift-ms-per-60s <ms>    Stretch the take (default 0).
  --noise <amplitude>        Add deterministic noise (default 0).

Expected manifest:
  A JSON array of seconds, or {"onsetsSeconds": [...]}, or
  {"notes": [{"onsetSeconds": 0.5}, ...]}.

Exit codes:
  0  every decision gate passed
  1  at least one decision gate failed
  2  bad input (missing file, malformed WAV, malformed manifest)
''');
}

void _writeJson(Map<String, dynamic> object) {
  _writeLine(jsonEncode(object));
}

void _reportError(String message, bool jsonMode) {
  if (jsonMode) {
    _writeJson({'error': message, 'exitCode': _exitBadInput});
  } else {
    stderr.writeln('error: $message');
  }
}

void _writeLine(String line) {
  stdout.writeln(line);
}

String _fmt(double value, [int digits = 2]) {
  if (!value.isFinite) return value.toString();
  return value.toStringAsFixed(digits);
}

double _round(double value, int digits) {
  final factor = math.pow(10, digits).toDouble();
  return (value * factor).roundToDouble() / factor;
}

class _UsageException implements Exception {
  _UsageException(this.message);

  final String message;
}

class _Options {
  _Options(List<String> args) {
    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      if (!argument.startsWith('--')) {
        throw _UsageException('Unexpected argument "$argument".');
      }
      final name = argument.substring(2);
      if (name == 'json') {
        _flags.add(name);
        continue;
      }
      if (index + 1 >= args.length) {
        throw _UsageException('Option --$name needs a value.');
      }
      _values[name] = args[++index];
    }
  }

  final Map<String, String> _values = {};
  final Set<String> _flags = {};

  String? value(String name) => _values[name];

  bool flag(String name) => _flags.contains(name);

  String required(String name) {
    final result = _values[name];
    if (result == null || result.isEmpty) {
      throw _UsageException('Missing required option --$name.');
    }
    return result;
  }

  double number(String name, double fallback) {
    final raw = _values[name];
    if (raw == null) return fallback;
    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite) {
      throw _UsageException('--$name must be a number.');
    }
    return parsed;
  }

  int integer(String name, int fallback) {
    final raw = _values[name];
    if (raw == null) return fallback;
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw _UsageException('--$name must be an integer.');
    }
    return parsed;
  }

  void rejectUnknown(Set<String> allowed) {
    for (final name in _values.keys) {
      if (!allowed.contains(name)) {
        throw _UsageException('Unknown option --$name.');
      }
    }
    for (final name in _flags) {
      if (!allowed.contains(name)) {
        throw _UsageException('Unknown option --$name.');
      }
    }
  }
}
