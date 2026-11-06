import 'dart:math' as math;
import 'dart:typed_data';

/// In-place iterative radix-2 Cooley-Tukey FFT.
///
/// [size] must be a power of two. The phrase pipeline uses sizes in the
/// 256-2048 range, but any power of two greater than one is accepted.
class Fft {
  factory Fft(int size) {
    if (size < 2 || (size & (size - 1)) != 0) {
      throw ArgumentError.value(size, 'size', 'must be a power of two >= 2');
    }
    return Fft._(size);
  }

  Fft._(this.size)
      : _cos = Float64List(size ~/ 2),
        _sin = Float64List(size ~/ 2),
        _bitReverse = Int32List(size) {
    final bits = _log2(size);
    for (var index = 0; index < size; index++) {
      _bitReverse[index] = _reverseBits(index, bits);
    }
    for (var index = 0; index < size ~/ 2; index++) {
      final angle = -2 * math.pi * index / size;
      _cos[index] = math.cos(angle);
      _sin[index] = math.sin(angle);
    }
  }

  /// Number of complex samples in one transform.
  final int size;

  final Float64List _cos;
  final Float64List _sin;
  final Int32List _bitReverse;

  /// Transforms [real] and [imaginary] in place.
  ///
  /// Both buffers must have exactly [size] entries. The imaginary part is
  /// normally zero for real audio.
  void forward(Float64List real, Float64List imaginary) {
    _checkBuffers(real, imaginary);

    for (var index = 0; index < size; index++) {
      final reversed = _bitReverse[index];
      if (reversed > index) {
        final realValue = real[index];
        real[index] = real[reversed];
        real[reversed] = realValue;
        final imaginaryValue = imaginary[index];
        imaginary[index] = imaginary[reversed];
        imaginary[reversed] = imaginaryValue;
      }
    }

    for (var length = 2; length <= size; length <<= 1) {
      final half = length >> 1;
      final twiddleStep = size ~/ length;
      for (var start = 0; start < size; start += length) {
        for (var offset = 0; offset < half; offset++) {
          final twiddle = offset * twiddleStep;
          final wr = _cos[twiddle];
          final wi = _sin[twiddle];
          final even = start + offset;
          final odd = even + half;
          final oddReal = real[odd];
          final oddImaginary = imaginary[odd];
          final rotatedReal = wr * oddReal - wi * oddImaginary;
          final rotatedImaginary = wr * oddImaginary + wi * oddReal;
          real[odd] = real[even] - rotatedReal;
          imaginary[odd] = imaginary[even] - rotatedImaginary;
          real[even] += rotatedReal;
          imaginary[even] += rotatedImaginary;
        }
      }
    }
  }

  /// Inverse transform, scaled by `1 / size`.
  void inverse(Float64List real, Float64List imaginary) {
    _checkBuffers(real, imaginary);
    for (var index = 0; index < size; index++) {
      imaginary[index] = -imaginary[index];
    }
    forward(real, imaginary);
    final scale = 1.0 / size;
    for (var index = 0; index < size; index++) {
      real[index] *= scale;
      imaginary[index] = -imaginary[index] * scale;
    }
  }

  void _checkBuffers(Float64List real, Float64List imaginary) {
    if (real.length != size || imaginary.length != size) {
      throw ArgumentError(
        'real and imaginary buffers must both have length $size',
      );
    }
  }

  static int _log2(int value) {
    var bits = 0;
    while ((1 << bits) < value) {
      bits++;
    }
    return bits;
  }

  static int _reverseBits(int value, int bits) {
    var reversed = 0;
    for (var index = 0; index < bits; index++) {
      reversed = (reversed << 1) | ((value >> index) & 1);
    }
    return reversed;
  }
}

/// Hann window value for [index] in a window of [length] samples.
double hannWindow(int index, int length) {
  if (length <= 1) return 1;
  return 0.5 * (1 - math.cos(2 * math.pi * index / (length - 1)));
}

/// Convenience magnitude spectrum for short, one-off analysis.
///
/// The returned list contains the non-negative frequencies
/// `0 .. fftSize / 2`, inclusive. The input is Hann-windowed and zero-padded
/// to [fftSize] when [fftSize] is larger than [samples].
List<double> magnitudeSpectrum(
  List<double> samples, {
  int? fftSize,
  bool applyWindow = true,
}) {
  final size = fftSize ?? _nextPowerOfTwo(samples.length);
  if (size < samples.length) {
    throw ArgumentError.value(
      fftSize,
      'fftSize',
      'must be at least the number of input samples',
    );
  }
  final real = Float64List(size);
  final imaginary = Float64List(size);
  for (var index = 0; index < samples.length; index++) {
    real[index] = applyWindow
        ? samples[index] * hannWindow(index, samples.length)
        : samples[index];
  }
  Fft(size).forward(real, imaginary);
  final bins = size ~/ 2 + 1;
  final magnitudes = List<double>.filled(bins, 0);
  for (var index = 0; index < bins; index++) {
    magnitudes[index] = math.sqrt(
      real[index] * real[index] + imaginary[index] * imaginary[index],
    );
  }
  return magnitudes;
}

int _nextPowerOfTwo(int value) {
  var result = 1;
  while (result < value) {
    result <<= 1;
  }
  return result;
}
