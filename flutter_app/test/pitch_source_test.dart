import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';

class FakePcmCapture implements PcmCapture {
  bool permission = true;
  bool failFirstStart = false;
  bool stopped = false;
  bool disposed = false;
  int startCalls = 0;
  final requests = <({int sampleRate, int channels})>[];
  final controller = StreamController<Uint8List>.broadcast();
  void Function(PcmCaptureConfig config)? onConfigChanged;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> setOnConfigChanged(
    void Function(PcmCaptureConfig config)? callback,
  ) async {
    onConfigChanged = callback;
  }

  @override
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
  }) async {
    startCalls++;
    requests.add((sampleRate: sampleRate, channels: channels));
    if (failFirstStart && startCalls == 1) {
      throw StateError('sample rate not supported');
    }
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!controller.isClosed) {
      await controller.close();
    }
  }

  void emitConfig(int sampleRate, int channels) {
    onConfigChanged?.call(
      PcmCaptureConfig(sampleRate: sampleRate, channels: channels),
    );
  }

  void add(Uint8List bytes) {
    controller.add(bytes);
  }
}

void main() {
  List<double> sine(
    double frequency,
    int sampleRate, {
    double seconds = 1,
    double amplitude = 0.5,
  }) {
    final length = (sampleRate * seconds).round();
    return [
      for (var index = 0; index < length; index++)
        amplitude * math.sin(2 * math.pi * frequency * index / sampleRate),
    ];
  }

  Uint8List monoPcm16(List<double> samples) {
    final bytes = Uint8List(samples.length * 2);
    final data = ByteData.sublistView(bytes);
    for (var index = 0; index < samples.length; index++) {
      data.setInt16(
        index * 2,
        (samples[index].clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }
    return bytes;
  }

  Uint8List stereoPcm16(List<double> left, List<double> right) {
    final bytes = Uint8List(left.length * 4);
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    for (var index = 0; index < left.length; index++) {
      data.setInt16(
        offset,
        (left[index].clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
      data.setInt16(
        offset + 2,
        (right[index].clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
      offset += 4;
    }
    return bytes;
  }

  test('PitchFrame defaults keep old call sites working', () {
    final frame = PitchFrame(
      frequency: 440,
      clarity: 0.9,
      rms: 0.1,
      timestamp: DateTime(2026, 11, 5),
    );

    expect(frame.sampleIndex, 0);
    expect(frame.sampleTime, Duration.zero);
  });

  test('PitchFrame carries a sample-clock position', () {
    final frame = PitchFrame(
      frequency: 440,
      clarity: 0.9,
      rms: 0.1,
      timestamp: DateTime(2026, 11, 5),
      sampleIndex: 44100,
      sampleTime: const Duration(milliseconds: 2000),
    );

    expect(frame.sampleIndex, 44100);
    expect(frame.sampleTime, const Duration(milliseconds: 2000));
  });

  test(
    'effective stereo config feeds the sample clock and decodes 440 Hz',
    () async {
      final capture = FakePcmCapture();
      final source = RecordPitchSource(captureFactory: () => capture);
      final frames = <PitchFrame>[];
      final subscription = source.frames.listen(frames.add);
      addTearDown(() async {
        await subscription.cancel();
        await source.dispose();
      });

      expect(await source.start(), isTrue);
      expect(capture.requests.single, (sampleRate: 48000, channels: 1));

      // The platform negotiated stereo at 48 kHz before the first byte.
      capture.emitConfig(48000, 2);

      final left = sine(440, 48000);
      final right = sine(440, 48000);
      capture.add(stereoPcm16(left, right));
      await pumpEventQueue();

      expect(frames.length, greaterThanOrEqualTo(2));
      expect(frames.first.sampleIndex, 0);
      expect(frames.first.sampleTime, Duration.zero);
      expect(frames[1].sampleIndex, RecordPitchSource.hopSize);
      expect(
        frames[1].sampleTime,
        Duration(
          microseconds:
              (RecordPitchSource.hopSize *
                      Duration.microsecondsPerSecond /
                      RecordPitchSource.analysisSampleRate)
                  .round(),
        ),
      );
      expect(
        frames[1].timestamp.difference(frames[0].timestamp),
        frames[1].sampleTime - frames[0].sampleTime,
      );

      for (final frame in frames) {
        expect((frame.frequency - 440).abs(), lessThan(2));
      }
    },
  );

  test('sampleIndex restarts at zero on start after stop', () async {
    final capture = FakePcmCapture();
    final source = RecordPitchSource(captureFactory: () => capture);
    final frames = <PitchFrame>[];
    final subscription = source.frames.listen(frames.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.dispose();
    });

    expect(await source.start(), isTrue);
    capture.add(monoPcm16(sine(440, 48000)));
    await pumpEventQueue();
    expect(frames.first.sampleIndex, 0);

    await source.stop();
    frames.clear();

    expect(await source.start(), isTrue);
    capture.emitConfig(44100, 1);
    capture.add(monoPcm16(sine(440, 44100)));
    await pumpEventQueue();

    expect(frames, isNotEmpty);
    expect(frames.first.sampleIndex, 0);
    expect(frames[1].sampleIndex, RecordPitchSource.hopSize);
  });

  test('falls back to 44.1 kHz when 48 kHz is rejected', () async {
    final capture = FakePcmCapture()..failFirstStart = true;
    final source = RecordPitchSource(captureFactory: () => capture);
    final frames = <PitchFrame>[];
    final subscription = source.frames.listen(frames.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.dispose();
    });

    expect(await source.start(), isTrue);
    expect(capture.requests, [
      (sampleRate: 48000, channels: 1),
      (sampleRate: 44100, channels: 1),
    ]);
    expect(capture.stopped, isTrue);

    capture.add(monoPcm16(sine(440, 44100)));
    await pumpEventQueue();

    expect(frames, isNotEmpty);
    expect(frames.first.sampleIndex, 0);
    expect((frames.first.frequency - 440).abs(), lessThan(2));
  });

  test('a late effective config drops pre-correction samples', () async {
    final capture = FakePcmCapture();
    final source = RecordPitchSource(captureFactory: () => capture);
    final frames = <PitchFrame>[];
    final subscription = source.frames.listen(frames.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.dispose();
    });

    expect(await source.start(), isTrue);
    final early = monoPcm16(sine(440, 48000, seconds: 0.02));
    capture.add(early);
    await pumpEventQueue();
    expect(frames, isEmpty);

    capture.emitConfig(44100, 1);
    capture.add(monoPcm16(sine(440, 44100)));
    await pumpEventQueue();

    expect(frames, isNotEmpty);
    expect(frames.first.sampleIndex, 0);
    for (final frame in frames) {
      expect((frame.frequency - 440).abs(), lessThan(2));
    }
  });

  test(
    'a post-frame config correction keeps the sample clock monotonic',
    () async {
      final capture = FakePcmCapture();
      final source = RecordPitchSource(captureFactory: () => capture);
      final frames = <PitchFrame>[];
      final subscription = source.frames.listen(frames.add);
      addTearDown(() async {
        await subscription.cancel();
        await source.dispose();
      });

      expect(await source.start(), isTrue);
      capture.add(monoPcm16(sine(440, 48000, seconds: 0.5)));
      await pumpEventQueue();

      expect(frames, isNotEmpty);
      final before = frames.length;
      final lastBefore = frames.last;

      // The platform changes both rate and channel count after a frame was
      // already published. The clock must keep moving forward.
      capture.emitConfig(44100, 2);
      capture.add(
        stereoPcm16(
          sine(440, 44100, seconds: 0.5),
          sine(440, 44100, seconds: 0.5),
        ),
      );
      await pumpEventQueue();

      final after = frames.sublist(before);
      expect(after, isNotEmpty);

      var previousIndex = lastBefore.sampleIndex;
      for (final frame in after) {
        expect(frame.sampleIndex, greaterThan(previousIndex));
        previousIndex = frame.sampleIndex;
        expect(
          frame.sampleTime,
          Duration(
            microseconds:
                (frame.sampleIndex *
                        Duration.microsecondsPerSecond /
                        RecordPitchSource.analysisSampleRate)
                    .round(),
          ),
        );
        expect((frame.frequency - 440).abs(), lessThan(2));
      }
    },
  );

  test('analysis cadence stays at 2048/1024 samples at 22.05 kHz', () async {
    final capture = FakePcmCapture();
    final source = RecordPitchSource(captureFactory: () => capture);
    final frames = <PitchFrame>[];
    final subscription = source.frames.listen(frames.add);
    addTearDown(() async {
      await subscription.cancel();
      await source.dispose();
    });

    expect(RecordPitchSource.frameSize, 2048);
    expect(RecordPitchSource.hopSize, 1024);

    expect(await source.start(), isTrue);
    capture.emitConfig(44100, 1);

    final tone = monoPcm16(sine(440, 44100, seconds: 0.2));
    // 4095 input frames at 44.1 kHz produce 2047 analysis samples, one short
    // of the 2048-sample window.
    capture.add(tone.sublist(0, 8190));
    await pumpEventQueue();
    expect(frames, isEmpty);

    // The last input frame completes the window.
    capture.add(tone.sublist(8190, 8192));
    await pumpEventQueue();
    expect(frames, hasLength(1));
    expect(frames.first.sampleIndex, 0);

    // One hop of 1024 analysis samples is 2048 input frames at 44.1 kHz.
    capture.add(tone.sublist(8192, 8192 + 4096));
    await pumpEventQueue();
    expect(frames.length, greaterThanOrEqualTo(2));
    expect(frames[1].sampleIndex, 1024);
  });
}
