import 'dart:typed_data';

import '../audio/wav.dart';

/// Turns the recorded mono samples into stored bytes.
///
/// V1 ships one implementation, [WavRecordingEncoder]. A future AAC encoder
/// must implement the same contract without opening a second recorder and must
/// not change the stored bytes of existing takes. See decision 0009.
abstract interface class RecordingEncoder {
  /// MIME type written to [MediaStore] and used for export.
  String get mimeType;

  /// File extension without the dot, used for export names.
  String get fileExtension;

  /// Encodes normalized mono samples in -1..1.
  Uint8List encode(List<double> samples, {required int sampleRate});
}

/// PCM16 RIFF/WAVE implementation. This is the only format V1 stores.
class WavRecordingEncoder implements RecordingEncoder {
  const WavRecordingEncoder();

  @override
  String get mimeType => 'audio/wav';

  @override
  String get fileExtension => 'wav';

  @override
  Uint8List encode(List<double> samples, {required int sampleRate}) {
    return encodeWavPcm16(
      WavData(sampleRate: sampleRate, channels: 1, samples: samples),
    );
  }
}
