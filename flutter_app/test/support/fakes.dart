import 'dart:async';
import 'dart:convert';

import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';

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
  FakePitchSource({this.permission = true});

  final bool permission;
  final _controller = StreamController<PitchFrame>.broadcast();
  bool started = false;
  bool disposed = false;

  @override
  Stream<PitchFrame> get frames => _controller.stream;

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<bool> start() async {
    started = true;
    return permission;
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
  FakePitchSourceFactory({this.permission = true});

  final bool permission;
  final created = <FakePitchSource>[];

  PitchSource call() {
    final source = FakePitchSource(permission: permission);
    created.add(source);
    return source;
  }
}
