import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/phrase_objectives.dart';
import '../../content/practice_session_factory.dart';
import '../../core/audio/phrase_scorer.dart';
import '../../core/audio/scored_take_gate.dart';
import '../../core/learning/practice_session.dart';
import '../../core/learning/progress.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import 'today_content.dart';

/// Supplies the wall clock to one Today session.
///
/// Tests override this with a mutable clock so every start, tick, pause, and
/// finish is deterministic. The session aggregate never reads the clock itself.
typedef TodayClock = DateTime Function();

final todayClockProvider = Provider<TodayClock>((ref) => DateTime.now);

/// Whether today is a performance day.
///
/// Recording is deliberately not every-session behaviour. The default is false,
/// so an Apply take is unscored practice unless a caller opts in. No screen
/// turns this on automatically; a future performance-day scheduler owns that.
final todayPerformanceDayProvider = Provider<bool>((ref) => false);

/// The T2.5 scored-take gate for a Today take.
///
/// The default is closed. A take only updates phrase progress when wired
/// headphones are confirmed or a calibration report verified the clock.
final todayScoredTakeGateProvider = Provider<ScoredTakeGate>(
  (ref) => const ScoredTakeGate(),
);

/// Phrase content available to the Today screen.
///
/// The shared registry is empty until a content loader registers parsed scores;
/// tests inject a local registry. Today never builds a second registry.
final todayPhraseRegistryProvider = Provider<PhraseObjectiveRegistry>(
  (ref) => ref.watch(phraseRegistryProvider),
);

/// Everything the Today screen renders for one session.
///
/// [session] owns the plan and the elapsed/instrument clocks. The remaining
/// fields are UI state only: no metric here is invented, and none of it is
/// persisted except the real practice completion and phrase evidence the
/// controller sends through `AppController`.
class TodayState {
  const TodayState({
    required this.session,
    required this.targetReason,
    required this.performanceDay,
    required this.gate,
    this.selfRating = 0,
    this.lastTake,
    this.lastTakeSaved = false,
    this.lastCorrection,
    this.earlyEnded = false,
    this.completedRecorded = false,
  });

  final PracticeSession session;
  final String targetReason;
  final bool performanceDay;
  final ScoredTakeGate gate;

  /// 0 means the learner has not rated the session yet. 1-3 is the self-rating.
  final int selfRating;

  /// The last phrase take the caller handed to the controller, if any.
  final PhraseResult? lastTake;

  /// True only when that take was determinate, gate-open, and saved.
  final bool lastTakeSaved;

  /// The one correction associated with [lastTake], when the caller has one.
  final String? lastCorrection;

  /// True when the learner ended the session before the stop point.
  final bool earlyEnded;

  /// True once the completion was sent to the app controller.
  final bool completedRecorded;

  TodayState copyWith({
    PracticeSession? session,
    String? targetReason,
    bool? performanceDay,
    ScoredTakeGate? gate,
    int? selfRating,
    PhraseResult? lastTake,
    bool? lastTakeSaved,
    String? lastCorrection,
    bool clearLastCorrection = false,
    bool? earlyEnded,
    bool? completedRecorded,
  }) {
    return TodayState(
      session: session ?? this.session,
      targetReason: targetReason ?? this.targetReason,
      performanceDay: performanceDay ?? this.performanceDay,
      gate: gate ?? this.gate,
      selfRating: selfRating ?? this.selfRating,
      lastTake: lastTake ?? this.lastTake,
      lastTakeSaved: lastTakeSaved ?? this.lastTakeSaved,
      lastCorrection: clearLastCorrection
          ? null
          : lastCorrection ?? this.lastCorrection,
      earlyEnded: earlyEnded ?? this.earlyEnded,
      completedRecorded: completedRecorded ?? this.completedRecorded,
    );
  }
}

/// Owns the one Today [PracticeSession] and its UI state.
///
/// The controller is the only writer of the session clock. The screen calls
/// [tick] once a second while the session runs; tests call the same methods with
/// a supplied clock. Completion is recorded once through
/// `AppController.recordTodayPractice`, which uses the existing practice path
/// and T2.10's measured-time/optional-habit API. The Today surface shows no XP,
/// streak, gems, or quests; the shared habit API may still advance the user's
/// optional streak in the background, exactly as the weekly goal does
/// elsewhere.
class TodayController extends Notifier<TodayState> {
  late TodayClock _clock;
  bool _completionRecorded = false;

  @override
  TodayState build() {
    _completionRecorded = false;
    _clock = ref.read(todayClockProvider);
    final progress = _progress();
    final now = _clock();
    final session = buildPracticeSession(progress: progress, now: now);
    return TodayState(
      session: session,
      targetReason: todayTargetReason(progress, session.target, now),
      performanceDay: ref.read(todayPerformanceDayProvider),
      gate: ref.read(todayScoredTakeGateProvider),
    );
  }

  ProgressState _progress() =>
      ref.read(appControllerProvider).asData?.value.progress ??
      ProgressState.fresh();

  /// Changes the selected plan length before the clock starts.
  ///
  /// The target and the maintenance selection are preserved, so changing the
  /// plan never silently switches to a different piece.
  void setLength(PracticeSessionLength length) {
    final current = state;
    if (current.session.isStarted || current.session.length == length) return;
    state = current.copyWith(
      session: _sessionLike(current.session, length: length),
    );
  }

  /// Adds or removes the maintenance block before the clock starts.
  ///
  /// A five-minute maintenance day becomes six minutes. Ten- and twenty-minute
  /// plans keep their selected length and place the maintenance block at the
  /// end, exactly as `buildPracticePlan` defines it. The control is a no-op when
  /// no previously learned target exists.
  void setMaintenanceDay(bool enabled) {
    final current = state;
    if (current.session.isStarted) return;
    if (current.session.maintenanceTarget == null) return;
    if (current.session.isMaintenanceDay == enabled) return;
    state = current.copyWith(
      session: _sessionLike(current.session, isMaintenanceDay: enabled),
    );
  }

  PracticeSession _sessionLike(
    PracticeSession base, {
    PracticeSessionLength? length,
    bool? isMaintenanceDay,
  }) {
    return PracticeSession(
      target: base.target,
      length: length ?? base.length,
      isMaintenanceDay: isMaintenanceDay ?? base.isMaintenanceDay,
      maintenanceTarget: base.maintenanceTarget,
    );
  }

  /// Starts the clock. A second call is a no-op.
  void start({DateTime? now}) {
    final current = state;
    if (current.session.isStarted) return;
    current.session.start(now ?? _clock());
    state = current.copyWith();
  }

  void pause({DateTime? now}) {
    final current = state;
    if (!current.session.isRunning) return;
    current.session.pause(now ?? _clock());
    state = current.copyWith();
    // `PracticeSession.pause` accounts the elapsed interval first. That
    // interval can cross the stop point and finish the session, so completion
    // must be recorded here as well as on tick/advance/early-end.
    _recordCompletionIfNeeded();
  }

  void resume({DateTime? now}) {
    final current = state;
    if (!current.session.isPaused) return;
    current.session.resume(now ?? _clock());
    state = current.copyWith();
  }

  /// Drops the gap while the Today surface was detached (for example, another
  /// tab) without counting it as guitar time. No-op unless the clock is running.
  void resyncClock({DateTime? now}) {
    final current = state;
    if (!current.session.isRunning) return;
    current.session.resyncClock(now ?? _clock());
  }

  /// Accounts elapsed time up to the supplied clock and advances any block
  /// whose budget has passed.
  void tick({DateTime? now}) {
    final current = state;
    if (!current.session.isRunning) return;
    current.session.tick(now ?? _clock());
    state = current.copyWith();
    _recordCompletionIfNeeded();
  }

  /// Moves to the next block, accounting the time played in the current one.
  void advance({DateTime? now}) {
    final current = state;
    if (!current.session.isStarted || current.session.isFinished) return;
    current.session.advance(now: now ?? _clock());
    state = current.copyWith();
    _recordCompletionIfNeeded();
  }

  /// Ends the session early and reaches the clear stop point.
  ///
  /// The learner keeps the real instrument time they played; nothing is
  /// punished, and the screen states that stopping early is okay.
  void finishEarly() {
    final current = state;
    if (current.session.isFinished) return;
    final now = _clock();
    final hadTimeLeft = !current.session.stopPointReached;
    if (!current.session.isStarted) {
      current.session.start(now);
    } else {
      current.session.tick(now);
    }
    var guard = 0;
    while (!current.session.isFinished &&
        guard <= current.session.blocks.length + 1) {
      current.session.advance(now: now);
      guard++;
    }
    state = current.copyWith(earlyEnded: hadTimeLeft);
    _recordCompletionIfNeeded();
  }

  /// Starts a fresh session with the same length and maintenance choice.
  void restart() {
    final previous = state.session;
    final progress = _progress();
    final now = _clock();
    final session = buildPracticeSession(
      progress: progress,
      now: now,
      length: previous.length,
      isMaintenanceDay: previous.isMaintenanceDay,
    );
    _completionRecorded = false;
    state = TodayState(
      session: session,
      targetReason: todayTargetReason(progress, session.target, now),
      performanceDay: ref.read(todayPerformanceDayProvider),
      gate: ref.read(todayScoredTakeGateProvider),
    );
  }

  /// Records the learner's 1-3 self-rating. 0 clears it.
  void rateSession(int rating) {
    if (rating < 1 || rating > 3) return;
    state = state.copyWith(selfRating: rating);
  }

  /// Records one completed phrase take through the existing progress path.
  ///
  /// A take is saved only on a performance day, when it is determinate and
  /// complete, and when the T2.5 gate is open. An indeterminate, incomplete,
  /// gate-closed, or non-performance-day take remains practice only: it is
  /// shown to the learner but never calls `recordPhraseResult`.
  Future<bool> savePhraseResult({
    required String phraseId,
    required PhraseResult result,
    required int tempoBpm,
    int? targetTempoBpm,
    String? pieceId,
    int? contentVersion,
    String? correction,
  }) async {
    final allowed =
        state.performanceDay &&
        state.gate.allowsScoredTake &&
        result.complete &&
        result.outcome != AttemptOutcome.indeterminate;
    if (!allowed) {
      state = state.copyWith(
        lastTake: result,
        lastTakeSaved: false,
        lastCorrection: correction,
        clearLastCorrection: correction == null,
      );
      return false;
    }

    var saved = false;
    try {
      await ref.read(appControllerProvider.future);
      saved = await ref
          .read(appControllerProvider.notifier)
          .recordPhraseResult(
            phraseId: phraseId,
            result: result,
            tempoBpm: tempoBpm,
            targetTempoBpm: targetTempoBpm,
            pieceId: pieceId,
            contentVersion: contentVersion,
          );
    } catch (_) {
      saved = false;
    }
    state = state.copyWith(
      lastTake: result,
      lastTakeSaved: saved,
      lastCorrection: correction,
      clearLastCorrection: correction == null,
    );
    return saved;
  }

  void _recordCompletionIfNeeded() {
    if (!state.session.isFinished || _completionRecorded) return;
    _completionRecorded = true;
    final instrumentTime = state.session.instrumentElapsed;
    state = state.copyWith(completedRecorded: true);
    unawaited(
      ref
          .read(appControllerProvider.notifier)
          .recordTodayPractice(
            instrumentTime: instrumentTime,
            completedAt: _clock(),
          ),
    );
  }
}

final todayControllerProvider = NotifierProvider<TodayController, TodayState>(
  TodayController.new,
);
