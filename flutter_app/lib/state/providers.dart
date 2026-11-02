import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/pitch_source.dart';
import '../shared/audio/audio_engine.dart';
import '../shared/audio/sound_service.dart';

typedef PitchSourceFactory = PitchSource Function();

final pitchSourceFactoryProvider = Provider<PitchSourceFactory>(
  (ref) => RecordPitchSource.new,
);

/// Time to ignore at the start of a mic exercise so the previous note's tail
/// cannot trigger an answer. Tests set this to zero.
final lessonGraceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 250),
);

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioPlayersSoundService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = AudioPlayersSpecEngine();
  ref.onDispose(() {
    unawaited(engine.dispose());
  });
  return engine;
});
