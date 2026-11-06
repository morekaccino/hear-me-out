import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

/// Feeds pre-recorded PCM16 chunks through the [PcmCapture] seam.
///
/// The chunks are emitted on a zero-duration timer after [startStream], so the
/// phrase recorder has subscribed before any bytes arrive.
class FakePcmCapture implements PcmCapture {
  FakePcmCapture({
    this.permission = true,
    this.config,
    List<Uint8List> chunks = const <Uint8List>[],
    Set<int> failSampleRates = const <int>{},
  }) : chunks = List<Uint8List>.from(chunks),
       failSampleRates = Set<int>.from(failSampleRates);

  bool permission;
  PcmCaptureConfig? config;
  List<Uint8List> chunks;
  Set<int> failSampleRates;

  int permissionChecks = 0;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  final List<int> startAttempts = <int>[];

  void Function(PcmCaptureConfig config)? _onConfigChanged;
  StreamController<Uint8List>? _controller;

  @override
  Future<bool> hasPermission() async {
    permissionChecks++;
    return permission;
  }

  @override
  Future<void> setOnConfigChanged(
    void Function(PcmCaptureConfig config)? callback,
  ) async {
    _onConfigChanged = callback;
  }

  @override
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
  }) async {
    startCalls++;
    startAttempts.add(sampleRate);
    if (failSampleRates.contains(sampleRate)) {
      throw StateError('Platform refused $sampleRate Hz');
    }
    final controller = StreamController<Uint8List>(sync: true);
    _controller = controller;
    _onConfigChanged?.call(
      config ?? PcmCaptureConfig(sampleRate: sampleRate, channels: channels),
    );
    final pending = List<Uint8List>.from(chunks);
    Timer.run(() {
      for (final chunk in pending) {
        if (!controller.isClosed) controller.add(chunk);
      }
    });
    return controller.stream;
  }

  void emit(Uint8List bytes) {
    final controller = _controller;
    if (controller != null && !controller.isClosed) controller.add(bytes);
  }

  /// Simulates a late platform format callback after the stream started.
  void changeConfig(PcmCaptureConfig next) {
    config = next;
    _onConfigChanged?.call(next);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      // The platform recorder stops independently of stream teardown. Do not
      // await close here: a pending subscription cancel can complete later.
      unawaited(controller.close());
    }
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    final controller = _controller;
    _controller = null;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }
}

/// Encodes normalized mono samples as little-endian PCM16.
Uint8List pcm16Bytes(List<double> samples) {
  final buffer = ByteData(samples.length * 2);
  for (var index = 0; index < samples.length; index++) {
    final value = samples[index].clamp(-1.0, 1.0);
    buffer.setInt16(index * 2, (value * 32767).round(), Endian.little);
  }
  return buffer.buffer.asUint8List();
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
