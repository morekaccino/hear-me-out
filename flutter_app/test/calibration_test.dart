import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/calibration.dart';
import 'package:hear_me_out/core/audio/wav.dart';

void main() {
  const sampleRate = 16000;

  WavData clickTrain({
    int rate = sampleRate,
    double durationSeconds = 20,
    double intervalSeconds = 0.5,
    double offsetMs = 0,
    double driftMsPer60s = 0,
    double noiseAmplitude = 0,
    Set<int> dropClicks = const <int>{},
    List<double> extraOnsets = const <double>[],
    bool stereo = false,
    double extraAmplitude = 0.7,
  }) {
    final frameCount = (durationSeconds * rate).round();
    final channels = stereo ? 2 : 1;
    final samples = Float64List(frameCount * channels);
    var click = 0;
    for (
      var time = 0.5;
      time < durationSeconds - 0.1;
      time += intervalSeconds
    ) {
      if (!dropClicks.contains(click)) {
        final shiftSeconds = offsetMs / 1000.0 + driftMsPer60s / 60000.0 * time;
        final start = ((time + shiftSeconds) * rate).round();
        _addClick(samples, channels, start, rate);
      }
      click++;
    }
    for (final time in extraOnsets) {
      final start = (time * rate).round();
      _addClick(samples, channels, start, rate, amplitude: extraAmplitude);
    }
    if (noiseAmplitude > 0) {
      var seed = 123456789;
      for (var index = 0; index < samples.length; index++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final noise = (seed / 0x3fffffff - 1.0) * noiseAmplitude;
        samples[index] += noise;
      }
    }
    return WavData(sampleRate: rate, channels: channels, samples: samples);
  }

  List<double> expectedOnsets({
    double durationSeconds = 20,
    double intervalSeconds = 0.5,
  }) {
    final onsets = <double>[];
    for (
      var time = 0.5;
      time < durationSeconds - 0.1;
      time += intervalSeconds
    ) {
      onsets.add(time);
    }
    return onsets;
  }

  group('loopback offset', () {
    test('measures a zero offset and marks timing usable', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(),
      );

      expect(report.offsetMs, closeTo(0, 1));
      expect(report.driftMsPer60s, closeTo(0, 1));
      expect(report.noteRecall, closeTo(1, 0.01));
      expect(report.timingUsable, isTrue);
      expect(report.failures, isEmpty);
    });

    test('measures a 5 ms offset and passes the 10 ms gate', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 5),
      );

      expect(report.offsetMs, closeTo(5, 1));
      expect(report.timingUsable, isTrue);
    });

    test('measures a 10 ms offset', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 10),
      );

      expect(report.offsetMs, closeTo(10, 1));
    });

    test('fails a 25 ms offset', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 25),
      );

      expect(report.offsetMs, closeTo(25, 1));
      expect(report.timingUsable, isFalse);
      expect(report.failures.join(' '), contains('offset'));
    });

    test('does not alias a 490 ms offset to -10 ms on a 0.5 s train', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 490),
      );

      expect(report.offsetMs, closeTo(490, 1));
      expect(report.offsetVerified, isTrue);
      expect(report.driftVerified, isTrue);
      expect(report.timingUsable, isFalse);
      expect(report.failures.join(' '), contains('offset'));
    });

    test('measures 240 ms and 300 ms offsets on a 0.5 s train', () {
      for (final offset in [240.0, 300.0]) {
        final report = analyzeLoopback(
          reference: clickTrain(),
          recorded: clickTrain(offsetMs: offset),
        );

        expect(report.offsetMs, closeTo(offset, 1));
        expect(report.offsetVerified, isTrue);
        expect(report.timingUsable, isFalse);
      }
    });

    test('does not alias a 60 ms offset on a 0.05 s train', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 10, intervalSeconds: 0.05),
        recorded: clickTrain(
          durationSeconds: 10,
          intervalSeconds: 0.05,
          offsetMs: 60,
        ),
      );

      expect(report.offsetMs, closeTo(60, 1));
      expect(report.offsetVerified, isTrue);
      expect(report.timingUsable, isFalse);
    });

    test('marks a take that starts before the reference as unverified', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: -400),
      );

      expect(report.offsetVerified, isFalse);
      expect(report.driftVerified, isFalse);
      expect(report.timingUsable, isFalse);
      expect(
        report.failures.join(' '),
        contains('before the first reference click'),
      );
      expect(report.toJson()['offsetMs'], isNull);
      expect(report.toJson()['driftMsPer60s'], isNull);
      expect(report.toJson()['offsetVerified'], isFalse);
    });

    test('respects a custom offset gate', () {
      final recording = clickTrain(offsetMs: 10);

      final strict = analyzeLoopback(
        reference: clickTrain(),
        recorded: recording,
        gates: const CalibrationGates(maxOffsetMs: 8),
      );
      final lenient = analyzeLoopback(
        reference: clickTrain(),
        recorded: recording,
        gates: const CalibrationGates(maxOffsetMs: 12),
      );

      expect(strict.timingUsable, isFalse);
      expect(lenient.timingUsable, isTrue);
    });

    test('works with a 48 kHz stereo take', () {
      final report = analyzeLoopback(
        reference: clickTrain(rate: 48000, stereo: true),
        recorded: clickTrain(rate: 48000, stereo: true, offsetMs: 5),
      );

      expect(report.offsetMs, closeTo(5, 1));
      expect(report.timingUsable, isTrue);
    });
  });

  group('clock drift', () {
    test('measures zero drift over a 30 second take', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 30, intervalSeconds: 1),
        recorded: clickTrain(durationSeconds: 30, intervalSeconds: 1),
      );

      expect(report.driftMsPer60s, closeTo(0, 1));
      expect(report.timingUsable, isTrue);
    });

    test('passes 10 ms per 60 s drift', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 30, intervalSeconds: 1),
        recorded: clickTrain(
          durationSeconds: 30,
          intervalSeconds: 1,
          driftMsPer60s: 10,
        ),
      );

      expect(report.driftMsPer60s, closeTo(10, 2));
      expect(report.offsetMs, closeTo(0, 1));
      expect(report.timingUsable, isTrue);
    });

    test('fails 30 ms per 60 s drift', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 30, intervalSeconds: 1),
        recorded: clickTrain(
          durationSeconds: 30,
          intervalSeconds: 1,
          driftMsPer60s: 30,
        ),
      );

      expect(report.driftMsPer60s, closeTo(30, 2));
      expect(report.timingUsable, isFalse);
      expect(report.failures.join(' '), contains('drift'));
    });

    test('fails negative drift beyond the gate', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 30, intervalSeconds: 1),
        recorded: clickTrain(
          durationSeconds: 30,
          intervalSeconds: 1,
          driftMsPer60s: -30,
        ),
      );

      expect(report.driftMsPer60s, closeTo(-30, 2));
      expect(report.timingUsable, isFalse);
    });

    test('requires at least two clicks to verify drift', () {
      final report = analyzeLoopback(
        reference: clickTrain(durationSeconds: 2, intervalSeconds: 10),
        recorded: clickTrain(durationSeconds: 2, intervalSeconds: 10),
      );

      expect(report.expectedOnsets, 1);
      expect(report.offsetVerified, isFalse);
      expect(report.driftVerified, isFalse);
      expect(report.timingUsable, isFalse);
      expect(report.failures.join(' '), contains('at least 2'));
      expect(report.toJson()['offsetMs'], isNull);
      expect(report.toJson()['driftMsPer60s'], isNull);
    });
  });

  group('recall and false onsets', () {
    test('reports full recall for a clean take', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(),
      );

      expect(report.noteRecall, closeTo(1, 0.001));
      expect(report.falseOnsetsPerMinute, closeTo(0, 0.001));
    });

    test('reports recall loss for missing clicks', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(dropClicks: {3, 7, 11}),
      );

      expect(report.matchedOnsets, 36);
      expect(report.noteRecall, closeTo(36 / 39, 0.001));
    });

    test('counts extra clicks as false onsets', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(extraOnsets: [1.25, 6.25]),
      );

      expect(report.detectedOnsets, 41);
      expect(report.falseOnsetsPerMinute, closeTo(6, 0.2));
      // False onsets gate bleed, not the loopback timing decision.
      expect(report.timingUsable, isTrue);
    });

    test('ignores low-level deterministic noise', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 5, noiseAmplitude: 0.01),
      );

      expect(report.noteRecall, closeTo(1, 0.01));
      expect(report.falseOnsetsPerMinute, closeTo(0, 0.5));
      expect(report.offsetMs, closeTo(5, 1));
    });

    test('matches expected note onsets from a manifest', () {
      final expected = expectedOnsets();
      final report = analyzeNoteRecall(
        recorded: clickTrain(offsetMs: 5),
        expectedOnsetSeconds: expected,
      );

      expect(report.expectedOnsets, expected.length);
      expect(report.matchedOnsets, expected.length);
      expect(report.noteRecall, closeTo(1, 0.001));
      expect(report.falseOnsetsPerMinute, closeTo(0, 0.001));
      expect(report.meanLatencyMs, greaterThan(3));
      expect(report.meanLatencyMs, lessThan(15));
      expect(report.recallUsable, isTrue);
    });

    test('reports a missing note as recall loss', () {
      final expected = expectedOnsets();
      final report = analyzeNoteRecall(
        recorded: clickTrain(dropClicks: {5}),
        expectedOnsetSeconds: expected,
      );

      expect(report.matchedOnsets, expected.length - 1);
      expect(report.noteRecall, closeTo(0.975, 0.001));
      // 97.5% is still above the 95% floor.
      expect(report.recallUsable, isTrue);
    });

    test('fails recall below the 95% floor', () {
      final expected = expectedOnsets();
      final report = analyzeNoteRecall(
        recorded: clickTrain(dropClicks: {2, 5, 8}),
        expectedOnsetSeconds: expected,
      );

      expect(report.noteRecall, closeTo(36 / 39, 0.001));
      expect(report.recallUsable, isFalse);
      expect(report.failures.join(' '), contains('recall'));
    });

    test('fails extra onsets above one per minute', () {
      final expected = expectedOnsets();
      final report = analyzeNoteRecall(
        recorded: clickTrain(extraOnsets: [2.25]),
        expectedOnsetSeconds: expected,
      );

      // 20 second take, one extra onset -> 3 per minute.
      expect(report.falseOnsetsPerMinute, closeTo(3, 0.2));
      expect(report.recallUsable, isFalse);
      expect(report.failures.join(' '), contains('false onsets'));
    });

    test('rejects an empty expected manifest', () {
      expect(
        () => analyzeNoteRecall(
          recorded: clickTrain(),
          expectedOnsetSeconds: const <double>[],
        ),
        throwsArgumentError,
      );
    });
  });

  group('bleed', () {
    test('passes when speaker and headphone recalls match', () {
      final expected = expectedOnsets();
      final report = analyzeBleed(
        speaker: clickTrain(),
        headphones: clickTrain(),
        expectedOnsetSeconds: expected,
      );

      expect(report.recallDrop, closeTo(0, 0.001));
      expect(report.headphonesRequired, isFalse);
      expect(report.failures, isEmpty);
    });

    test('passes a small recall drop', () {
      final expected = expectedOnsets();
      final report = analyzeBleed(
        speaker: clickTrain(dropClicks: {4}),
        headphones: clickTrain(),
        expectedOnsetSeconds: expected,
      );

      expect(report.recallDrop, closeTo(1 / 39, 0.001));
      expect(report.headphonesRequired, isFalse);
    });

    test('passes an exact 5 percent recall drop at the gate boundary', () {
      final expected = expectedOnsets(durationSeconds: 20.5);
      final report = analyzeBleed(
        speaker: clickTrain(durationSeconds: 20.5, dropClicks: {3, 15}),
        headphones: clickTrain(durationSeconds: 20.5),
        expectedOnsetSeconds: expected,
      );

      expect(report.recallDrop, closeTo(0.05, 0.001));
      expect(report.headphonesRequired, isFalse);
    });

    test('requires headphones when the speaker loses recall', () {
      final expected = expectedOnsets();
      final report = analyzeBleed(
        speaker: clickTrain(dropClicks: {1, 6, 12}),
        headphones: clickTrain(),
        expectedOnsetSeconds: expected,
      );

      expect(report.speakerRecall, closeTo(36 / 39, 0.001));
      expect(report.headphoneRecall, closeTo(1, 0.001));
      expect(report.recallDrop, closeTo(3 / 39, 0.001));
      expect(report.headphonesRequired, isTrue);
      expect(report.failures.join(' '), contains('speaker recall'));
    });

    test('requires headphones on speaker bleed onsets', () {
      final expected = expectedOnsets();
      final report = analyzeBleed(
        speaker: clickTrain(extraOnsets: [1.25, 3.25, 5.25]),
        headphones: clickTrain(),
        expectedOnsetSeconds: expected,
      );

      expect(report.recallDrop, closeTo(0, 0.001));
      expect(report.speakerFalseOnsetsPerMinute, closeTo(9, 0.2));
      expect(report.headphonesRequired, isTrue);
      expect(report.failures.join(' '), contains('false onsets'));
    });

    test('accepts exactly one false onset per minute', () {
      final expected = expectedOnsets(durationSeconds: 60);
      final report = analyzeBleed(
        speaker: clickTrain(durationSeconds: 60, extraOnsets: [30.25]),
        headphones: clickTrain(durationSeconds: 60),
        expectedOnsetSeconds: expected,
      );

      expect(report.speakerFalseOnsetsPerMinute, closeTo(1, 0.05));
      expect(report.headphonesRequired, isFalse);
    });
  });

  group('input validation', () {
    test('rejects mismatched sample rates', () {
      expect(
        () => analyzeLoopback(
          reference: clickTrain(rate: 44100),
          recorded: clickTrain(rate: 48000),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a silent recording', () {
      final silent = WavData(
        sampleRate: sampleRate,
        channels: 1,
        samples: List<double>.filled(sampleRate * 2, 0),
      );
      expect(
        () => analyzeLoopback(reference: clickTrain(), recorded: silent),
        throwsArgumentError,
      );
    });

    test('rejects a stereo file with a broken frame count', () {
      expect(
        () => WavData(sampleRate: 44100, channels: 2, samples: [0.0, 0.0, 0.0]),
        throwsArgumentError,
      );
    });
  });

  group('report serialization', () {
    test('CalibrationReport JSON contains the decision and metrics', () {
      final report = analyzeLoopback(
        reference: clickTrain(),
        recorded: clickTrain(offsetMs: 25),
      );
      final json = report.toJson();

      expect(json['timingUsable'], isFalse);
      expect(json['offsetMs'], isA<double>());
      expect(json['driftMsPer60s'], isA<double>());
      expect(json['falseOnsetsPerMinute'], isA<double>());
      expect(json['noteRecall'], isA<double>());
      expect(json['failures'], isA<List<String>>());
      expect(() => jsonEncode(json), returnsNormally);
    });

    test('BleedReport JSON contains the headphone decision', () {
      final expected = expectedOnsets();
      final report = analyzeBleed(
        speaker: clickTrain(dropClicks: {1, 6, 12}),
        headphones: clickTrain(),
        expectedOnsetSeconds: expected,
      );
      final json = report.toJson();

      expect(json['headphonesRequired'], isTrue);
      expect(json['speakerRecall'], isA<double>());
      expect(json['headphoneRecall'], isA<double>());
      expect(json['recallDrop'], isA<double>());
      expect(json['speakerFalseOnsetsPerMinute'], isA<double>());
      expect(() => jsonEncode(json), returnsNormally);
    });
  });
}

void _addClick(
  Float64List samples,
  int channels,
  int start,
  int sampleRate, {
  double amplitude = 0.8,
}) {
  final length = (0.008 * sampleRate).round();
  for (var index = 0; index < length; index++) {
    final position = start + index;
    if (position < 0 || position >= samples.length ~/ channels) break;
    final time = index / sampleRate;
    final value =
        amplitude *
        math.exp(-time / 0.0015) *
        math.sin(2 * math.pi * 2500 * time);
    for (var channel = 0; channel < channels; channel++) {
      samples[position * channels + channel] += value;
    }
  }
}
