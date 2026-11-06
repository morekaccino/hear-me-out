import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/pitch_source.dart';
import '../../core/learning/progress.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../shared/audio/sound_service.dart';
import '../../shared/navigation/duo_route.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../lesson/lesson_screen.dart';
import '../technique/technique_screen.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with WidgetsBindingObserver {
  PitchSource? _source;
  StreamSubscription<PitchFrame>? _subscription;
  PitchFrame? _frame;
  String? _micError;
  bool _starting = false;
  bool _openingPractice = false;
  bool _openingTechnique = false;
  int _micGeneration = 0;
  int _selectedString = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopTuner());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_stopTuner());
    }
  }

  Future<void> _stopTuner() async {
    final generation = ++_micGeneration;
    final source = _source;
    _source = null;
    final subscription = _subscription;
    _subscription = null;
    // Stop the hardware before waiting on the stream teardown. This keeps a
    // navigation tap responsive and guarantees the mic is off first. The
    // generation token already makes stale frames harmless, so the cancelled
    // subscription does not need to block navigation.
    await source?.stop();
    await source?.dispose();
    unawaited(subscription?.cancel());
    if (mounted && generation == _micGeneration) {
      setState(() {
        _frame = null;
        _starting = false;
      });
    }
  }

  Future<void> _toggleTuner() async {
    if (_starting) return;
    if (_source != null) {
      await _stopTuner();
      return;
    }
    final generation = ++_micGeneration;
    setState(() {
      _starting = true;
      _micError = null;
    });
    final source = ref.read(pitchSourceFactoryProvider)();
    bool started;
    try {
      started = await source.start();
    } catch (_) {
      started = false;
    }
    if (!mounted || generation != _micGeneration) {
      await source.dispose();
      return;
    }
    if (!started) {
      await source.dispose();
      if (!mounted || generation != _micGeneration) return;
      setState(() {
        _starting = false;
        _micError = 'Microphone unavailable. Check your system permissions.';
      });
      return;
    }
    _source = source;
    _subscription = source.frames.listen((frame) {
      if (!mounted || generation != _micGeneration) return;
      setState(() => _frame = frame);
    });
    if (mounted) setState(() => _starting = false);
  }

  Future<bool> _ensureMic() async {
    final source = ref.read(pitchSourceFactoryProvider)();
    try {
      return await source.ensurePermission();
    } catch (_) {
      return false;
    } finally {
      await source.dispose();
    }
  }

  Future<void> _openTechnique() async {
    if (_openingTechnique) return;
    _openingTechnique = true;
    try {
      // The technique screen plays button sounds; the tuner must not keep
      // listening underneath it.
      await _stopTuner();
      if (!mounted) return;
      await Navigator.of(context)
          .push(duoLessonRoute<void>((_) => const TechniqueScreen()));
    } finally {
      _openingTechnique = false;
    }
  }

  Future<void> _startPractice(String kind) async {
    if (_openingPractice) return;
    _openingPractice = true;
    try {
      final settings = ref
          .read(appControllerProvider)
          .asData
          ?.value
          .progress
          .settings;
      final mode = settings?.answerMode ?? AnswerMode.mixed;
      await _stopTuner();
      if (!mounted) return;
      var micAvailable = false;
      if (mode != AnswerMode.name) {
        micAvailable = await _ensureMic();
        if (!mounted) return;
        if (!micAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone unavailable. This session will use note names.',
              ),
            ),
          );
        }
      }
      unawaited(ref.read(soundServiceProvider).play(Sfx.lessonStart));
      final controller = ref.read(appControllerProvider.notifier);
      controller.startPractice(kind: kind, micAvailable: micAvailable);
      await Navigator.of(context)
          .push(duoLessonRoute<void>((_) => const LessonScreen()));
    } finally {
      _openingPractice = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final progress = data.progress;
    final due = progress.dueSkills(DateTime.now()).length;
    final weak = progress.weakSkills(limit: 20).length;
    final learned = progress.skills.values
        .where((skill) => skill.attempts > 0)
        .length;
    final skillAttempts = progress.totalSkillAttempts;
    final skillCorrect = progress.skills.values.fold(
      0,
      (sum, skill) => sum + skill.correct,
    );
    final accuracy = skillAttempts == 0 ? 0 : skillCorrect / skillAttempts;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Practice',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (progress.settings.streakEnabled)
                    StatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '${progress.effectiveStreak}',
                      iconColor: AppColors.orange,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tune up, then review the skills that need work.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              _WeeklyGoalCard(progress: progress),
              const SizedBox(height: 24),
              _TunerCard(
                selectedString: _selectedString,
                onStringSelected: (index) {
                  if (index == _selectedString) return;
                  unawaited(ref.read(soundServiceProvider).play(Sfx.uiSelect));
                  setState(() => _selectedString = index);
                },
                running: _source != null,
                starting: _starting,
                frame: _frame,
                error: _micError,
                a4: progress.settings.a4Hz,
                onToggle: _toggleTuner,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      value: '${progress.masteredSkillCount}',
                      label: 'Mastered',
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      value: '$learned',
                      label: 'Learned',
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      value: '${(accuracy * 100).round()}%',
                      label: 'Accuracy',
                      color: const Color(0xFFFF9600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Smart practice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _PracticeRow(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.purple,
                title: 'Smart review',
                subtitle: due + weak == 0
                    ? 'Nothing needs repair right now'
                    : '${due + weak} skills due or fragile',
                badge: due + weak == 0 ? null : '${due + weak}',
                onTap: () => _startPractice('smart'),
              ),
              const SizedBox(height: 8),
              _PracticeRow(
                icon: Icons.event_repeat_rounded,
                color: AppColors.blue,
                title: 'Due review',
                subtitle: due == 0
                    ? 'Nothing due right now'
                    : due == 1
                    ? '1 skill ready to review'
                    : '$due skills ready to review',
                badge: due == 0 ? null : '$due',
                onTap: () => _startPractice('due'),
              ),
              const SizedBox(height: 8),
              _PracticeRow(
                icon: Icons.healing_rounded,
                color: AppColors.red,
                title: 'Weak skills',
                subtitle: weak == 0
                    ? 'No weak skills yet'
                    : weak == 1
                    ? '1 skill below 75% accuracy'
                    : '$weak skills below 75% accuracy',
                badge: weak == 0 ? null : '$weak',
                onTap: () => _startPractice('weak'),
              ),
              const SizedBox(height: 8),
              _PracticeRow(
                icon: Icons.shuffle_rounded,
                color: AppColors.purple,
                title: 'Free practice',
                subtitle: learned == 0
                    ? 'Start with the first note lesson'
                    : 'Mix every skill you have met',
                onTap: () => _startPractice('all'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Technique',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _PracticeRow(
                icon: Icons.pan_tool_alt_rounded,
                color: AppColors.teal,
                title: 'Technique check',
                subtitle: 'Posture, hands, and a 60-second drill',
                onTap: _openTechnique,
              ),
              const SizedBox(height: 16),
              Text(
                'The standard tuning tuner above listens to your guitar and shows how far each string is from standard pitch. No audio leaves this device.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TunerCard extends StatelessWidget {
  const _TunerCard({
    required this.selectedString,
    required this.onStringSelected,
    required this.running,
    required this.starting,
    required this.frame,
    required this.error,
    required this.a4,
    required this.onToggle,
  });

  final int selectedString;
  final ValueChanged<int> onStringSelected;
  final bool running;
  final bool starting;
  final PitchFrame? frame;
  final String? error;
  final double a4;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final target = standardTuning[selectedString];
    final voiced = frame?.voiced == true;
    final frequency = frame?.frequency ?? 0;
    final detected = voiced
        ? Note.fromMidi(frequencyToMidi(frequency, a4: a4).round())
        : null;
    final centsToTarget = voiced
        ? 1200 * math.log(frequency / target.open.frequency(a4: a4)) / math.ln2
        : 0.0;
    final inTune = voiced && centsToTarget.abs() <= 5;
    final color = inTune ? AppColors.greenDark : AppColors.text;

    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppColors.blueDark,
              ),
              const SizedBox(width: 8),
              const Text(
                'Standard tuning',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (running)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.red),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < standardTuning.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DuoTappable(
                      onTap: () => onStringSelected(index),
                      pressedScale: 0.95,
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedString == index
                              ? AppColors.blue
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedString == index
                                ? AppColors.blueDark
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          standardTuning[index].open.pitchClass,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: selectedString == index
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 116,
            child: Center(
              child: voiced && detected != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detected.display,
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inTune
                              ? 'In tune'
                              : '${centsToTarget > 0 ? 'Tune down' : 'Tune up'}  ·  ${centsToTarget.abs().toStringAsFixed(0)} cents',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: inTune
                                ? AppColors.greenDark
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${frequency.toStringAsFixed(1)} Hz  ·  target ${target.open.display}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          running
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_none_rounded,
                          size: 40,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          starting
                              ? 'Starting microphone…'
                              : running
                              ? 'Play the ${target.label} string'
                              : 'Tap to start the tuner',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ],
          const SizedBox(height: 8),
          DuoButton(
            label: running ? 'STOP TUNER' : 'START TUNER',
            onPressed: starting ? null : onToggle,
            color: running ? AppColors.textMuted : AppColors.blue,
            icon: running ? Icons.stop_rounded : Icons.mic_rounded,
            height: 48,
            fontSize: 14,
            sound: running ? Sfx.tunerOff : Sfx.tunerOn,
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minutes = progress.weeklyPracticeMinutes(now);
    final goal = progress.settings.weeklyGoalMinutes;
    final ratio = goal <= 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    final remaining = progress.weeklyPracticeGoalRemaining(now);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 20,
                color: AppColors.greenDark,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'This week',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$minutes / $goal min',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LessonProgressBar(value: ratio, height: 12),
          const SizedBox(height: 6),
          Text(
            ratio >= 1
                ? 'Weekly goal complete. Nice work.'
                : minutes == 0
                ? 'Any guitar time this week counts.'
                : '$remaining min to this week’s goal.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
