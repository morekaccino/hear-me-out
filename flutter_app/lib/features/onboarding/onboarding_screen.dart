import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/note_matcher.dart';
import '../../core/audio/pitch_source.dart';
import '../../core/learning/progress.dart';
import '../../core/music/note.dart';
import '../../core/notation/staff_painter.dart';
import '../../shared/audio/sound_service.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  int _page = 0;
  int _dailyGoal = 20;
  int _explanationMode = 0;

  PitchSource? _source;
  StreamSubscription<PitchFrame>? _subscription;
  PitchReading _reading = PitchReading.silent;
  bool _checkingMic = false;
  bool _advancing = false;
  int _micGeneration = 0;
  String? _micError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMic();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopMic();
    }
  }

  Future<void> _stopMic() async {
    final generation = ++_micGeneration;
    await _subscription?.cancel();
    _subscription = null;
    final source = _source;
    _source = null;
    await source?.stop();
    await source?.dispose();
    if (mounted && generation == _micGeneration) {
      setState(() {
        _reading = PitchReading.silent;
        _checkingMic = false;
      });
    }
  }

  Future<void> _startMic() async {
    if (_checkingMic || _source != null) return;
    final generation = ++_micGeneration;
    setState(() {
      _checkingMic = true;
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
        _checkingMic = false;
        _micError =
            'Microphone access was denied. You can still practice by naming notes.';
      });
      return;
    }
    _source = source;
    _subscription = source.frames.listen((frame) {
      if (!mounted || generation != _micGeneration) return;
      if (!frame.voiced) {
        setState(() => _reading = PitchReading.silent);
        return;
      }
      final midi = frequencyToMidi(frame.frequency);
      setState(() {
        _reading = PitchReading(
          frequency: frame.frequency,
          midi: midi,
          cents: centsFromMidi(midi),
          clarity: frame.clarity,
          note: Note.fromMidi(midi.round()),
          voiced: true,
        );
      });
    });
    if (mounted) setState(() => _checkingMic = false);
  }

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    try {
      if (_page == 2) {
        await _stopMic();
      }
      if (_page < 3) {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      await ref
          .read(appControllerProvider.notifier)
          .completeOnboarding(AppSettings(dailyGoalXp: _dailyGoal));
    } finally {
      _advancing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    for (var index = 0; index < 4; index++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: LessonProgressBar(
                            value: index <= _page ? 1 : 0,
                            height: 8,
                            color: index <= _page
                                ? AppColors.green
                                : AppColors.border,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _WelcomePage(),
                    _HowItWorksPage(
                      mode: _explanationMode,
                      onModeChanged: (mode) {
                        if (mode == _explanationMode) return;
                        unawaited(
                          ref.read(soundServiceProvider).play(Sfx.uiSelect),
                        );
                        setState(() => _explanationMode = mode);
                      },
                    ),
                    _MicCheckPage(
                      checking: _checkingMic,
                      listening: _source != null,
                      reading: _reading,
                      error: _micError,
                      onTest: _startMic,
                      onSkip: _next,
                    ),
                    _GoalPage(
                      selected: _dailyGoal,
                      onSelected: (goal) {
                        if (goal == _dailyGoal) return;
                        unawaited(
                          ref.read(soundServiceProvider).play(Sfx.uiSelect),
                        );
                        setState(() => _dailyGoal = goal);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: DuoButton(
                  label: _page == 3 ? "LET'S PLAY" : 'CONTINUE',
                  onPressed: _next,
                  icon: _page == 3 ? Icons.music_note_rounded : null,
                  sound: _page == 3 ? Sfx.rewardUnlock : Sfx.uiPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            const Mascot(size: 160),
            const SizedBox(height: 16),
            Text(
              'Read music.\nPlay guitar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.08,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'See a note on the staff. Name it, or play it on your guitar and get instant feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _FeaturePill(icon: Icons.music_note, label: 'Note reading'),
                _FeaturePill(icon: Icons.mic, label: 'Pitch feedback'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.greenDark),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage({required this.mode, required this.onModeChanged});

  final int mode;
  final ValueChanged<int> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final note = Note.parse('G4');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Text(
              'Two ways to answer',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Both build the same note-reading skill.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ModeTab(
                          label: 'NAME IT',
                          icon: Icons.touch_app_rounded,
                          selected: mode == 0,
                          onTap: () => onModeChanged(0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeTab(
                          label: 'PLAY IT',
                          icon: Icons.mic_rounded,
                          selected: mode == 1,
                          onTap: () => onModeChanged(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    child: StaffView(
                      note: note,
                      staffColor: AppColors.textLight,
                      noteColor: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mode == 0)
                    Row(
                      children: [
                        for (final name in ['E4', 'G4', 'B4', 'A4'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: name == 'G4'
                                      ? AppColors.greenSoft
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: name == 'G4'
                                        ? AppColors.green
                                        : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: name == 'G4'
                                        ? AppColors.greenDark
                                        : AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: AppColors.blueDark,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Play G on your guitar. The mic hears the pitch and tells you how close you are.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blueDark,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No account. No cloud. Your progress stays on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuoTappable(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.greenSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.greenDark : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.greenDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicCheckPage extends StatelessWidget {
  const _MicCheckPage({
    required this.checking,
    required this.listening,
    required this.reading,
    required this.error,
    required this.onTest,
    required this.onSkip,
  });

  final bool checking;
  final bool listening;
  final PitchReading reading;
  final String? error;
  final VoidCallback onTest;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final note = reading.note;
    final writtenNote = note?.transposed(12);
    final cents = reading.cents;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Mascot(size: 100, mood: MascotMood.thinking),
            const SizedBox(height: 8),
            const Text(
              'Check your microphone',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Play any note on your guitar. If the mic works, you will see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: SizedBox(
                height: 120,
                child: Center(
                  child: reading.voiced && writtenNote != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              writtenNote.display,
                              style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenDark,
                              ),
                            ),
                            Text(
                              'Written pitch  ·  ${reading.frequency.toStringAsFixed(1)} Hz  ·  ${cents.toStringAsFixed(0)} cents',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              size: 38,
                              color: AppColors.textLight,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Waiting for a note…',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (reading.note == null)
              DuoButton(
                label: checking
                    ? 'STARTING…'
                    : listening
                    ? 'LISTENING…'
                    : 'TEST MICROPHONE',
                onPressed: checking || listening ? null : onTest,
                color: AppColors.blue,
                icon: Icons.mic_rounded,
              )
            else
              OutlineDuoButton(
                label: 'SKIP FOR NOW',
                onPressed: onSkip,
                color: AppColors.textMuted,
              ),
            if (reading.note == null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip, I will type note names',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Mascot(size: 110, mood: MascotMood.cheer),
            const SizedBox(height: 12),
            const Text(
              'Pick a daily goal',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Small and steady beats one long session.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            for (final goal in [10, 20, 30])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DuoTappable(
                  onTap: () => onSelected(goal),
                  pressedScale: 0.98,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: selected == goal
                          ? AppColors.greenSoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected == goal
                            ? AppColors.green
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected == goal
                                ? AppColors.green
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            goal == 10
                                ? Icons.eco_rounded
                                : goal == 20
                                ? Icons.local_fire_department_rounded
                                : Icons.bolt_rounded,
                            color: selected == goal
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal == 10
                                    ? 'Casual'
                                    : goal == 20
                                    ? 'Regular'
                                    : 'Serious',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$goal XP per day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected == goal)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.green,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
