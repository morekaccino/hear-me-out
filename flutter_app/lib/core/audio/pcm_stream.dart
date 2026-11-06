import 'dart:math' as math;
import 'dart:typed_data';

/// Decodes interleaved PCM16 little-endian bytes and resamples them to a
/// single mono channel at [outputSampleRate].
///
/// The decoder is streaming and deterministic. It keeps partial samples,
/// partial channel frames, and the resampler history across [add] calls, so
/// any chunking of the same byte stream produces the same output.
///
/// There is no wall clock in this class. The caller derives time from
/// [outputSampleIndex] and [outputSampleRate].
class Pcm16StreamDecoder {
  Pcm16StreamDecoder({
    required this.inputSampleRate,
    required this.channels,
    required this.outputSampleRate,
    this.maxFrames,
  }) : assert(inputSampleRate > 0, 'inputSampleRate must be positive'),
       assert(outputSampleRate > 0, 'outputSampleRate must be positive'),
       assert(channels > 0, 'channels must be positive'),
       assert(maxFrames == null || maxFrames > 0, 'maxFrames must be positive');

  final int inputSampleRate;
  final int channels;
  final int outputSampleRate;

  /// Maximum number of output samples returned by one [add] call.
  ///
  /// When null, [add] returns every sample it can produce. Extra output is
  /// buffered and returned by the next [add] or by [flush].
  final int? maxFrames;

  /// Mono input samples retained for interpolation.
  final List<double> _mono = <double>[];

  /// Output samples produced but not yet returned.
  final List<double> _ready = <double>[];

  /// Absolute input frame index of `_mono[0]`.
  int _monoBase = 0;

  /// Absolute index of the next output sample to produce.
  int _nextOutput = 0;

  /// Number of output samples returned to the caller.
  int _emitted = 0;

  int? _pendingByte;
  double _channelSum = 0;
  int _channelCount = 0;

  /// Number of output samples returned by [add] and [flush].
  int get framesEmitted => _emitted;

  /// Index of the next output sample the caller will receive.
  int get outputSampleIndex => _emitted;

  /// Feed raw interleaved PCM16 little-endian bytes in any chunking.
  List<double> add(Uint8List bytes) {
    if (bytes.isEmpty) return const <double>[];

    var index = 0;
    final pending = _pendingByte;
    _pendingByte = null;
    if (pending != null) {
      _addRawSample(pending | (bytes[0] << 8));
      index = 1;
    }
    for (; index + 1 < bytes.length; index += 2) {
      _addRawSample(bytes[index] | (bytes[index + 1] << 8));
    }
    if (index < bytes.length) {
      _pendingByte = bytes[index];
    }

    _generate();
    return _takeReady();
  }

  /// Flush buffered output at the end of a stream.
  ///
  /// A partial PCM sample or partial channel frame cannot be recovered and is
  /// discarded. No output position beyond the last decoded input frame is
  /// extrapolated, so no sample is emitted twice.
  List<double> flush() {
    _channelSum = 0;
    _channelCount = 0;
    _pendingByte = null;
    _generate();

    final tail = List<double>.of(_ready);
    _ready.clear();
    _emitted += tail.length;
    return tail;
  }

  void _addRawSample(int raw) {
    final signed = raw >= 0x8000 ? raw - 0x10000 : raw;
    _channelSum += signed / 32768.0;
    _channelCount++;
    if (_channelCount < channels) return;

    _mono.add(_channelSum / channels);
    _channelSum = 0;
    _channelCount = 0;
  }

  void _generate() {
    final ratio = inputSampleRate / outputSampleRate;
    while (true) {
      final position = _nextOutput * ratio;
      final left = position.floor();
      final offset = left - _monoBase;
      if (offset + 1 >= _mono.length) break;

      final fraction = position - left;
      final first = _mono[offset];
      final second = _mono[offset + 1];
      _ready.add(first + (second - first) * fraction);
      _nextOutput++;
    }
    _trimHistory(ratio);
  }

  void _trimHistory(double ratio) {
    final keepFrom = math.max(0, (_nextOutput * ratio).floor() - 1);
    final drop = keepFrom - _monoBase;
    if (drop <= 0) return;

    final count = math.min(drop, _mono.length);
    _mono.removeRange(0, count);
    _monoBase += count;
  }

  List<double> _takeReady() {
    if (_ready.isEmpty) return const <double>[];
    final limit = maxFrames;
    final count = limit == null
        ? _ready.length
        : math.min(limit, _ready.length);
    if (count == 0) return const <double>[];

    final out = _ready.sublist(0, count);
    _ready.removeRange(0, count);
    _emitted += count;
    return out;
  }
}
