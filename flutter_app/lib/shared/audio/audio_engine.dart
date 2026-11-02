import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../core/audio/synth.dart';
import '../../core/music/sound_spec.dart';

/// Plays generated ear-training stimuli. Kept behind an interface so widget
/// tests never touch a platform player.
abstract interface class AudioEngine {
  Future<void> play(SoundSpec spec);

  Future<void> stop();

  Future<void> dispose();
}

class AudioPlayersSpecEngine implements AudioEngine {
  AudioPlayersSpecEngine();

  final AudioPlayer _player = AudioPlayer();
  Future<void>? _pending;

  @override
  Future<void> play(SoundSpec spec) {
    return _pending = _play(spec);
  }

  Future<void> _play(SoundSpec spec) async {
    try {
      await _player.stop();
      final bytes = synthesizeWav(spec);
      await _player.play(BytesSource(bytes), volume: 0.85);
    } catch (_) {
      // A platform may not support in-memory sources. The visual question still
      // works; the practice screen can fall back to a metronome or text prompt.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _pending;
    await _player.dispose();
  }
}
