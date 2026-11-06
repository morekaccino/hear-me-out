import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/audio/pitch_source.dart';
import '../core/media/media_store.dart';
import '../core/media/media_store_factory.dart';
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

/// Local recording store.
///
/// On IO the store lives under the application support directory. On web it is
/// IndexedDB. Tests override this provider with `MemoryMediaStore`; nothing here
/// starts a recorder or touches the microphone.
final mediaStoreProvider = FutureProvider<MediaStore>((ref) async {
  if (kIsWeb) {
    return createMediaStore();
  }
  final supportDirectory = await getApplicationSupportDirectory();
  return createMediaStore(directory: '${supportDirectory.path}/media');
});

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
