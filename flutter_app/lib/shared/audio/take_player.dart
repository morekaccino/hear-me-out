import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Plays one stored WAV take. Kept behind an interface so widget tests never
/// touch a platform player.
abstract interface class TakePlayer {
  Future<void> playWav(Uint8List bytes);

  Future<void> stop();

  Future<void> dispose();
}

class AudioPlayersTakePlayer implements TakePlayer {
  AudioPlayersTakePlayer();

  final AudioPlayer _player = AudioPlayer();
  Future<void>? _pending;

  @override
  Future<void> playWav(Uint8List bytes) {
    return _pending = _play(bytes);
  }

  Future<void> _play(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes, mimeType: 'audio/wav'), volume: 0.9);
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // A platform player may already be released.
    }
  }

  @override
  Future<void> dispose() async {
    await _pending;
    await _player.dispose();
  }
}
