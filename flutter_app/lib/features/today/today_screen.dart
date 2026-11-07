import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/phrase_objectives.dart';
import '../../content/technique/technique_content.dart';
import '../../core/learning/practice_session.dart';
import '../../core/notation/staff_painter.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../phrase/phrase_player_screen.dart';
import '../reading_lab/reading_lab_entry.dart';
import '../reading_lab/reading_lab_screen.dart';
import '../technique/technique_screen.dart';
import 'today_content.dart';
import 'today_controller.dart';

/// The gated Today 5-minute practice surface.
///
/// This screen is only mounted from main navigation when decision 0001's
/// `phraseLoopEnabled` switch is on. Tests may build it directly. It owns one
/// target, one correction, one next step, and a real instrument-time clock. It
/// has no hearts, XP, streak, gems, quests, or punishment.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, this.onOpenPractice});

  /// Switches to the existing Practice tab, which owns the tuner and the
  /// single-note Reading Lab. Null in direct test builds.
  final VoidCallback? onOpenPractice;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A returning tab must not charge the unattended gap as guitar time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(appControllerProvider).asData == null) return;
      ref.read(todayControllerProvider.notifier).resyncClock();
    });
    // Tick only while the session is running. The timer never invents time: it
    // simply asks the controller to account the supplied wall clock.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Never initialize the Today target from a still-loading profile.
      if (ref.read(appControllerProvider).asData == null) return;
      final session = ref.read(todayControllerProvider).session;
      if (session.isRunning) {
        ref.read(todayControllerProvider.notifier).tick();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  void _pauseIfRunning() {
    try {
      if (ref.read(appControllerProvider).asData == null) return;
      final session = ref.read(todayControllerProvider).session;
      if (session.isRunning) {
        ref.read(todayControllerProvider.notifier).pause();
      }
    } catch (_) {
      // The provider scope may already be tearing down. Nothing to pause.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.inactive) {
      return;
    }
    _pauseIfRunning();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: app.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(DuoSpacing.lg),
              child: Text(
                'Could not load today’s practice.\n$error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          data: (_) => PageFrame(
            maxWidth: 720,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DuoSpacing.md,
                DuoSpacing.sm,
                DuoSpacing.md,
                DuoSpacing.xl,
              ),
              child: _TodayBody(onOpenPractice: widget.onOpenPractice),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({this.onOpenPractice});

  final VoidCallback? onOpenPractice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    final registry = ref.watch(todayPhraseRegistryProvider);
    final session = state.session;
    final target = resolveTodayTarget(session.target, registry);
    final completedLessons =
        ref
            .watch(appControllerProvider)
            .asData
            ?.value
            .progress
            .completedLessons
            .length ??
        0;

    void openReadingLab() {
      // Leaving Today for the lab must not charge the gap as guitar time; the
      // learner can resume the session on return.
      if (state.session.isRunning) controller.pause();
      unawaited(Navigator.of(context).push(readingLabRoute()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodayHeader(state: state),
        const SizedBox(height: DuoSpacing.md),
        _PlanPicker(state: state, controller: controller),
        const SizedBox(height: DuoSpacing.md),
        _TargetCard(state: state, target: target),
        const SizedBox(height: DuoSpacing.md),
        _ClockCard(state: state, controller: controller),
        const SizedBox(height: DuoSpacing.lg),
        Text(
          'THE PLAN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        for (var index = 0; index < session.blocks.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: DuoSpacing.sm),
            child: _BlockCard(
              state: state,
              index: index,
              registry: registry,
              onOpenPractice: onOpenPractice,
              onOpenReadingLab: openReadingLab,
            ),
          ),
        const SizedBox(height: DuoSpacing.xs),
        ReadingLabEntry(
          completedLessons: completedLessons,
          onOpen: openReadingLab,
        ),
        const SizedBox(height: DuoSpacing.sm),
        _PreviewFooter(),
      ],
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.state});

  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final finished = state.session.isFinished;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Mascot(size: 58),
        const SizedBox(width: DuoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                finished ? 'Today is done' : 'Today’s practice',
                key: const ValueKey('today-title'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                finished
                    ? 'Stop point reached. That is enough for today.'
                    : 'One target. One correction. One next step.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({required this.state, required this.controller});

  final TodayState state;
  final TodayController controller;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final started = session.isStarted;
    final maintenance = session.maintenanceTarget;
    final maintenanceCopy = session.length == PracticeSessionLength.five
        ? 'Adds the earlier phrase and extends this plan to 6 minutes.'
        : 'Adds the earlier phrase at the end.';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${session.totalDuration.inMinutes} MIN',
                key: const ValueKey('today-total-minutes'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          Wrap(
            spacing: DuoSpacing.xs,
            runSpacing: DuoSpacing.xs,
            children: [
              for (final length in PracticeSessionLength.values)
                _LengthChip(
                  length: length,
                  selected: session.length == length,
                  enabled: !started,
                  onTap: () => controller.setLength(length),
                ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            '${_formatDuration(session.instrumentTime)} of this plan is guitar '
            'in hand. The timer counts that time, not prompts.',
            key: const ValueKey('today-instrument-budget'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            _lengthDescription(session.length),
            key: const ValueKey('today-length-description'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
          if (maintenance != null) ...[
            const SizedBox(height: DuoSpacing.sm),
            DuoTappable(
              key: const ValueKey('today-maintenance-toggle'),
              enabled: !started,
              onTap: () =>
                  controller.setMaintenanceDay(!session.isMaintenanceDay),
              child: Container(
                padding: const EdgeInsets.all(DuoSpacing.sm),
                decoration: BoxDecoration(
                  color: session.isMaintenanceDay
                      ? AppColors.purpleSoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(DuoSpacing.sm),
                  border: Border.all(
                    color: session.isMaintenanceDay
                        ? AppColors.purpleDark
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: session.isMaintenanceDay
                            ? AppColors.purple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: session.isMaintenanceDay
                              ? AppColors.purpleDark
                              : AppColors.borderStrong,
                          width: 1.5,
                        ),
                      ),
                      child: session.isMaintenanceDay
                          ? const Icon(
                              Icons.check_rounded,
                              size: 17,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: DuoSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maintenance day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            maintenanceCopy,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LengthChip extends StatelessWidget {
  const _LengthChip({
    required this.length,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PracticeSessionLength length;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      key: ValueKey('today-length-${length.minutes}'),
      enabled: enabled,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${length.minutes} minute plan',
        excludeSemantics: true,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: DuoSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.greenDark : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: Text(
            '${length.minutes} MIN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: selected
                  ? Colors.white
                  : enabled
                  ? AppColors.text
                  : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.state, required this.target});

  final TodayState state;
  final TodayTargetView target;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppColors.greenSoft,
      borderColor: AppColors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY’S TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            target.title,
            key: const ValueKey('today-target-title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            target.detail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            'Why this target: ${state.targetReason}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.state, required this.controller});

  final TodayState state;
  final TodayController controller;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final running = session.isRunning;
    final accent = running
        ? AppColors.green
        : session.isFinished
        ? AppColors.blue
        : AppColors.borderStrong;

    return SectionCard(
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GUITAR IN HAND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      _formatDuration(session.instrumentElapsed),
                      key: const ValueKey('today-instrument-time'),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: session.instrumentElapsed > Duration.zero
                            ? AppColors.greenDark
                            : AppColors.text,
                      ),
                    ),
                    Text(
                      'of ${_formatDuration(session.instrumentTime)} planned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DuoSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SESSION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${_formatDuration(session.elapsed)} / '
                    '${_formatDuration(session.totalDuration)}',
                    key: const ValueKey('today-session-time'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.sm),
          LessonProgressBar(
            value: session.progress,
            color: running ? AppColors.green : AppColors.blue,
            height: 12,
          ),
          const SizedBox(height: DuoSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                session.isFinished
                    ? Icons.check_circle_rounded
                    : Icons.flag_rounded,
                size: 17,
                color: session.isFinished
                    ? AppColors.greenDark
                    : AppColors.textMuted,
              ),
              const SizedBox(width: DuoSpacing.xxs),
              Expanded(
                child: Text(
                  _stopPointCopy(state),
                  key: const ValueKey('today-stop-point'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (state.earlyEnded) ...[
            const SizedBox(height: DuoSpacing.xs),
            _CalmNote(
              key: const ValueKey('today-early-end'),
              text:
                  'You stopped early. That is okay — the minutes you played '
                  'still count.',
            ),
          ],
          const SizedBox(height: DuoSpacing.sm),
          _ClockControls(state: state, controller: controller),
        ],
      ),
    );
  }

  String _stopPointCopy(TodayState state) {
    final session = state.session;
    if (session.isFinished) {
      if (state.earlyEnded) {
        return 'You stopped before the stop point. Your guitar time is still '
            'yours.';
      }
      return 'Stop point reached at '
          '${_formatDuration(session.totalDuration)}. That is the whole session.';
    }
    if (!session.isStarted) {
      return 'The stop point is ${_formatDuration(session.totalDuration)}. '
          'You can stop early at any time.';
    }
    return 'Stop point at ${_formatDuration(session.totalDuration)}. '
        '${_formatDuration(session.remaining)} left.';
  }
}

class _ClockControls extends StatelessWidget {
  const _ClockControls({required this.state, required this.controller});

  final TodayState state;
  final TodayController controller;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session.isFinished) {
      return DuoButton(
        key: const ValueKey('today-session-restart'),
        label: 'START A NEW SESSION',
        icon: Icons.refresh_rounded,
        onPressed: controller.restart,
      );
    }
    if (!session.isStarted) {
      return DuoButton(
        key: const ValueKey('today-session-start'),
        label: 'START ${session.totalDuration.inMinutes}-MINUTE SESSION',
        icon: Icons.play_arrow_rounded,
        onPressed: () => controller.start(),
      );
    }
    if (session.isPaused) {
      return Row(
        children: [
          Expanded(
            child: DuoButton(
              key: const ValueKey('today-session-resume'),
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              onPressed: () => controller.resume(),
              height: 52,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: DuoSpacing.xs),
          Expanded(
            child: OutlineDuoButton(
              key: const ValueKey('today-session-end-early'),
              label: 'END EARLY',
              icon: Icons.stop_rounded,
              onPressed: controller.finishEarly,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlineDuoButton(
            key: const ValueKey('today-session-pause'),
            label: 'PAUSE',
            icon: Icons.pause_rounded,
            onPressed: () => controller.pause(),
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: DuoSpacing.xs),
        Expanded(
          child: DuoButton(
            key: const ValueKey('today-session-stop'),
            label: 'STOP',
            icon: Icons.stop_rounded,
            onPressed: controller.finishEarly,
            color: AppColors.textMuted,
            height: 52,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({
    required this.state,
    required this.index,
    required this.registry,
    this.onOpenPractice,
    this.onOpenReadingLab,
  });

  final TodayState state;
  final int index;
  final PhraseObjectiveRegistry registry;
  final VoidCallback? onOpenPractice;
  final VoidCallback? onOpenReadingLab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = state.session;
    final block = session.blocks[index];
    final current = !session.isFinished && index == session.currentIndex;
    final complete = session.isFinished || index < session.currentIndex;
    final expanded =
        current ||
        (session.isFinished && block.role == PracticeBlockRole.reflect);
    final accent = _roleColor(block.role);
    final blockTarget = resolveTodayTarget(block.target, registry);

    return SectionCard(
      key: ValueKey('today-block-${block.role.name}-$index'),
      color: current ? _roleSoftColor(block.role) : AppColors.background,
      borderColor: current
          ? accent
          : complete
          ? AppColors.greenDark
          : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBadge(
                number: index + 1,
                complete: complete,
                current: current,
                color: accent,
              ),
              const SizedBox(width: DuoSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_roleLabel(block.role)} · '
                      '${_formatBudget(block.budget)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DuoSpacing.xxs),
              if (complete)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.greenDark,
                )
              else if (current)
                _NowBadge(color: accent)
              else
                Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            'What: ${_blockWhat(block)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Why: ${_blockWhy(block)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: DuoSpacing.sm),
            _BlockBody(
              state: state,
              block: block,
              index: index,
              target: blockTarget,
              registry: registry,
              onOpenPractice: onOpenPractice,
              onOpenReadingLab: onOpenReadingLab,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockBody extends ConsumerWidget {
  const _BlockBody({
    required this.state,
    required this.block,
    required this.index,
    required this.target,
    required this.registry,
    this.onOpenPractice,
    this.onOpenReadingLab,
  });

  final TodayState state;
  final PracticeBlock block;
  final int index;
  final TodayTargetView target;
  final PhraseObjectiveRegistry registry;
  final VoidCallback? onOpenPractice;
  final VoidCallback? onOpenReadingLab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (block.role) {
      PracticeBlockRole.setup => _setup(context, ref),
      PracticeBlockRole.technique => _technique(context, ref),
      PracticeBlockRole.model => _model(context, ref),
      PracticeBlockRole.acquire => _reps(context, ref, earlier: false),
      PracticeBlockRole.maintenance => _reps(context, ref, earlier: true),
      PracticeBlockRole.apply => _apply(context, ref),
      PracticeBlockRole.reflect => _reflect(context, ref),
    };
  }

  Widget _setup(BuildContext context, WidgetRef ref) {
    final controller = ref.read(todayControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in allTechniqueChecklists.first.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _CheckLine(text: item),
          ),
        const SizedBox(height: DuoSpacing.xxs),
        if (!state.session.isStarted)
          DuoButton(
            key: ValueKey('today-block-action-$index'),
            label: 'START SESSION',
            icon: Icons.play_arrow_rounded,
            onPressed: () => controller.start(),
            height: 52,
            fontSize: 14,
          )
        else
          DuoButton(
            key: ValueKey('today-block-action-$index'),
            label: 'I’M TUNED, NEXT',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => controller.advance(),
            height: 52,
            fontSize: 14,
          ),
        if (onOpenPractice != null) ...[
          const SizedBox(height: DuoSpacing.xs),
          OutlineDuoButton(
            label: 'OPEN TUNER',
            icon: Icons.graphic_eq_rounded,
            onPressed: onOpenPractice,
            color: AppColors.blue,
          ),
        ],
      ],
    );
  }

  Widget _technique(BuildContext context, WidgetRef ref) {
    final drill = allTechniqueChecklists.first.drill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DuoSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(DuoSpacing.sm),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drill.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                drill.instructions,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: DuoSpacing.xs),
              Wrap(
                spacing: DuoSpacing.xs,
                runSpacing: DuoSpacing.xxs,
                children: [
                  _StatChip(label: '${drill.seconds} SEC'),
                  _StatChip(label: '${drill.tempoBpm} BPM'),
                  _StatChip(label: '${drill.repetitions} REPS'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        DuoButton(
          key: ValueKey('today-block-action-$index'),
          label: 'DONE, NEXT',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => ref.read(todayControllerProvider.notifier).advance(),
          height: 52,
          fontSize: 14,
        ),
        const SizedBox(height: DuoSpacing.xs),
        OutlineDuoButton(
          label: 'OPEN TECHNIQUE',
          icon: Icons.pan_tool_alt_rounded,
          onPressed: () {
            unawaited(
              Navigator.of(context)
                  .push(duoLessonRoute<void>((_) => const TechniqueScreen())),
            );
          },
          color: AppColors.teal,
        ),
      ],
    );
  }

  Widget _model(BuildContext context, WidgetRef ref) {
    final spec = todaySynthPreview(block.target, registry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const ValueKey('today-synth-preview'),
            padding: const EdgeInsets.symmetric(
              horizontal: DuoSpacing.xs,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.purpleDark, width: 1.5),
            ),
            child: Text(
              'SYNTH PREVIEW',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.purpleDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        Text(
          'Generated on this device. Human reference recordings are not '
          'available yet.',
          key: const ValueKey('today-synth-note'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        if (spec != null)
          OutlineDuoButton(
            label: 'PLAY SYNTH PREVIEW',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              unawaited(ref.read(audioEngineProvider).play(spec));
            },
            color: AppColors.purpleDark,
          ),
        const SizedBox(height: DuoSpacing.xs),
        DuoButton(
          key: ValueKey('today-block-action-$index'),
          label: 'DONE, NEXT',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => ref.read(todayControllerProvider.notifier).advance(),
          height: 52,
          fontSize: 14,
        ),
      ],
    );
  }

  Widget _reps(BuildContext context, WidgetRef ref, {required bool earlier}) {
    final note = target.note;
    final phraseId = todayPhraseIdFor(block.target);
    final phrasePractice = !earlier && phraseId != null
        ? phrasePlayerForPhraseId(
            phraseId,
            registry: registry,
            recordProgress: false,
            practiceOnly: true,
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(
              DuoSpacing.sm,
              DuoSpacing.xxs,
              DuoSpacing.sm,
              DuoSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DuoSpacing.sm),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                StaffView(
                  note: note,
                  height: 130,
                  staffColor: AppColors.borderStrong,
                  noteColor: AppColors.text,
                ),
                Text(
                  '${note.display} · ${target.detail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DuoSpacing.xs),
        ],
        Text(
          earlier
              ? 'Play the earlier phrase once at a comfortable tempo. No score.'
              : 'One bar at 50–70%. Do 3–5 blocked reps, then change one thing.',
          key: ValueKey(
            earlier
                ? 'today-maintenance-instructions'
                : 'today-acquire-instructions',
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        DuoButton(
          key: ValueKey('today-block-action-$index'),
          label: earlier ? 'PLAYED IT, NEXT' : 'REPS DONE, NEXT',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => ref.read(todayControllerProvider.notifier).advance(),
          height: 52,
          fontSize: 14,
        ),
        if (!earlier && phrasePractice != null) ...[
          const SizedBox(height: DuoSpacing.xs),
          OutlineDuoButton(
            label: 'OPEN PHRASE PRACTICE',
            icon: Icons.music_note_rounded,
            onPressed: () {
              unawaited(
                Navigator.of(context)
                    .push(duoLessonRoute<void>((_) => phrasePractice)),
              );
            },
            color: AppColors.purpleDark,
          ),
        ] else if (!earlier && onOpenReadingLab != null) ...[
          const SizedBox(height: DuoSpacing.xs),
          OutlineDuoButton(
            label: 'OPEN READING LAB',
            icon: Icons.menu_book_rounded,
            onPressed: onOpenReadingLab,
            color: AppColors.blue,
          ),
        ],
      ],
    );
  }

  Widget _apply(BuildContext context, WidgetRef ref) {
    final phraseId = todayPhraseIdFor(block.target);
    final controller = ref.read(todayControllerProvider.notifier);
    final player =
        state.performanceDay && state.gate.allowsScoredTake && phraseId != null
        ? phrasePlayerForPhraseId(
            phraseId,
            registry: registry,
            recordProgress: false,
            headphonesConfirmed: state.gate.headphonesConfirmed,
            clockVerified: state.gate.clockVerified,
            onTakeCompleted: (verification) {
              final record = target.phrase;
              if (record == null) return Future<bool>.value(false);
              return controller.savePhraseResult(
                phraseId: record.phrase.id,
                result: verification.result,
                tempoBpm: record.phrase.targetTempoBpm,
                targetTempoBpm: record.phrase.targetTempoBpm,
                pieceId: record.piece.id,
                contentVersion: record.contentVersion,
                correction: verification.correction,
              );
            },
          )
        : null;
    final status = _applyStatus(
      phraseId: phraseId,
      playerAvailable: player != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'One take at target tempo. Stop after one.',
          key: const ValueKey('today-apply-instructions'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        Container(
          padding: const EdgeInsets.all(DuoSpacing.sm),
          decoration: BoxDecoration(
            color: state.performanceDay
                ? AppColors.blueSoft
                : AppColors.surface,
            borderRadius: BorderRadius.circular(DuoSpacing.sm),
            border: Border.all(
              color: state.performanceDay
                  ? AppColors.blueDark
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                state.performanceDay
                    ? Icons.mic_rounded
                    : Icons.headphones_rounded,
                size: 18,
                color: state.performanceDay
                    ? AppColors.blueDark
                    : AppColors.textMuted,
              ),
              const SizedBox(width: DuoSpacing.xxs),
              Expanded(
                child: Text(
                  status,
                  key: const ValueKey('today-apply-status'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DuoSpacing.xs),
        if (player != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DuoSpacing.xs),
            child: OutlineDuoButton(
              label: 'OPEN PHRASE TAKE',
              icon: Icons.mic_rounded,
              onPressed: () {
                unawaited(
                  Navigator.of(context)
                      .push(duoLessonRoute<void>((_) => player)),
                );
              },
              color: AppColors.blue,
            ),
          ),
        DuoButton(
          key: ValueKey('today-block-action-$index'),
          label: 'TAKE DONE, NEXT',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => ref.read(todayControllerProvider.notifier).advance(),
          height: 52,
          fontSize: 14,
        ),
      ],
    );
  }

  String _applyStatus({
    required String? phraseId,
    required bool playerAvailable,
  }) {
    if (!state.performanceDay) {
      return 'Practice only. Recording is for a performance day, not every '
          'session.';
    }
    if (!state.gate.allowsScoredTake) {
      return 'Performance day, but the scored-take gate is closed. This take '
          'stays unscored and is not saved.';
    }
    if (phraseId == null) {
      return 'Performance day and the gate is open. This target has no phrase '
          'take, so play one clean take and mark it done.';
    }
    if (!playerAvailable) {
      return 'Performance day and the gate is open, but the phrase player is '
          'still gated in this build. This take is practice only.';
    }
    return 'Performance day. The scored-take gate is open, so this take may be '
        'saved.';
  }

  Widget _reflect(BuildContext context, WidgetRef ref) {
    final result = state.lastTake;
    final metric = result != null
        ? 'Last take: ${(result.noteAccuracy * 100).round()}% of notes clean.'
        : state.session.instrumentElapsed > Duration.zero
        ? 'Guitar time: ${_formatDuration(state.session.instrumentElapsed)}.'
        : 'No guitar time recorded yet.';
    final correction = state.lastCorrection ?? _ratingCorrection();
    final nextStep = todayNextStep(block.target, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'How did that feel?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DuoSpacing.xxs),
        Wrap(
          spacing: DuoSpacing.xs,
          runSpacing: DuoSpacing.xs,
          children: [
            for (final rating in const [
              (1, 'Not yet'),
              (2, 'Getting there'),
              (3, 'Solid'),
            ])
              _RatingChip(
                rating: rating.$1,
                label: rating.$2,
                selected: state.selfRating == rating.$1,
                onTap: () => ref
                    .read(todayControllerProvider.notifier)
                    .rateSession(rating.$1),
              ),
          ],
        ),
        if (state.selfRating == 0) ...[
          const SizedBox(height: DuoSpacing.xs),
          Text(
            'Rate first. Then the session shows one real metric, one '
            'correction, and one next step.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ] else ...[
          const SizedBox(height: DuoSpacing.sm),
          _SummaryLine(
            key: const ValueKey('today-metric'),
            label: 'ONE REAL METRIC',
            value: metric,
            color: AppColors.blue,
          ),
          const SizedBox(height: DuoSpacing.xs),
          _SummaryLine(
            key: const ValueKey('today-correction'),
            label: state.lastCorrection != null
                ? 'ONE CORRECTION'
                : 'ONE CORRECTION · FROM YOUR RATING',
            value: correction,
            color: AppColors.orangeDark,
          ),
          const SizedBox(height: DuoSpacing.xs),
          _SummaryLine(
            key: const ValueKey('today-next-step'),
            label: 'ONE NEXT STEP',
            value: nextStep,
            color: AppColors.greenDark,
          ),
        ],
        if (!state.session.isFinished) ...[
          const SizedBox(height: DuoSpacing.sm),
          DuoButton(
            key: ValueKey('today-block-action-$index'),
            label: 'FINISH SESSION',
            icon: Icons.check_rounded,
            onPressed: () =>
                ref.read(todayControllerProvider.notifier).finishEarly(),
            height: 52,
            fontSize: 14,
          ),
        ],
      ],
    );
  }

  String _ratingCorrection() {
    return switch (state.selfRating) {
      1 => 'Stay at half tempo and play only the first bar.',
      2 => 'Repeat the bar once more before adding speed.',
      _ => 'Keep this tempo and add the next bar tomorrow.',
    };
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.complete,
    required this.current,
    required this.color,
  });

  final int number;
  final bool complete;
  final bool current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: complete || current ? color : AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: complete || current ? color : AppColors.borderStrong,
          width: 1.5,
        ),
      ),
      child: complete
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: current ? Colors.white : AppColors.textMuted,
              ),
            ),
    );
  }
}

class _NowBadge extends StatelessWidget {
  const _NowBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DuoSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'NOW',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 17,
          color: AppColors.greenDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DuoSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.borderStrong, width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int rating;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      key: ValueKey('today-reflect-rating-$rating'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: DuoSpacing.sm,
          vertical: DuoSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.greenDark : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DuoSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DuoSpacing.sm),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmNote extends StatelessWidget {
  const _CalmNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DuoSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(DuoSpacing.sm),
        border: Border.all(color: AppColors.green, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: AppColors.greenDark,
          ),
          const SizedBox(width: DuoSpacing.xxs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Practice preview. Today is behind the phrase-loop switch, and phrase '
      'scoring is not validated yet.',
      key: const ValueKey('today-preview-footer'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textLight,
      ),
    );
  }
}

String _lengthDescription(PracticeSessionLength length) {
  return switch (length) {
    PracticeSessionLength.five =>
      'The standard daily plan. Short enough to repeat tomorrow.',
    PracticeSessionLength.ten =>
      'Ten minutes adds a second acquisition pass on the same target.',
    PracticeSessionLength.twenty =>
      'Deep practice: more acquisition and application time on one target.',
  };
}

String _roleLabel(PracticeBlockRole role) {
  return switch (role) {
    PracticeBlockRole.setup => 'TUNE & SETUP',
    PracticeBlockRole.technique => 'TECHNIQUE',
    PracticeBlockRole.model => 'MODEL',
    PracticeBlockRole.acquire => 'ACQUIRE',
    PracticeBlockRole.apply => 'APPLY',
    PracticeBlockRole.maintenance => 'MAINTENANCE',
    PracticeBlockRole.reflect => 'REFLECT',
  };
}

Color _roleColor(PracticeBlockRole role) {
  return switch (role) {
    PracticeBlockRole.setup => AppColors.green,
    PracticeBlockRole.technique => AppColors.teal,
    PracticeBlockRole.model => AppColors.purpleDark,
    PracticeBlockRole.acquire => AppColors.blueDark,
    PracticeBlockRole.apply => AppColors.orangeDark,
    PracticeBlockRole.maintenance => AppColors.tealDark,
    PracticeBlockRole.reflect => AppColors.greenDark,
  };
}

Color _roleSoftColor(PracticeBlockRole role) {
  return switch (role) {
    PracticeBlockRole.setup => AppColors.greenSoft,
    PracticeBlockRole.technique => AppColors.background,
    PracticeBlockRole.model => AppColors.purpleSoft,
    PracticeBlockRole.acquire => AppColors.blueSoft,
    PracticeBlockRole.apply => AppColors.blueSoft,
    PracticeBlockRole.maintenance => AppColors.background,
    PracticeBlockRole.reflect => AppColors.greenSoft,
  };
}

String _blockWhat(PracticeBlock block) {
  return switch (block.role) {
    PracticeBlockRole.setup =>
      'Tune each string, set your posture, and have the target ready.',
    PracticeBlockRole.technique =>
      'Play the 60-second drill once. Stop when the timer ends.',
    PracticeBlockRole.model =>
      'Listen to one preview, then hum or clap the shape back.',
    PracticeBlockRole.acquire =>
      'Loop one bar at 50–70% tempo. Do 3–5 blocked reps, then one correction.',
    PracticeBlockRole.apply =>
      'Play one take at target tempo. Stop after one take.',
    PracticeBlockRole.maintenance =>
      'Play the earlier phrase once at a comfortable tempo.',
    PracticeBlockRole.reflect =>
      'Rate how it felt, then read one metric and one next step.',
  };
}

String _blockWhy(PracticeBlock block) {
  return switch (block.role) {
    PracticeBlockRole.setup => 'A tuned guitar makes every pitch check honest.',
    PracticeBlockRole.technique =>
      'Clean motion comes before speed and volume.',
    PracticeBlockRole.model => 'Hearing it first gives your hands a target.',
    PracticeBlockRole.acquire => 'Slow reps build the motion you will keep.',
    PracticeBlockRole.apply =>
      'One take shows what carries over at target tempo.',
    PracticeBlockRole.maintenance =>
      'A learned phrase stays easy only when you revisit it.',
    PracticeBlockRole.reflect =>
      'Naming what happened turns practice into a plan.',
  };
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

String _formatBudget(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) return '${duration.inSeconds}s';
  if (seconds == 0) return '$minutes min';
  return '$minutes min ${seconds}s';
}
