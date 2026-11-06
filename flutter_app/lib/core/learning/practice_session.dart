import 'objective.dart';

/// The length the learner picked for a Today practice session.
enum PracticeSessionLength {
  five(5),
  ten(10),
  twenty(20);

  const PracticeSessionLength(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}

/// What one block in a practice session is for.
///
/// [setup] is preparation: tuning and posture, never a scored block. The
/// remaining roles follow plan section 5.1. [maintenance] is the previously
/// learned phrase that is added at the end of a maintenance day.
enum PracticeBlockRole {
  setup,
  technique,
  model,
  acquire,
  apply,
  maintenance,
  reflect,
}

/// One timed step in a practice session.
///
/// A block never owns a score or a scheduler. It points at one objective so the
/// UI and the future scoring layer can reuse the existing prompt and verifier
/// types without duplicating either.
class PracticeBlock {
  const PracticeBlock({
    required this.role,
    required this.title,
    required this.budget,
    required this.target,
    this.countsInstrumentTime = true,
  }) : assert(budget > Duration.zero);

  final PracticeBlockRole role;
  final String title;
  final Duration budget;

  /// The one thing this block exercises. For the main session blocks this is
  /// the session target; a maintenance block may name an earlier learned
  /// target instead.
  final ObjectiveRef target;

  /// False for listening, planning, and reflection, so elapsed instrument time
  /// is measured on the guitar rather than on prompt count.
  final bool countsInstrumentTime;

  bool get isPreparation => role == PracticeBlockRole.setup;
}

/// Where a session is in its lifecycle.
enum PracticeSessionStatus { notStarted, running, paused, finished }

/// One Today practice session.
///
/// The aggregate owns the plan, one target, and clock-driven state. It does not
/// know about notes, lessons, XP, or content packs, and it never reads
/// the wall clock. Callers pass every timestamp so the five-minute budget is
/// testable.
///
/// `LessonRun` remains the Reading Lab and single-note lesson engine. This type
/// is deliberately separate.
class PracticeSession {
  PracticeSession({
    required this.target,
    this.length = PracticeSessionLength.five,
    this.isMaintenanceDay = false,
    this.maintenanceTarget,
  }) : blocks = List.unmodifiable(
         buildPracticePlan(
           target: target,
           length: length,
           isMaintenanceDay: isMaintenanceDay,
           maintenanceTarget: maintenanceTarget,
         ),
       );

  /// The single objective for the whole session.
  final ObjectiveRef target;

  final PracticeSessionLength length;

  /// True when this session was chosen for a maintenance day. It extends the
  /// five-minute plan only when [maintenanceTarget] is available.
  final bool isMaintenanceDay;

  /// A previously learned objective for the maintenance block. Null means the
  /// block is omitted and the plan keeps its selected length.
  final ObjectiveRef? maintenanceTarget;

  final List<PracticeBlock> blocks;

  PracticeSessionStatus _status = PracticeSessionStatus.notStarted;
  int _index = 0;
  Duration _elapsed = Duration.zero;
  Duration _instrumentElapsed = Duration.zero;
  Duration _blockElapsed = Duration.zero;
  DateTime? _lastTickAt;

  PracticeSessionStatus get status => _status;

  bool get isStarted => _status != PracticeSessionStatus.notStarted;

  bool get isRunning => _status == PracticeSessionStatus.running;

  bool get isPaused => _status == PracticeSessionStatus.paused;

  bool get isFinished => _status == PracticeSessionStatus.finished;

  /// The clear end of the session. It is true once the plan is finished or
  /// the full time budget has been used.
  bool get stopPointReached => isFinished || _elapsed >= totalDuration;

  int get currentIndex => _index;

  PracticeBlock? get currentBlock =>
      isFinished || _index >= blocks.length ? null : blocks[_index];

  /// Total wall-clock time spent inside the plan.
  Duration get elapsed => _elapsed;

  /// Time actually spent with the guitar in hand.
  Duration get instrumentElapsed => _instrumentElapsed;

  Duration get totalDuration =>
      blocks.fold(Duration.zero, (total, block) => total + block.budget);

  Duration get instrumentTime => blocks
      .where((block) => block.countsInstrumentTime)
      .fold(Duration.zero, (total, block) => total + block.budget);

  /// Time left before the stop point. It is zero after a manual finish even if
  /// the learner skipped some of the plan.
  Duration get remaining {
    if (isFinished) return Duration.zero;
    final left = totalDuration - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  Duration get currentBlockRemaining {
    final block = currentBlock;
    if (block == null) return Duration.zero;
    final left = block.budget - _blockElapsed;
    return left.isNegative ? Duration.zero : left;
  }

  double get progress {
    if (isFinished) return 1;
    final total = totalDuration.inMicroseconds;
    if (total <= 0) return 1;
    return (_elapsed.inMicroseconds / total).clamp(0.0, 1.0);
  }

  double get currentBlockProgress {
    final block = currentBlock;
    if (block == null) return 1;
    final total = block.budget.inMicroseconds;
    if (total <= 0) return 1;
    return (_blockElapsed.inMicroseconds / total).clamp(0.0, 1.0);
  }

  /// Starts the clock. Calling it again after the session starts is a no-op.
  void start(DateTime now) {
    if (_status != PracticeSessionStatus.notStarted) return;
    _status = PracticeSessionStatus.running;
    _lastTickAt = now;
  }

  /// Accounts the time up to [now], then stops the clock.
  void pause(DateTime now) {
    if (_status != PracticeSessionStatus.running) return;
    _accountUntil(now);
    if (_status != PracticeSessionStatus.running) return;
    _status = PracticeSessionStatus.paused;
    _lastTickAt = null;
  }

  /// Restarts the clock from [now] without counting the paused interval.
  void resume(DateTime now) {
    if (_status != PracticeSessionStatus.paused) return;
    _status = PracticeSessionStatus.running;
    _lastTickAt = now;
  }

  /// Re-bases the running clock at [now] without counting the interval since
  /// the last tick.
  ///
  /// A UI may detach while a session is running, for example when the learner
  /// switches tabs. The gap was not attended practice time, so the returning
  /// screen drops it instead of charging it as instrument time. It is a no-op
  /// when the clock is not running.
  void resyncClock(DateTime now) {
    if (_status != PracticeSessionStatus.running) return;
    _lastTickAt = now;
  }

  /// Accounts elapsed time and advances through any blocks whose budget has
  /// passed. The clock is always supplied by the caller.
  void tick(DateTime now) {
    if (_status != PracticeSessionStatus.running) return;
    _accountUntil(now);
  }

  /// Moves to the next block without inventing time.
  ///
  /// When [now] is supplied and the session is running, the elapsed time up to
  /// [now] is accounted first, so a learner who taps "next" mid-block still
  /// earns the instrument time they just played. Callers that pass no [now]
  /// must call [tick] first or that time is not counted. Advancing past the last
  /// block reaches the stop point.
  void advance({DateTime? now}) {
    if (_status == PracticeSessionStatus.notStarted || isFinished) return;
    final indexBefore = _index;
    if (now != null && _status == PracticeSessionStatus.running) {
      _accountUntil(now);
    }
    if (isFinished || _index != indexBefore) return;
    _moveToNextBlock();
  }

  void _accountUntil(DateTime now) {
    final last = _lastTickAt;
    if (last == null) return;
    if (!now.isAfter(last)) {
      // A clock that stands still or steps backward must not add time. Keep the
      // last reading so a later monotonic tick is measured from it.
      return;
    }

    var delta = now.difference(last);
    _lastTickAt = now;

    final sessionLeft = totalDuration - _elapsed;
    if (sessionLeft <= Duration.zero) {
      _finish();
      return;
    }
    if (delta > sessionLeft) delta = sessionLeft;

    while (delta > Duration.zero && !isFinished && _index < blocks.length) {
      final block = blocks[_index];
      final blockLeft = block.budget - _blockElapsed;
      if (blockLeft <= Duration.zero) {
        _moveToNextBlock();
        continue;
      }

      final slice = delta < blockLeft ? delta : blockLeft;
      if (block.countsInstrumentTime) _instrumentElapsed += slice;
      _elapsed += slice;
      _blockElapsed += slice;
      delta -= slice;

      if (_blockElapsed >= block.budget) _moveToNextBlock();
    }

    if (_elapsed >= totalDuration) _finish();
  }

  void _moveToNextBlock() {
    if (isFinished) return;
    if (_index >= blocks.length - 1) {
      _finish();
      return;
    }
    _index++;
    _blockElapsed = Duration.zero;
  }

  void _finish() {
    _status = PracticeSessionStatus.finished;
    _lastTickAt = null;
  }
}

/// Builds the 5/10/20-minute block plan for [target].
///
/// The five-minute plan mirrors plan section 5.1: 30 seconds of setup, a
/// 60-second technique drill, 30 seconds of modelling, 90 seconds of
/// acquisition, 60 seconds of application, and 30 seconds of reflection. That
/// is 3 minutes 30 seconds of guitar time.
///
/// The ten- and twenty-minute plans keep the same block vocabulary and add
/// deeper acquisition and application time. They add a maintenance segment
/// only when [maintenanceTarget] names a previously learned objective; when it
/// is null the maintenance budget goes to the application block so the plan
/// still totals ten or twenty minutes. A five-minute maintenance day extends the
/// standard plan to six minutes only when a learned target is available.
List<PracticeBlock> buildPracticePlan({
  required ObjectiveRef target,
  required PracticeSessionLength length,
  bool isMaintenanceDay = false,
  ObjectiveRef? maintenanceTarget,
}) {
  final blocks = <PracticeBlock>[];

  switch (length) {
    case PracticeSessionLength.five:
      blocks.addAll(_fiveMinuteBlocks(target));
      if (isMaintenanceDay && maintenanceTarget != null) {
        blocks.add(
          PracticeBlock(
            role: PracticeBlockRole.maintenance,
            title: 'Maintenance: earlier phrase',
            budget: const Duration(minutes: 1),
            target: maintenanceTarget,
          ),
        );
      }
    case PracticeSessionLength.ten:
      blocks.addAll(_tenMinuteBlocks(target, maintenanceTarget));
    case PracticeSessionLength.twenty:
      blocks.addAll(_twentyMinuteBlocks(target, maintenanceTarget));
  }

  return List.unmodifiable(blocks);
}

List<PracticeBlock> _fiveMinuteBlocks(ObjectiveRef target) => [
  _block(
    PracticeBlockRole.setup,
    'Tune and set up',
    const Duration(seconds: 30),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.technique,
    'Technique warm-up',
    const Duration(minutes: 1),
    target,
  ),
  _block(
    PracticeBlockRole.model,
    'Listen and model',
    const Duration(seconds: 30),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.acquire,
    'Acquire: one bar',
    const Duration(seconds: 90),
    target,
  ),
  _block(
    PracticeBlockRole.apply,
    'Apply at target tempo',
    const Duration(minutes: 1),
    target,
  ),
  _block(
    PracticeBlockRole.reflect,
    'Reflect and plan',
    const Duration(seconds: 30),
    target,
    countsInstrumentTime: false,
  ),
];

List<PracticeBlock> _tenMinuteBlocks(
  ObjectiveRef target,
  ObjectiveRef? maintenance,
) => [
  _block(
    PracticeBlockRole.setup,
    'Tune and set up',
    const Duration(seconds: 30),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.technique,
    'Technique drill',
    const Duration(seconds: 90),
    target,
  ),
  _block(
    PracticeBlockRole.model,
    'Listen and model',
    const Duration(minutes: 1),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.acquire,
    'Acquire: first phrase',
    const Duration(seconds: 150),
    target,
  ),
  _block(
    PracticeBlockRole.acquire,
    'Acquire: second phrase',
    const Duration(seconds: 90),
    target,
  ),
  _block(
    PracticeBlockRole.apply,
    'Apply both phrases',
    maintenance == null
        ? const Duration(seconds: 150)
        : const Duration(seconds: 90),
    target,
  ),
  _block(
    PracticeBlockRole.reflect,
    'Reflect and plan',
    const Duration(seconds: 30),
    target,
    countsInstrumentTime: false,
  ),
  if (maintenance != null)
    _block(
      PracticeBlockRole.maintenance,
      'Maintenance: earlier phrase',
      const Duration(minutes: 1),
      maintenance,
    ),
];

List<PracticeBlock> _twentyMinuteBlocks(
  ObjectiveRef target,
  ObjectiveRef? maintenance,
) => [
  _block(
    PracticeBlockRole.setup,
    'Tune and set up',
    const Duration(minutes: 1),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.technique,
    'Technique deep drill',
    const Duration(minutes: 3),
    target,
  ),
  _block(
    PracticeBlockRole.model,
    'Listen and model',
    const Duration(seconds: 90),
    target,
    countsInstrumentTime: false,
  ),
  _block(
    PracticeBlockRole.acquire,
    'Acquire: first phrase',
    const Duration(minutes: 5),
    target,
  ),
  _block(
    PracticeBlockRole.acquire,
    'Acquire: second phrase',
    const Duration(seconds: 210),
    target,
  ),
  _block(
    PracticeBlockRole.apply,
    'Apply both phrases',
    maintenance == null
        ? const Duration(minutes: 5)
        : const Duration(minutes: 3),
    target,
  ),
  _block(
    PracticeBlockRole.reflect,
    'Reflect and plan',
    const Duration(minutes: 1),
    target,
    countsInstrumentTime: false,
  ),
  if (maintenance != null)
    _block(
      PracticeBlockRole.maintenance,
      'Maintenance: earlier phrase',
      const Duration(minutes: 2),
      maintenance,
    ),
];

PracticeBlock _block(
  PracticeBlockRole role,
  String title,
  Duration budget,
  ObjectiveRef target, {
  bool countsInstrumentTime = true,
}) => PracticeBlock(
  role: role,
  title: title,
  budget: budget,
  target: target,
  countsInstrumentTime: countsInstrumentTime,
);
