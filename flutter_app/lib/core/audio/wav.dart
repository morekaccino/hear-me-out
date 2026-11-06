import 'dart:typed_data';

/// A decoded PCM audio buffer.
///
/// [samples] holds interleaved samples in the range -1.0 to 1.0. The channel
/// order is preserved exactly as it appears in the source file. Mono and
/// multichannel files are supported; nothing is downmixed here.
class WavData {
  WavData({
    required this.sampleRate,
    required this.channels,
    required this.samples,
  }) {
    if (sampleRate <= 0) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
    }
    if (channels <= 0) {
      throw ArgumentError.value(channels, 'channels', 'must be positive');
    }
    if (samples.length % channels != 0) {
      throw ArgumentError.value(
        samples.length,
        'samples',
        'must contain a whole number of $channels-channel frames',
      );
    }
  }

  final int sampleRate;
  final int channels;

  /// Interleaved samples in the range -1.0 to 1.0.
  final List<double> samples;

  /// Number of complete sample frames (one frame per sample time).
  int get frameCount => samples.length ~/ channels;

  Duration get duration => Duration(
    microseconds: frameCount == 0
        ? 0
        : (frameCount * 1000000 / sampleRate).round(),
  );
}

const int _wavHeaderBytes = 44;
const int _pcmFormatTag = 1;
const int _pcm16Bits = 16;

/// Parses a little-endian PCM16 RIFF/WAVE file.
///
/// Unknown ancillary chunks are skipped. Non-PCM, non-16-bit, and malformed
/// files throw a [FormatException] with a message that names the problem.
WavData parseWav(Uint8List bytes) {
  if (bytes.length < 12) {
    throw const FormatException(
      'Not a WAV file: header is shorter than 12 bytes.',
    );
  }

  final view = ByteData.sublistView(bytes);
  if (_chunkId(bytes, 0) != 'RIFF') {
    throw const FormatException('Not a RIFF file: missing RIFF header.');
  }
  if (_chunkId(bytes, 8) != 'WAVE') {
    throw const FormatException('Not a WAVE file: missing WAVE form type.');
  }

  int? sampleRate;
  int? channels;
  int? blockAlign;
  var sawFormat = false;
  var dataOffset = -1;
  var dataSize = 0;

  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = _chunkId(bytes, offset);
    final size = view.getUint32(offset + 4, Endian.little);
    final payloadStart = offset + 8;
    final available = bytes.length - payloadStart;
    if (size > available) {
      throw FormatException(
        'Truncated WAV: "$id" chunk declares $size bytes but only '
        '$available remain.',
      );
    }

    if (id == 'fmt ') {
      if (size < 16) {
        throw FormatException(
          'Malformed WAV: fmt chunk is $size bytes; at least 16 are required.',
        );
      }
      final formatTag = view.getUint16(payloadStart, Endian.little);
      if (formatTag != _pcmFormatTag) {
        throw FormatException(
          'Unsupported WAV encoding: format tag $formatTag; only PCM (1) is '
          'supported.',
        );
      }
      channels = view.getUint16(payloadStart + 2, Endian.little);
      sampleRate = view.getUint32(payloadStart + 4, Endian.little);
      blockAlign = view.getUint16(payloadStart + 12, Endian.little);
      final bits = view.getUint16(payloadStart + 14, Endian.little);
      if (bits != _pcm16Bits) {
        throw FormatException(
          'Unsupported WAV bit depth: $bits; only 16-bit PCM is supported.',
        );
      }
      if (channels <= 0) {
        throw FormatException(
          'Malformed WAV: invalid channel count $channels.',
        );
      }
      if (sampleRate <= 0) {
        throw FormatException(
          'Malformed WAV: invalid sample rate $sampleRate.',
        );
      }
      if (blockAlign != channels * 2) {
        throw FormatException(
          'Malformed WAV: block alignment $blockAlign does not match '
          '$channels channels of 16-bit audio.',
        );
      }
      sawFormat = true;
    } else if (id == 'data') {
      dataOffset = payloadStart;
      dataSize = size;
    }

    offset = payloadStart + size + (size.isOdd ? 1 : 0);
  }

  if (!sawFormat ||
      sampleRate == null ||
      channels == null ||
      blockAlign == null) {
    throw const FormatException('Malformed WAV: missing fmt chunk.');
  }
  if (dataOffset < 0) {
    throw const FormatException('Malformed WAV: missing data chunk.');
  }
  final channelCount = channels;
  final frames = dataSize ~/ blockAlign;
  if (dataSize % blockAlign != 0) {
    throw FormatException(
      'Malformed WAV: data chunk is $dataSize bytes, which is not a whole '
      'number of $blockAlign-byte frames.',
    );
  }

  final samples = Float64List(frames * channelCount);
  for (var frame = 0; frame < frames; frame++) {
    for (var channel = 0; channel < channelCount; channel++) {
      final index = dataOffset + (frame * channelCount + channel) * 2;
      samples[frame * channelCount + channel] =
          view.getInt16(index, Endian.little) / 32768.0;
    }
  }

  return WavData(
    sampleRate: sampleRate,
    channels: channelCount,
    samples: samples,
  );
}

/// Encodes [data] as a little-endian PCM16 RIFF/WAVE file.
///
/// Samples are clamped to -1.0..1.0 before quantization. The channel order is
/// preserved.
Uint8List encodeWavPcm16(WavData data) {
  final dataSize = data.samples.length * 2;
  final buffer = ByteData(_wavHeaderBytes + dataSize);
  var offset = 0;

  void writeString(String value) {
    for (final codeUnit in value.codeUnits) {
      buffer.setUint8(offset++, codeUnit);
    }
  }

  void writeUint32(int value) {
    buffer.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  void writeUint16(int value) {
    buffer.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  final blockAlign = data.channels * 2;
  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(_pcmFormatTag);
  writeUint16(data.channels);
  writeUint32(data.sampleRate);
  writeUint32(data.sampleRate * blockAlign);
  writeUint16(blockAlign);
  writeUint16(_pcm16Bits);
  writeString('data');
  writeUint32(dataSize);

  for (final sample in data.samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    buffer.setInt16(offset, (clamped * 32767).round(), Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

String _chunkId(Uint8List bytes, int offset) {
  return String.fromCharCodes(bytes, offset, offset + 4);
}
