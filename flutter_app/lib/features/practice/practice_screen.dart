import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/pitch_source.dart';
import '../../core/learning/progress.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../shared/audio/sound_service.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../lesson/lesson_screen.dart';

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
    await _subscription?.cancel();
    _subscription = null;
    final source = _source;
    _source = null;
    await source?.stop();
    await source?.dispose();
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
      unawaited(
        ref.read(soundServiceProvider).play(Sfx.lessonStart),
      );
      final controller = ref.read(appControllerProvider.notifier);
      controller.startPractice(kind: kind, micAvailable: micAvailable);
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const LessonScreen()));
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
    final due = progress.dueNotes(DateTime.now()).length;
    final weak = progress.weakNotes(limit: 20).length;
    final learned = progress.notes.values.where((n) => n.attempts > 0).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                  StatPill(
                    icon: Icons.favorite_rounded,
                    value: '${progress.hearts}',
                    iconColor: AppColors.red,
                  ),
                  const SizedBox(width: 12),
                  StatPill(
                    icon: Icons.diamond_rounded,
                    value: '${progress.gems}',
                    iconColor: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tune up, then drill the notes that need work.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              if (progress.hearts < maxHearts) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.red, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Finish any practice session to earn one heart back.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _TunerCard(
                selectedString: _selectedString,
                onStringSelected: (index) {
                  if (index == _selectedString) return;
                  unawaited(
                    ref.read(soundServiceProvider).play(Sfx.uiSelect),
                  );
                  setState(() => _selectedString = index);
                },
                running: _source != null,
                starting: _starting,
                frame: _frame,
                error: _micError,
                a4: progress.settings.a4Hz,
                onToggle: _toggleTuner,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      value: '${progress.masteredCount}',
                      label: 'Mastered',
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      value: '$learned',
                      label: 'Learned',
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      value: '${(progress.accuracy * 100).round()}%',
                      label: 'Accuracy',
                      color: const Color(0xFFFF9600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Smart practice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _PracticeRow(
                icon: Icons.event_repeat_rounded,
                color: AppColors.blue,
                title: 'Due review',
                subtitle: due == 0
                    ? 'Nothing due right now'
                    : due == 1
                    ? '1 note ready to review'
                    : '$due notes ready to review',
                badge: due == 0 ? null : '$due',
                onTap: () => _startPractice('due'),
              ),
              const SizedBox(height: 10),
              _PracticeRow(
                icon: Icons.healing_rounded,
                color: AppColors.red,
                title: 'Weak notes',
                subtitle: weak == 0
                    ? 'No weak notes yet'
                    : weak == 1
                    ? '1 note below 75% accuracy'
                    : '$weak notes below 75% accuracy',
                badge: weak == 0 ? null : '$weak',
                onTap: () => _startPractice('weak'),
              ),
              const SizedBox(height: 10),
              _PracticeRow(
                icon: Icons.shuffle_rounded,
                color: AppColors.purple,
                title: 'Free practice',
                subtitle: learned == 0
                    ? 'Start with E and F'
                    : 'Mix every note you have met',
                onTap: () => _startPractice('all'),
              ),
              const SizedBox(height: 16),
              const Text(
                'The tuner listens to your guitar and shows how far each string is from standard pitch. No audio leaves this device.',
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
              const SizedBox(width: 6),
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
                    SizedBox(width: 5),
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
                    child: GestureDetector(
                      onTap: () => onStringSelected(index),
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
                          style: const TextStyle(
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
                        const SizedBox(height: 6),
                        Text(
                          starting
                              ? 'Starting microphone…'
                              : running
                              ? 'Play the ${target.label} string'
                              : 'Tap to start the tuner',
                          style: const TextStyle(
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
        borderRadius: BorderRadius.circular(14),
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
            style: const TextStyle(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    style: const TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
              ),
          ],
        ),
      ),
    );
  }
}
