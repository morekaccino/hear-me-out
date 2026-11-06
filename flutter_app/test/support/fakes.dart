import 'dart:async';
import 'dart:convert';

import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/onboarding_choices.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/sound_spec.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/retention/retention_log.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
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

class FakeOnboardingStore implements OnboardingStore {
  FakeOnboardingStore([this.value]);

  OnboardingChoices? value;
  int saveCount = 0;

  @override
  Future<OnboardingChoices?> load() async => value;

  @override
  Future<void> save(OnboardingChoices choices) async {
    value = choices;
    saveCount++;
  }

  @override
  Future<void> clear() async => value = null;
}

class MemoryRetentionStore implements RetentionStore {
  MemoryRetentionStore({
    bool optIn = false,
    String installId = 'test-install',
    List<RetentionEvent> events = const [],
  }) : value = RetentionStoredData(
         optIn: optIn,
         log: RetentionLog(installId: installId, events: events),
       );

  RetentionStoredData value;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<RetentionStoredData> load() async => value;

  @override
  Future<void> save(RetentionStoredData data) async {
    value = data;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    value = RetentionStoredData(optIn: value.optIn, log: value.log.clear());
    clearCount++;
  }
}

class FakePitchSource implements PitchSource {
  FakePitchSource({
    this.permission = true,
    this.startResult,
    this.startGate,
    this.onStart,
  });

  final bool permission;
  final bool? startResult;
  final Completer<bool>? startGate;
  final void Function()? onStart;
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
    onStart?.call();
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
    this.onStart,
  });

  final bool permission;
  final bool? startResult;
  final Completer<bool>? startGate;
  final void Function()? onStart;
  final created = <FakePitchSource>[];

  PitchSource call() {
    final source = FakePitchSource(
      permission: permission,
      startResult: startResult,
      startGate: startGate,
      onStart: onStart,
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
  final events = <String>[];
  int stopCount = 0;

  /// When set, [play] stays pending until the gate completes. This models the
  /// real player: the future resolves when playback starts, not when it ends.
  Completer<void>? playGate;

  /// When set, [stop] stays pending until the gate completes. This models a
  /// slow platform stop so mic-start races are testable.
  Completer<void>? stopGate;

  @override
  Future<void> play(SoundSpec spec) async {
    played.add(spec);
    events.add('audio-play');
    final gate = playGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    events.add('audio-stop');
    final gate = stopGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> dispose() async {}
}
