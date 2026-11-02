import 'dart:async';
import 'dart:convert';

import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/sound_spec.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/shared/audio/audio_engine.dart';
import 'package:hear_me_out/shared/audio/sound_service.dart';

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([ProgressState? initial])
    : _value = initial == null
          ? null
          : ProgressState.fromJson(
              jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>,
            );

  ProgressState? _value;

  ProgressState? get value => _value;

  @override
  Future<ProgressState?> load() async => _value;

  @override
  Future<void> save(ProgressState progress) async {
    _value = ProgressState.fromJson(
      jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> clear() async => _value = null;
}

class FakePitchSource implements PitchSource {
  FakePitchSource({this.permission = true, this.startResult, this.startGate});

  final bool permission;
  final bool? startResult;
  final Completer<bool>? startGate;
  final _controller = StreamController<PitchFrame>.broadcast();
  bool started = false;
  bool disposed = false;
  int permissionChecks = 0;

  @override
  Stream<PitchFrame> get frames => _controller.stream;

  @override
  Future<bool> ensurePermission() async {
    permissionChecks++;
    return permission;
  }

  @override
  Future<bool> start() async {
    started = true;
    final gate = startGate;
    if (gate != null) return gate.future;
    return startResult ?? permission;
  }

  @override
  Future<void> stop() async {
    started = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }

  void emit(PitchFrame frame) {
    if (!_controller.isClosed) _controller.add(frame);
  }
}

class FakePitchSourceFactory {
  FakePitchSourceFactory({
    this.permission = true,
    this.startResult,
    this.startGate,
  });

  final bool permission;
  final bool? startResult;
  final Completer<bool>? startGate;
  final created = <FakePitchSource>[];

  PitchSource call() {
    final source = FakePitchSource(
      permission: permission,
      startResult: startResult,
      startGate: startGate,
    );
    created.add(source);
    return source;
  }
}

class FakeSoundService implements SoundService {
  @override
  bool enabled = true;

  final played = <Sfx>[];

  @override
  Future<void> preload() async {}

  @override
  Future<void> play(Sfx sound) async {
    if (enabled) played.add(sound);
  }

  @override
  Future<void> playSequence(Iterable<Sfx> sounds) async {
    for (final sound in sounds) {
      await play(sound);
    }
  }

  @override
  Future<void> dispose() async {}
}

class FakeAudioEngine implements AudioEngine {
  final played = <SoundSpec>[];
  int stopCount = 0;

  @override
  Future<void> play(SoundSpec spec) async {
    played.add(spec);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}
