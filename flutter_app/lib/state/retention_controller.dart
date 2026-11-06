import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/retention/retention_event.dart';
import '../core/retention/retention_log.dart';
import '../core/storage/retention_store.dart';

/// The UI-facing retention state: whether logging is on and what is stored.
class RetentionState {
  const RetentionState({required this.optIn, required this.log});

  final bool optIn;
  final RetentionLog log;

  int get eventCount => log.length;

  RetentionState copyWith({bool? optIn, RetentionLog? log}) =>
      RetentionState(optIn: optIn ?? this.optIn, log: log ?? this.log);
}

/// Owns the local, opt-in retention log.
///
/// Every method is best-effort: storage failures never throw into a lesson or
/// onboarding. When [RetentionState.optIn] is false, writes are a no-op.
///
/// Writes run through one queue because the app fires hooks without awaiting
/// them. Two hooks reading the same state and saving could otherwise lose an
/// event.
class RetentionController extends AsyncNotifier<RetentionState> {
  late RetentionStore _store;
  Future<void> _writes = Future<void>.value();

  @override
  Future<RetentionState> build() async {
    _store = ref.watch(retentionStoreProvider);
    final data = await _store.load();
    return RetentionState(optIn: data.optIn, log: data.log);
  }

  Future<void> setOptIn(bool value, {DateTime? at}) => _enqueue(() async {
    final current = await future;
    if (current.optIn == value) return;
    var log = current.log;
    if (value && !log.hasEvent(RetentionEventName.appOpen)) {
      // Opt-in starts the retention clock at the moment of consent so D1,
      // D7, and D30 have a real install day.
      log = log.record(RetentionEventName.appOpen, at: at ?? DateTime.now());
    }
    final next = current.copyWith(optIn: value, log: log);
    state = AsyncData(next);
    await _save(next);
  });

  Future<void> record(RetentionEventName name, {DateTime? at}) =>
      _enqueue(() => _recordLocked(name, at));

  /// Records [appOpen] at most once per local day.
  Future<void> recordAppOpen({DateTime? at}) => _enqueue(() async {
    final current = await future;
    final now = at ?? DateTime.now();
    if (!current.optIn) return;
    if (current.log.hasEventOnLocalDay(RetentionEventName.appOpen, now)) {
      return;
    }
    await _recordLocked(RetentionEventName.appOpen, now);
  });

  /// Records [dailyActive] at most once per local day. Called when a session
  /// completes, separate from merely opening the app.
  Future<void> recordDailyActive({DateTime? at}) => _enqueue(() async {
    final current = await future;
    final now = at ?? DateTime.now();
    if (!current.optIn) return;
    if (current.log.hasEventOnLocalDay(RetentionEventName.dailyActive, now)) {
      return;
    }
    await _recordLocked(RetentionEventName.dailyActive, now);
  });

  Future<void> recordOnboardingStart({DateTime? at}) =>
      _recordOnce(RetentionEventName.onboardingStart, at);

  Future<void> recordOnboardingComplete({DateTime? at}) =>
      _recordOnce(RetentionEventName.onboardingComplete, at);

  Future<void> recordFirstNote({DateTime? at}) =>
      _recordOnce(RetentionEventName.firstNote, at);

  /// API for T2.5. Call only from the real phrase path.
  Future<void> recordFirstPhrase({DateTime? at}) =>
      _recordOnce(RetentionEventName.firstPhrase, at);

  /// API for T4.2. Call only from the real recording path.
  Future<void> recordFirstRecording({DateTime? at}) =>
      _recordOnce(RetentionEventName.firstRecording, at);

  Future<void> _recordOnce(RetentionEventName name, DateTime? at) =>
      _enqueue(() async {
        final current = await future;
        if (!current.optIn || current.log.hasEvent(name)) return;
        await _recordLocked(name, at);
      });

  /// Deletes every stored event but keeps the install id and opt-in choice.
  Future<void> erase() => _enqueue(() async {
    final current = await future;
    final next = current.copyWith(log: current.log.clear());
    state = AsyncData(next);
    await _save(next);
  });

  Future<void> _recordLocked(RetentionEventName name, DateTime? at) async {
    final current = await future;
    if (!current.optIn) return;
    final next = current.copyWith(
      log: current.log.record(name, at: at ?? DateTime.now()),
    );
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> _save(RetentionState next) async {
    try {
      await _store.save(RetentionStoredData(optIn: next.optIn, log: next.log));
    } catch (_) {
      // Keep the in-memory state; the user can retry.
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _writes.then((_) async {
      try {
        await action();
      } catch (_) {
        // Instrumentation is never allowed to break a lesson.
      }
    });
    _writes = result;
    return result;
  }
}

final retentionControllerProvider =
    AsyncNotifierProvider<RetentionController, RetentionState>(
      RetentionController.new,
    );
