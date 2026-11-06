import 'dart:math' as math;
import 'dart:typed_data';

import 'fft.dart';

/// A detected attack in a mono sample buffer.
class OnsetEvent {
  const OnsetEvent({
    required this.sampleIndex,
    required this.timeSeconds,
    required this.strength,
  });

  /// First sample of the attack, relative to the start of the buffer.
  final int sampleIndex;

  /// [sampleIndex] converted to seconds.
  final double timeSeconds;

  /// Normalized 0..1 confidence that this is a musical attack.
  final double strength;

  @override
  String toString() =>
      'OnsetEvent(${timeSeconds.toStringAsFixed(3)}s, '
      '${(strength * 100).toStringAsFixed(0)}%)';
}

/// Spectral-flux onset detector for monophonic guitar takes.
///
/// Pipeline:
/// 1. Hann-windowed frames, hop usually 10-12 ms.
/// 2. Half-wave-rectified difference of log magnitudes.
/// 3. Adaptive threshold from the local median and median absolute deviation,
///    plus a local-maximum prominence floor. A single global threshold would
///    fail on quiet takes; the local rule does not.
/// 4. A rise gate rejects note releases and steady noise.
/// 5. Peak picking with a minimum gap, then a short energy-envelope refinement
///    that reports the first sample of the attack rather than the FFT frame
///    centre. The refinement is what keeps timing errors in the low
///    milliseconds instead of half an FFT frame.
///
/// A note that begins in the very first frame cannot be detected because there
/// is no preceding frame to compare with. Callers should include a short
/// count-in or lead-in before the first target.
class OnsetDetector {
  OnsetDetector({
    required this.sampleRate,
    this.frameSize = 1024,
    this.hopSize = 256,
    this.minRms = 0.004,
    this.fluxThreshold = 0.12,
    this.minGapSeconds = 0.05,
  })  : assert(frameSize > 0 && (frameSize & (frameSize - 1)) == 0),
        assert(hopSize > 0 && hopSize <= frameSize);

  final double sampleRate;
  final int frameSize;
  final int hopSize;

  /// Frames quieter than this RMS are never reported as onsets.
  final double minRms;

  /// Minimum prominence as a fraction of the strongest flux in the local
  /// adaptive window. The local median/MAD threshold can only raise this.
  final double fluxThreshold;

  /// Two attacks closer than this are merged into the stronger one.
  final double minGapSeconds;

  List<OnsetEvent> detect(List<double> samples) {
    if (sampleRate <= 0 || samples.length < frameSize) {
      return const [];
    }
    final frameCount = 1 + (samples.length - frameSize) ~/ hopSize;
    if (frameCount < 3) return const [];

    final fft = Fft(frameSize);
    final real = Float64List(frameSize);
    final imaginary = Float64List(frameSize);
    final hann = Float64List(frameSize);
    for (var index = 0; index < frameSize; index++) {
      hann[index] = hannWindow(index, frameSize);
    }

    final binCount = frameSize ~/ 2 + 1;
    final logSpectra = List<Float64List>.generate(
      frameCount,
      (_) => Float64List(binCount),
    );
    final rmsByFrame = Float64List(frameCount);
    final lowRatioByFrame = Float64List(frameCount);
    final centroidByFrame = Float64List(frameCount);

    for (var frame = 0; frame < frameCount; frame++) {
      final start = frame * hopSize;
      var sumSquares = 0.0;
      for (var index = 0; index < frameSize; index++) {
        final sample = samples[start + index];
        sumSquares += sample * sample;
        real[index] = sample * hann[index];
        imaginary[index] = 0;
      }
      rmsByFrame[frame] = math.sqrt(sumSquares / frameSize);
      fft.forward(real, imaginary);

      final spectrum = logSpectra[frame];
      var totalEnergy = 0.0;
      var lowEnergy = 0.0;
      var magnitudeSum = 0.0;
      var weightedSum = 0.0;
      for (var bin = 0; bin < binCount; bin++) {
        final magnitude = math.sqrt(
          real[bin] * real[bin] + imaginary[bin] * imaginary[bin],
        );
        final energy = magnitude * magnitude;
        final frequency = bin * sampleRate / frameSize;
        totalEnergy += energy;
        magnitudeSum += magnitude;
        weightedSum += magnitude * frequency;
        if (frequency < 120) {
          lowEnergy += energy;
        }
        // A fixed logarithmic scale keeps note releases (where every
        // magnitude falls) at a low flux while preserving quiet attacks.
        spectrum[bin] = math.log(1 + 100 * magnitude);
      }
      lowRatioByFrame[frame] = totalEnergy > 0 ? lowEnergy / totalEnergy : 0;
      centroidByFrame[frame] = magnitudeSum > 0 ? weightedSum / magnitudeSum : 0;
    }

    final flux = Float64List(frameCount);
    for (var frame = 1; frame < frameCount; frame++) {
      final current = logSpectra[frame];
      final previous = logSpectra[frame - 1];
      var sum = 0.0;
      for (var bin = 0; bin < binCount; bin++) {
        final difference = current[bin] - previous[bin];
        if (difference > 0) sum += difference;
      }
      flux[frame] = sum / binCount;
    }

    final threshold = _adaptiveThreshold(flux);
    final minGapFrames = math.max(
      1,
      (minGapSeconds * sampleRate / hopSize).ceil(),
    );
    final lookbackFrames = math.max(
      1,
      (0.04 * sampleRate / hopSize).round(),
    );
    final bodyLookaheadFrames = math.max(
      1,
      (0.045 * sampleRate / hopSize).round(),
    );

    final peaks = <int>[];
    for (var frame = 1; frame < frameCount - 1; frame++) {
      if (rmsByFrame[frame] < minRms) continue;
      if (flux[frame] <= threshold[frame]) continue;
      if (flux[frame] < flux[frame - 1] || flux[frame] <= flux[frame + 1]) {
        continue;
      }
      // Attacks add energy relative to the quietest recent frame. Using the
      // minimum, not the frame 40 ms ago, lets a new note be heard while the
      // previous string is still decaying. A release keeps falling, so it
      // never clears this gate.
      var previousRms = double.infinity;
      for (var recent = math.max(0, frame - lookbackFrames);
          recent < frame;
          recent++) {
        if (rmsByFrame[recent] < previousRms) previousRms = rmsByFrame[recent];
      }
      if (!previousRms.isFinite) previousRms = 0;
      if (rmsByFrame[frame] < 1.15 * math.max(previousRms, 1e-4)) continue;
      if (peaks.isNotEmpty && frame - peaks.last < minGapFrames) {
        if (flux[frame] > flux[peaks.last]) {
          peaks[peaks.length - 1] = frame;
        }
        continue;
      }
      peaks.add(frame);
    }

    final adaptiveHalf = math.max(
      1,
      (0.5 * sampleRate / hopSize).round() ~/ 2,
    );
    final merged = <OnsetEvent>[];
    for (final frame in peaks) {
      var localMax = 0.0;
      final windowStart = math.max(0, frame - adaptiveHalf);
      final windowEnd = math.min(frameCount - 1, frame + adaptiveHalf);
      for (var index = windowStart; index <= windowEnd; index++) {
        if (flux[index] > localMax) localMax = flux[index];
      }
      final denominator = math.max(localMax - threshold[frame], 1e-6);
      var strength = ((flux[frame] - threshold[frame]) / denominator)
          .clamp(0.0, 1.0);
      // A body thump is a low-frequency burst whose spectral centroid sits
      // below the guitar's range. Look a few frames past the attack so the
      // broadband pick transient does not mask the low-frequency body. Keeping
      // the event weak lets the segmenter reject it as unpitched instead of
      // scoring a phantom note. A normal low E2 (82 Hz plus harmonics) keeps
      // its centroid above 85 Hz.
      final bodyFrame = math.min(
        frame + bodyLookaheadFrames,
        frameCount - 1,
      );
      final lowRatio = lowRatioByFrame[bodyFrame];
      final centroid = centroidByFrame[bodyFrame];
      if (lowRatio > 0.8 && centroid < 85) {
        strength *= 0.2;
      }
      final sampleIndex = _refineAttack(
        samples: samples,
        rmsByFrame: rmsByFrame,
        peakFrame: frame,
      );
      final event = OnsetEvent(
        sampleIndex: sampleIndex,
        timeSeconds: sampleIndex / sampleRate,
        strength: strength,
      );
      if (merged.isNotEmpty &&
          event.timeSeconds - merged.last.timeSeconds < minGapSeconds) {
        if (event.strength > merged.last.strength) {
          merged[merged.length - 1] = event;
        }
        continue;
      }
      merged.add(event);
    }
    return merged;
  }

  Float64List _adaptiveThreshold(Float64List flux) {
    final frameCount = flux.length;
    final windowFrames = math.max(
      3,
      (0.5 * sampleRate / hopSize).round() | 1,
    );
    final half = windowFrames ~/ 2;
    final threshold = Float64List(frameCount);
    final scratch = Float64List(windowFrames);
    final deviations = Float64List(windowFrames);

    for (var frame = 0; frame < frameCount; frame++) {
      // Causal window: judge an attack against what came before it, not
      // against the vibrato that follows. This keeps a modulated note's first
      // attack above threshold while still rejecting its later wobble.
      final start = math.max(0, frame - half + 1);
      final end = frame;
      final count = end - start + 1;
      var localMax = 0.0;
      for (var index = 0; index < count; index++) {
        final value = flux[start + index];
        scratch[index] = value;
        if (value > localMax) localMax = value;
      }
      final window = scratch.sublist(0, count)..sort();
      final median = _medianSorted(window);
      for (var index = 0; index < count; index++) {
        deviations[index] = (window[index] - median).abs();
      }
      final sortedDeviations = deviations.sublist(0, count)..sort();
      final mad = _medianSorted(sortedDeviations);
      // 1.4826 converts MAD to a robust standard deviation for Gaussian data.
      threshold[frame] = math.max(
        fluxThreshold * localMax,
        median + 3.0 * 1.4826 * mad,
      );
    }
    return threshold;
  }

  int _refineAttack({
    required List<double> samples,
    required Float64List rmsByFrame,
    required int peakFrame,
  }) {
    final frameStart = peakFrame * hopSize;
    final frameEnd = math.min(samples.length, frameStart + frameSize);
    final searchStart = math.max(0, frameStart - frameSize);
    final window = math.max(1, (0.003 * sampleRate).round());
    final step = math.max(1, (0.001 * sampleRate).round());
    if (frameEnd - searchStart < window) return frameStart;

    // The quietest 3 ms window before the peak approximates the local noise
    // floor, including the decay tail of the previous note.
    var noiseFloor = double.infinity;
    for (var start = searchStart; start + window <= frameStart; start += step) {
      final rms = _windowRms(samples, start, window);
      if (rms < noiseFloor) noiseFloor = rms;
    }
    if (!noiseFloor.isFinite) noiseFloor = minRms;
    final peakRms = rmsByFrame[peakFrame];
    final onsetThreshold = math.max(
      minRms,
      noiseFloor + 0.25 * math.max(peakRms - noiseFloor, 0),
    );

    var candidate = frameStart;
    var wasAbove = false;
    for (var start = searchStart; start + window <= frameEnd; start += step) {
      final above = _windowRms(samples, start, window) >= onsetThreshold;
      if (above && !wasAbove) {
        candidate = start;
      }
      wasAbove = above;
    }
    // If the signal was already above threshold at the search start, the
    // current attack cannot be isolated from the previous note. The frame
    // start is still within one hop of the spectral-flux peak.
    return candidate.clamp(0, samples.length - 1);
  }

  double _windowRms(List<double> samples, int start, int length) {
    var sum = 0.0;
    for (var index = 0; index < length; index++) {
      final sample = samples[start + index];
      sum += sample * sample;
    }
    return math.sqrt(sum / length);
  }

  static double _medianSorted(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return 0.5 * (sorted[middle - 1] + sorted[middle]);
  }
}
