import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/placement_starters.dart';
import '../../core/audio/note_matcher.dart';
import '../../core/audio/pitch_source.dart';
import '../../core/learning/objective.dart';
import '../../core/learning/onboarding_choices.dart';
import '../../core/learning/placement.dart';
import '../../core/learning/progress.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/verifier.dart';
import '../../core/music/note.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/placement_controller.dart';
import '../../state/providers.dart';
import '../exercises/prompt_view.dart';
import 'placement_result_view.dart';

/// A three-screen, skippable placement check.
///
/// It never blocks the first lesson or phrase: every screen has a skip path,
/// and the result is only saved when the learner taps the save button. The
/// playing screen owns one pitch source and disposes it on every exit.
class PlacementFlowScreen extends ConsumerStatefulWidget {
  const PlacementFlowScreen({
    super.key,
    this.readingLevel,
    this.hasGuitar,
    this.initialStage,
    this.startAtResult = false,
  });

  final ReadingLevel? readingLevel;
  final bool? hasGuitar;

  /// Opens directly on the result step for a manual override.
  final int? initialStage;
  final bool startAtResult;

  @override
  ConsumerState<PlacementFlowScreen> createState() =>
      _PlacementFlowScreenState();
}

class _PlacementFlowScreenState extends ConsumerState<PlacementFlowScreen>
    with WidgetsBindingObserver {
  static const _readingChecks = <Prompt>[
    StaffTapPrompt(
      objective: _readingObjective,
      templateId: 'placement.reading.staff-g4',
      note: Note('G', 4),
    ),
    StaffTapPrompt(
      objective: _readingObjective,
      templateId: 'placement.reading.staff-c5',
      note: Note('C', 5),
    ),
    ChoicePrompt(
      objective: _rhythmObjective,
      templateId: 'placement.reading.half-note',
      question: 'A half note lasts how many beats in 4/4?',
      options: [
        ChoiceOption('1', '1 beat'),
        ChoiceOption('2', '2 beats'),
        ChoiceOption('4', '4 beats'),
      ],
      correctId: '2',
    ),
  ];

  int _step = 0;
  int _readingIndex = 0;
  int _readingCorrect = 0;
  bool _readingAnswered = false;
  _PlayCheckResult _playResult = _PlayCheckResult.notChecked;
  final Map<int, bool> _techniqueAnswers = <int, bool>{};
  int _inferredStage = 5;
  late int _selectedStage;
  bool _stageTouched = false;
  bool _saving = false;

  PitchSource? _source;
  StreamSubscription<PitchFrame>? _subscription;
  bool _checkingMic = false;
  String? _micError;
  int _micGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = widget.initialStage ?? 5;
    _selectedStage = placementStages.contains(initial) ? initial : 5;
    _inferredStage = _selectedStage;
    if (widget.startAtResult) _step = 3;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopMic());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_stopMic());
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
      setState(() => _checkingMic = false);
    }
  }

  Future<void> _startMic() async {
    if (_checkingMic || _source != null) return;
    await _stopMic();
    if (!mounted) return;
    final generation = ++_micGeneration;
    setState(() {
      _checkingMic = true;
      _micError = null;
      _playResult = _PlayCheckResult.notChecked;
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
        _playResult = _PlayCheckResult.unavailable;
        _micError =
            'Microphone unavailable. You can continue without this check.';
      });
      return;
    }

    final settings =
        ref.read(appControllerProvider).asData?.value.progress.settings ??
        const AppSettings();
    final matcher = NoteMatcher(
      a4: settings.a4Hz,
      toleranceCents: settings.toleranceCents,
    );
    matcher.startExercise(_playTarget, grace: ref.read(lessonGraceProvider));
    _source = source;
    _subscription = source.frames.listen((frame) {
      if (!mounted || generation != _micGeneration) return;
      final result = matcher.addFrame(frame);
      if (result.state == MatchState.correct) {
        _finishPlayCheck(matchedTarget: true);
      } else if (result.state == MatchState.wrong ||
          result.state == MatchState.octave) {
        _finishPlayCheck(matchedTarget: false);
      }
    });
  }

  void _finishPlayCheck({required bool matchedTarget}) {
    if (!mounted) return;
    setState(() {
      _playResult = matchedTarget
          ? _PlayCheckResult.matched
          : _PlayCheckResult.other;
      _checkingMic = false;
    });
    unawaited(_stopMic());
  }

  void _goToStep(int step) {
    if (step == _step) return;
    if (_step == 1) unawaited(_stopMic());
    setState(() => _step = step);
  }

  void _advanceReading() {
    if (!_readingAnswered) return;
    if (_readingIndex >= _readingChecks.length - 1) {
      _goToStep(1);
      return;
    }
    setState(() {
      _readingIndex++;
      _readingAnswered = false;
    });
  }

  void _answerReading(Answer answer) {
    if (_readingAnswered) return;
    final verified = const PromptVerifier().verify(
      answer,
      _readingChecks[_readingIndex],
    );
    if (verified.correct) _readingCorrect++;
    setState(() => _readingAnswered = true);
  }

  void _openResult() {
    final inferred = widget.startAtResult
        ? _inferredStage
        : inferPlacementStage(
            readingLevel: widget.readingLevel,
            readingCorrect: _readingCorrect,
            readingTotal: _readingChecks.length,
            playedTarget: _playResult == _PlayCheckResult.matched,
            playedOther: _playResult == _PlayCheckResult.other,
            techniqueYes: _techniqueAnswers.values
                .where((value) => value)
                .length,
          );
    final resolved = widget.startAtResult
        ? _inferredStage
        : resolvePlacementStage(inferred);
    setState(() {
      _inferredStage = inferred;
      if (!_stageTouched) _selectedStage = resolved;
      _step = 3;
    });
  }

  void _selectStage(int stage) {
    if (!placementStages.contains(stage) || stage == _selectedStage) return;
    setState(() {
      _selectedStage = stage;
      _stageTouched = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final pieces = placementStarterSet(_selectedStage);
    if (pieces.length != 3) return;
    setState(() => _saving = true);
    unawaited(_stopMic());
    final manual =
        widget.startAtResult ||
        _stageTouched ||
        _selectedStage != resolvePlacementStage(_inferredStage);
    final record = await ref
        .read(placementControllerProvider.notifier)
        .savePlacement(
          inferredStage: _inferredStage,
          stage: _selectedStage,
          starterPieceIds: [for (final piece in pieces) piece.piece.id],
          manualOverride: manual,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(record);
  }

  void _skipFlow() {
    unawaited(_stopMic());
    Navigator.of(context).maybePop();
  }

  void _back() {
    if (widget.startAtResult) {
      _skipFlow();
      return;
    }
    if (_step == 0) {
      _skipFlow();
      return;
    }
    if (_step == 1) unawaited(_stopMic());
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 600,
          child: Column(
            children: [
              _PlacementHeader(step: _step, onBack: _back, onSkip: _skipFlow),
              if (_step < 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: _StepProgress(step: _step),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: switch (_step) {
                    0 => _ReadingStep(
                      index: _readingIndex,
                      prompt: _readingChecks[_readingIndex],
                      answered: _readingAnswered,
                      onAnswer: _answerReading,
                      onSkip: () => _goToStep(1),
                    ),
                    1 => _PlayingStep(
                      checkingMic: _checkingMic,
                      result: _playResult,
                      error: _micError,
                      hasGuitar: widget.hasGuitar,
                      onStart: _startMic,
                      onStop: _stopMic,
                      onSkip: () => _goToStep(2),
                    ),
                    2 => _TechniqueStep(
                      answers: _techniqueAnswers,
                      onChanged: (index, value) {
                        setState(() => _techniqueAnswers[index] = value);
                      },
                      onSkip: _openResult,
                    ),
                    _ => PlacementResultView(
                      inferredStage: _inferredStage,
                      selectedStage: _selectedStage,
                      onStageChanged: _selectStage,
                    ),
                  },
                ),
              ),
              _PlacementFooter(
                step: _step,
                saving: _saving,
                readingAnswered: _readingAnswered,
                onReadingContinue: _advanceReading,
                onPlayingContinue: () => _goToStep(2),
                onTechniqueContinue: _openResult,
                onSave: _save,
                onSkip: _skipFlow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _readingObjective = ObjectiveRef(
  'placement:reading',
  family: SkillFamily.noteReading,
);

const _rhythmObjective = ObjectiveRef(
  'placement:rhythm',
  family: SkillFamily.rhythm,
);

final _playTarget = Note.parse('G4');

enum _PlayCheckResult { notChecked, matched, other, unavailable }

class _PlacementHeader extends StatelessWidget {
  const _PlacementHeader({
    required this.step,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: step == 0
                ? IconButton(
                    tooltip: 'Close',
                    onPressed: onBack,
                    icon: const Icon(Icons.close_rounded),
                  )
                : IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Placement check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            key: const ValueKey('placement-skip'),
            onPressed: onSkip,
            child: const Text(
              'SKIP FOR NOW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: LessonProgressBar(
              value: index <= step ? 1 : 0,
              height: 8,
              color: index <= step ? AppColors.green : AppColors.border,
            ),
          ),
        ],
        const SizedBox(width: 12),
        Text(
          '${step + 1}/3',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ReadingStep extends StatelessWidget {
  const _ReadingStep({
    required this.index,
    required this.prompt,
    required this.answered,
    required this.onAnswer,
    required this.onSkip,
  });

  final int index;
  final Prompt prompt;
  final bool answered;
  final ValueChanged<Answer> onAnswer;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mascot(size: 84, mood: MascotMood.thinking),
        const SizedBox(height: 8),
        const Text(
          'Quick reading check',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Three short questions. It is not a test and it is not scored.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'QUESTION ${index + 1} OF 3',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          child: PromptView(
            key: ValueKey('placement-reading-$index'),
            prompt: prompt,
            onAnswer: onAnswer,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('placement-reading-skip'),
          onPressed: onSkip,
          child: const Text(
            'SKIP THIS CHECK',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PlayingStep extends StatelessWidget {
  const _PlayingStep({
    required this.checkingMic,
    required this.result,
    required this.error,
    required this.hasGuitar,
    required this.onStart,
    required this.onStop,
    required this.onSkip,
  });

  final bool checkingMic;
  final _PlayCheckResult result;
  final String? error;
  final bool? hasGuitar;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final finished =
        result == _PlayCheckResult.matched ||
        result == _PlayCheckResult.other ||
        result == _PlayCheckResult.unavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mascot(size: 84),
        const SizedBox(height: 8),
        const Text(
          'Play one note',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Play the written note below. One clear note is enough. This is not '
          'a test and it is not scored.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          color: AppColors.blueSoft,
          borderColor: AppColors.blue.withValues(alpha: 0.35),
          child: Column(
            children: [
              Text(
                _playTarget.display,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              Text(
                'Written pitch',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 12),
              if (checkingMic)
                Text(
                  'LISTENING…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.blueDark,
                  ),
                )
              else if (finished)
                Text(
                  result == _PlayCheckResult.unavailable
                      ? 'You can continue without this check.'
                      : 'Thanks. That is enough.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                )
              else
                Text(
                  'The microphone is only used while you tap the button.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!checkingMic)
          OutlineDuoButton(
            key: const ValueKey('placement-mic-start'),
            label: finished ? 'CHECK AGAIN' : 'CHECK MY PLAYING',
            icon: Icons.mic_rounded,
            color: AppColors.blue,
            onPressed: onStart,
          )
        else
          OutlineDuoButton(
            key: const ValueKey('placement-mic-stop'),
            label: 'STOP LISTENING',
            icon: Icons.stop_rounded,
            color: AppColors.textMuted,
            onPressed: onStop,
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
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
        if (hasGuitar == false) ...[
          const SizedBox(height: 8),
          Text(
            'No guitar right now? Skip this check and continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
        TextButton(
          key: const ValueKey('placement-playing-skip'),
          onPressed: onSkip,
          child: const Text(
            'SKIP THIS CHECK',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TechniqueStep extends StatelessWidget {
  const _TechniqueStep({
    required this.answers,
    required this.onChanged,
    required this.onSkip,
  });

  final Map<int, bool> answers;
  final void Function(int index, bool value) onChanged;
  final VoidCallback onSkip;

  static const _checks = <({String title, String detail})>[
    (
      title: 'Relaxed left hand',
      detail: 'My thumb stays behind the neck and my fingers stay curved.',
    ),
    (
      title: 'Steady right hand',
      detail: 'I can alternate fingers and keep a pulse without rushing.',
    ),
    (
      title: 'Clean shifts',
      detail: 'I can move position without a squeak or a lost beat.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Mascot(size: 84, mood: MascotMood.thinking),
        const SizedBox(height: 8),
        const Text(
          'Three quick self-checks',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Answer for yourself. The app does not judge your hand position, '
          'and there is no right answer here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < _checks.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TechniqueRow(
              index: index,
              title: _checks[index].title,
              detail: _checks[index].detail,
              answer: answers[index],
              onChanged: (value) => onChanged(index, value),
            ),
          ),
        SectionCard(
          color: AppColors.blueSoft,
          borderColor: AppColors.blue.withValues(alpha: 0.35),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                size: 18,
                color: AppColors.blueDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stop if you feel pain, numbness, or tingling. This check is '
                  'not a substitute for a teacher.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.blueDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          key: const ValueKey('placement-technique-skip'),
          onPressed: onSkip,
          child: const Text(
            'SKIP THIS CHECK',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({
    required this.index,
    required this.title,
    required this.detail,
    required this.answer,
    required this.onChanged,
  });

  final int index;
  final String title;
  final String detail;
  final bool? answer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final yes = answer == true;
    return SectionCard(
      color: yes ? AppColors.greenSoft : AppColors.background,
      borderColor: yes ? AppColors.green : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TechniqueChoice(
                  key: ValueKey('placement-technique-$index-yes'),
                  label: 'YES',
                  selected: yes,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TechniqueChoice(
                  key: ValueKey('placement-technique-$index-no'),
                  label: 'NOT YET',
                  selected: answer == false,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechniqueChoice extends StatelessWidget {
  const _TechniqueChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: DuoTappable(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementFooter extends StatelessWidget {
  const _PlacementFooter({
    required this.step,
    required this.saving,
    required this.readingAnswered,
    required this.onReadingContinue,
    required this.onPlayingContinue,
    required this.onTechniqueContinue,
    required this.onSave,
    required this.onSkip,
  });

  final int step;
  final bool saving;
  final bool readingAnswered;
  final VoidCallback onReadingContinue;
  final VoidCallback onPlayingContinue;
  final VoidCallback onTechniqueContinue;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final child = switch (step) {
      0 => DuoButton(
        key: const ValueKey('placement-reading-continue'),
        label: 'CONTINUE',
        onPressed: readingAnswered ? onReadingContinue : null,
        icon: Icons.arrow_forward_rounded,
      ),
      1 => DuoButton(
        key: const ValueKey('placement-playing-continue'),
        label: 'CONTINUE',
        onPressed: onPlayingContinue,
        icon: Icons.arrow_forward_rounded,
      ),
      2 => DuoButton(
        key: const ValueKey('placement-technique-continue'),
        label: 'SEE MY STARTING POINT',
        onPressed: onTechniqueContinue,
        icon: Icons.flag_rounded,
      ),
      _ => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DuoButton(
            key: const ValueKey('placement-save'),
            label: saving ? 'SAVING…' : 'SAVE THIS STARTING POINT',
            onPressed: saving ? null : onSave,
            icon: Icons.check_rounded,
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('placement-result-skip'),
            onPressed: saving ? null : onSkip,
            child: const Text(
              'NOT NOW',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: child,
    );
  }
}
