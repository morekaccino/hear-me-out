import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:hear_me_out/core/audio/phrase_prompt.dart';
import 'package:hear_me_out/core/music/score.dart';
import 'package:hear_me_out/core/music/score_parser.dart';

import 'audio_fixtures.dart';

/// Loads a committed arrangement through the canonical score parser.
///
/// The path is relative to `assets/content/pieces/`, for example
/// `foundation/ode-to-joy.json`.
Score loadCorpusScore(String relativePath) {
  final file = File('assets/content/pieces/$relativePath');
  if (!file.existsSync()) {
    throw StateError('Missing corpus file $file');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Corpus file $relativePath is not a JSON object');
  }
  return parseScore(Map<String, dynamic>.from(decoded));
}

/// Renders a take for [prompt] with known ground truth.
///
/// This is still a synthetic waveform, but its pitches, onsets, durations, and
/// bars come from a real corpus phrase through [PhrasePlayPrompt]. Tests use it
/// to exercise pitch, timing, and completeness, not to claim microphone
/// accuracy.
List<double> renderPromptTake(
  PhrasePlayPrompt prompt, {
  int sampleRate = 22050,
  Set<int> skip = const <int>{},
  Map<int, int> wrongMidi = const <int, int>{},
  double onsetShiftSeconds = 0,
  double cents = 0,
  List<({int midi, double atSeconds})> extras =
      const <({int midi, double atSeconds})>[],
}) {
  final duration = prompt.recordingDurationSeconds + 1.5;
  final samples = silentTake(sampleRate, duration);
  for (final target in prompt.targets) {
    if (skip.contains(target.index)) continue;
    final noteDuration = math.max(
      0.08,
      math.min(0.6, target.durationSeconds * 0.8),
    );
    addTone(
      samples,
      sampleRate,
      startSeconds: target.onsetSeconds + onsetShiftSeconds,
      durationSeconds: noteDuration,
      midi: wrongMidi[target.index] ?? target.midi,
      cents: cents,
    );
  }
  for (final extra in extras) {
    addTone(
      samples,
      sampleRate,
      startSeconds: extra.atSeconds,
      durationSeconds: 0.1,
      midi: extra.midi,
    );
  }
  return samples;
}
