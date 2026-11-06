import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/note_matcher.dart';
import '../../core/audio/pitch_source.dart';
import '../../core/learning/progress.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/lesson_run.dart';
import '../../core/learning/verifier.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../core/notation/staff_painter.dart';
import '../../shared/audio/sound_service.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/feedback_panel.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../exercises/fret_tap_view.dart';
import '../exercises/prompt_view.dart';
import 'lesson_layout.dart';

/// Converts a sounding pitch to the written guitar note, keeping the spelling
/// of the exercise target so B-flat does not turn into A-sharp.
Note? _writtenFromSounding(Note? sounding, Note? target) {
  if (sounding == null) return null;
  return sounding.transposed(
    12,
    preferFlats: target?.accidental == Accidental.flat,
  );
}

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with WidgetsBindingObserver {
  PitchSource? _source;
  StreamSubscription<PitchFrame>? _subscription;
  NoteMatcher? _matcher;
  PitchReading _reading = PitchReading.silent;
  String? _micError;
  bool _startingMic = false;
  bool _forceName = false;
  bool _submitting = false;
  int _micGeneration = 0;
  String? _activeKey;
  String? _selectedOptionId;
  String? _promptKey;
  DateTime? _promptStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      return;
    }
    if (state == AppLifecycleState.resumed && mounted) {
      final run = ref.read(appControllerProvider).asData?.value.run;
      final prompt = run?.current;
      if (run != null &&
          prompt is NotePrompt &&
          prompt.isPlay &&
          !run.awaitingNext &&
          !_forceName) {
        unawaited(_ensureMic());
      }
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
        _startingMic = false;
      });
    }
  }

  Future<void> _ensureMic() async {
    if (_source != null || _startingMic) return;
    final generation = ++_micGeneration;
    setState(() {
      _startingMic = true;
      _micError = null;
    });
    final factory = ref.read(pitchSourceFactoryProvider);
    final source = factory();
    try {
      final started = await source.start();
      if (!mounted || generation != _micGeneration) {
        await source.dispose();
        return;
      }
      if (!started) {
        await source.dispose();
        if (!mounted || generation != _micGeneration) return;
        setState(() {
          _startingMic = false;
          _micError =
              'Microphone unavailable. Check permissions, or answer with note names.';
        });
        return;
      }
      final data = ref.read(appControllerProvider).asData?.value;
      final run = data?.run;
      final prompt = run?.current;
      if (run == null ||
          prompt is! NotePrompt ||
          !prompt.isPlay ||
          run.awaitingNext ||
          _forceName) {
        await source.dispose();
        if (mounted && generation == _micGeneration) {
          setState(() => _startingMic = false);
        }
        return;
      }
      _source = source;
      _subscription = source.frames.listen((frame) {
        if (!mounted || generation != _micGeneration) return;
        _onFrame(frame);
      });
      if (mounted) setState(() => _startingMic = false);
    } catch (_) {
      await source.dispose();
      if (!mounted || generation != _micGeneration) return;
      setState(() {
        _startingMic = false;
        _micError = 'Could not start the microphone.';
      });
    }
  }

  void _onFrame(PitchFrame frame) {
    final data = ref.read(appControllerProvider).asData?.value;
    final run = data?.run;
    final matcher = _matcher;
    if (run == null || matcher == null || run.awaitingNext || _submitting) {
      return;
    }
    final prompt = run.current;
    if (prompt is! NotePrompt || !prompt.isPlay || _forceName) return;

    final result = matcher.addFrame(frame);
    if (mounted) {
      setState(() => _reading = result.reading);
    }

    switch (result.state) {
      case MatchState.correct:
      case MatchState.wrong:
      case MatchState.octave:
        _submitPitch(prompt, result);
      case MatchState.listening:
      case MatchState.silent:
        break;
    }
  }

  /// Routes the audio matcher's verdict through the shared verifier so the
  /// screen never decides correctness on its own.
  void _submitPitch(NotePrompt prompt, MatchResult result) {
    final verdict = const PromptVerifier().verify(
      PitchAnswer(
        outcome: switch (result.state) {
          MatchState.correct => PitchOutcome.correct,
          MatchState.octave => PitchOutcome.octave,
          _ => PitchOutcome.wrong,
        },
        cents: result.reading.voiced ? result.reading.cents : null,
        detected: result.reading.note,
      ),
      prompt,
    );
    unawaited(
      _submit(
        outcome: verdict.correct
            ? AttemptOutcome.correct
            : AttemptOutcome.incorrect,
        cents: result.reading.voiced ? result.reading.cents : null,
        detected: result.reading.note,
        octaveError: verdict.octaveError,
      ),
    );
  }

  Future<void> _submit({
    required AttemptOutcome outcome,
    double? cents,
    Note? detected,
    bool octaveError = false,
  }) async {
    if (_submitting) return;
    final data = ref.read(appControllerProvider).asData?.value;
    final run = data?.run;
    if (run == null || run.awaitingNext) return;

    _submitting = true;
    final settings = data!.progress.settings;
    if (settings.haptics && outcome.isDeterminate) {
      if (outcome == AttemptOutcome.correct) {
        unawaited(HapticFeedback.lightImpact());
      } else {
        unawaited(HapticFeedback.mediumImpact());
      }
    }

    await ref
        .read(appControllerProvider.notifier)
        .submitOutcome(
          outcome,
          cents: cents,
          detected: detected,
          octaveError: octaveError,
          responseMs: _promptStartedAt == null
              ? 0
              : DateTime.now().difference(_promptStartedAt!).inMilliseconds,
        );
    final updatedRun = ref.read(appControllerProvider).asData?.value.run;
    if (outcome == AttemptOutcome.indeterminate) {
      // A calm retry: no error cue and no reward cue.
    } else if (outcome == AttemptOutcome.correct) {
      _play(
        (updatedRun?.combo ?? 0) >= 3
            ? Sfx.answerCorrectCombo
            : Sfx.answerCorrect,
      );
    } else if (octaveError) {
      _play(Sfx.answerOctave);
    } else if (updatedRun != null &&
        !updatedRun.isPractice &&
        updatedRun.lives == 0) {
      _play(Sfx.lifeLost);
    } else {
      _play(Sfx.answerWrong);
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _play(Sfx sound) {
    unawaited(ref.read(soundServiceProvider).play(sound));
  }

  Future<void> _continue() async {
    await ref.read(appControllerProvider.notifier).nextExercise();
  }

  /// Routes any tap-based prompt through the shared verifier.
  void _submitPrompt(Prompt prompt, Answer answer) {
    final verdict = const PromptVerifier().verify(answer, prompt);
    unawaited(
      _submit(
        outcome: verdict.correct
            ? AttemptOutcome.correct
            : AttemptOutcome.incorrect,
      ),
    );
  }

  void _retryCurrent() {
    ref.read(appControllerProvider.notifier).retryCurrent();
    setState(() {
      _submitting = false;
      _reading = PitchReading.silent;
      _selectedOptionId = null;
      _activeKey = null;
      // The retry is a new attempt. Do not let the indeterminate take's
      // reading time contaminate the next response-time rating.
      _promptStartedAt = DateTime.now();
    });
  }

  void _prepareExercise(LessonRun run, NotePrompt exercise, bool showPlay) {
    if (!mounted) return;
    unawaited(ref.read(audioEngineProvider).stop());
    _selectedOptionId = null;
    _reading = PitchReading.silent;
    _submitting = false;
    if (showPlay && !run.awaitingNext) {
      final settings = ref
          .read(appControllerProvider)
          .requireValue
          .progress
          .settings;
      final matcher = NoteMatcher(
        a4: settings.a4Hz,
        toleranceCents: settings.toleranceCents,
      );
      matcher.startExercise(
        exercise.note,
        grace: ref.read(lessonGraceProvider),
      );
      _matcher = matcher;
      unawaited(_ensureMic());
    } else {
      _matcher?.clear();
      _matcher = null;
      unawaited(_stopMic());
    }
    if (mounted) setState(() {});
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this lesson?'),
        content: const Text(
          'Answers from this session still count toward your notes, but the lesson will not be completed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _play(Sfx.uiTapSecondary);
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              _play(Sfx.uiLocked);
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldExit != true || !mounted) return;
    ref.read(appControllerProvider.notifier).exitLesson();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).asData?.value;
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (data.result != null) {
      return LessonCompleteView(
        result: data.result!,
        onContinue: () {
          ref.read(appControllerProvider.notifier).dismissResult();
          Navigator.of(context).pop();
        },
        onRetry: () {
          ref.read(appControllerProvider.notifier).retryLesson();
          setState(() {
            _forceName = false;
            _micError = null;
            _reading = PitchReading.silent;
            _selectedOptionId = null;
            _activeKey = null;
            _matcher = null;
          });
        },
      );
    }
    final run = data.run;
    if (run == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prompt = run.current;
    final promptKey = '${run.index}-${prompt.templateId}';
    if (promptKey != _promptKey) {
      _promptKey = promptKey;
      _promptStartedAt = DateTime.now();
    }
    final exercise = prompt is NotePrompt ? prompt : null;
    if (exercise == null) {
      final question = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            run.isPractice ? 'Practice' : 'Lesson',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            promptTitle(prompt),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          PromptView(
            key: ValueKey(
              '${run.index}-${prompt.templateId}-${prompt.isTeach}',
            ),
            prompt: prompt,
            onAnswer: (answer) => _submitPrompt(prompt, answer),
          ),
        ],
      );

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(bottom: false,
            child: LessonLayout(
              header: _LessonTopBar(
                run: run,
                onClose: () {
                  _play(Sfx.uiTapSecondary);
                  _confirmExit();
                },
              ),
              question: question,
              questionKey: '${run.index}-${prompt.templateId}',
              answers: prompt.isTeach
                  ? DuoButton(
                      label: 'GOT IT',
                      onPressed: _continue,
                      color: AppColors.blue,
                    )
                  : null,
              feedback: run.awaitingNext
                  ? _FeedbackForRun(
                      key: ValueKey('feedback-${run.index}-${run.lastOutcome}'),
                      run: run,
                      onContinue: _continue,
                      onRetry: _retryCurrent,
                    )
                  : null,
            ),
          ),
        ),
      );
    }
    final showPlay = exercise.isPlay && !_forceName;
    final activationKey =
        '${run.index}|${exercise.note.id}|$showPlay|${run.awaitingNext}|$_forceName';
    if (activationKey != _activeKey) {
      _activeKey = activationKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prepareExercise(run, exercise, showPlay);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(bottom: false,
          child: LessonLayout(
            header: _LessonTopBar(
              run: run,
              onClose: () {
                _play(Sfx.uiTapSecondary);
                _confirmExit();
              },
            ),
            question: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  run.isPractice
                      ? (run.practiceTitle ?? 'Practice')
                      : run.isReviewingMistakes
                      ? 'Mistake review'
                      : (run.lesson.isReview
                            ? 'Unit checkpoint'
                            : 'Lesson'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.isTeach
                      ? 'A new note'
                      : run.isReviewingMistakes
                      ? 'Try this note again'
                      : showPlay
                      ? 'Play this note'
                      : 'What note is this?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _StaffCard(note: exercise.note, isNew: exercise.isNew),
                if (exercise.isTeach) ...[
                  const SizedBox(height: 16),
                  _TeachCard(prompt: exercise),
                ],
              ],
            ),
            questionKey: '${run.index}-${exercise.note.id}',
            answers: KeyedSubtree(
              key: ValueKey('answers-${run.index}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (exercise.isTeach)
                    DuoButton(
                      label: 'GOT IT',
                      onPressed: _continue,
                      color: AppColors.blue,
                    )
                  else if (showPlay)
                    _MicAnswer(
                      reading: _reading,
                      target: exercise.note,
                      toleranceCents: data.progress.settings.toleranceCents,
                      starting: _startingMic,
                      error: _micError,
                      onUseNames: () {
                        setState(() {
                          _forceName = true;
                          _activeKey = null;
                        });
                      },
                      onSkip: () => _submit(outcome: AttemptOutcome.incorrect),
                    )
                  else
                    _NameAnswer(
                      exercise: exercise,
                      run: run,
                      selectedOptionId: _selectedOptionId,
                      onSelected: (option) {
                        setState(() => _selectedOptionId = option.id);
                        final verdict = const PromptVerifier().verify(
                          ChoiceAnswer(option.id),
                          exercise,
                        );
                        _submit(
                          outcome: verdict.correct
                              ? AttemptOutcome.correct
                              : AttemptOutcome.incorrect,
                        );
                      },
                    ),
                ],
              ),
            ),
            feedback: run.awaitingNext
                ? _FeedbackForRun(
                    key: ValueKey('feedback-${run.index}-${run.lastOutcome}'),
                    run: run,
                    onContinue: _continue,
                    onRetry: _retryCurrent,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _LessonTopBar extends StatelessWidget {
  const _LessonTopBar({required this.run, required this.onClose});

  final LessonRun run;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= LessonLayout.wideBreakpoint;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 24 : 16,
            8,
            wide ? 24 : 16,
            6,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LessonLayout.columnWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textLight,
                        tooltip: 'Quit lesson',
                      ),
                      const Spacer(),
                      if (run.isPractice)
                        const Text(
                          'PRACTICE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.blueDark,
                          ),
                        )
                      else if (run.lesson.isReview)
                        const Text(
                          'CHECKPOINT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.yellowDark,
                          ),
                        )
                      else
                        HeartsRow(lives: run.lives),
                    ],
                  ),
                  // The bar shares the content column, so its edges line up
                  // with the staff card instead of floating at a different
                  // centre.
                  LessonProgressBar(value: run.progress, height: 14),
                  const SizedBox(height: 4),
                  Text(
                    run.stepLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.note, required this.isNew});

  final Note note;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFEDEDED),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 15,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                'TREBLE CLEF',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          StaffView(
            note: note,
            height: 218,
            staffColor: AppColors.textLight,
            noteColor: AppColors.text,
          ),
        ],
      ),
    );
  }
}

class _TeachCard extends StatelessWidget {
  const _TeachCard({required this.prompt});

  final NotePrompt prompt;

  @override
  Widget build(BuildContext context) {
    final position = Guitar.bestPosition(prompt.note);
    final positions = Guitar.positionsFor(prompt.note, maxFret: 4);
    return SectionCard(
      color: AppColors.blueSoft,
      borderColor: AppColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEW NOTE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.blueDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prompt.note.display,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position == null
                ? 'Find it on the staff, then say its name.'
                : '${position.label}. Here it is on the neck.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          if (positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            FretboardDiagram(
              maxFret: 4,
              positions: positions,
              height: 170,
            ),
          ],
        ],
      ),
    );
  }
}

class _NameAnswer extends StatelessWidget {
  const _NameAnswer({
    required this.exercise,
    required this.run,
    required this.selectedOptionId,
    required this.onSelected,
  });

  final NotePrompt exercise;
  final LessonRun run;
  final String? selectedOptionId;
  final ValueChanged<Note> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = exercise.choices;
    final rows = <Widget>[];
    for (var index = 0; index < options.length; index += 2) {
      final left = options[index];
      final right = index + 1 < options.length ? options[index + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: AnswerOption(
                label: left.display,
                state: _stateFor(left),
                onTap: run.awaitingNext ? null : () => onSelected(left),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: right == null
                  ? const SizedBox()
                  : AnswerOption(
                      label: right.display,
                      state: _stateFor(right),
                      onTap: run.awaitingNext ? null : () => onSelected(right),
                    ),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 8));
    }

    return Column(children: rows);
  }

  AnswerOptionState _stateFor(Note option) {
    if (!run.awaitingNext) return AnswerOptionState.idle;
    if (option.id == exercise.note.id) return AnswerOptionState.correct;
    if (option.id == selectedOptionId) return AnswerOptionState.wrong;
    return AnswerOptionState.dimmed;
  }
}

class _MicAnswer extends StatelessWidget {
  const _MicAnswer({
    required this.reading,
    required this.target,
    required this.toleranceCents,
    required this.starting,
    required this.error,
    required this.onUseNames,
    required this.onSkip,
  });

  final PitchReading reading;
  final Note target;
  final int toleranceCents;
  final bool starting;
  final String? error;
  final VoidCallback onUseNames;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Column(
        children: [
          SectionCard(
            color: AppColors.redSoft,
            borderColor: AppColors.red,
            child: Row(
              children: [
                const Icon(Icons.mic_off_rounded, color: AppColors.redDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.redDark,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DuoButton(
            label: 'USE NOTE NAMES INSTEAD',
            onPressed: onUseNames,
            color: AppColors.blue,
          ),
          const SizedBox(height: 8),
          OutlineDuoButton(
            label: 'SKIP THIS NOTE',
            onPressed: onSkip,
            color: AppColors.textMuted,
          ),
        ],
      );
    }

    final detected = _writtenFromSounding(reading.note, target);
    final voiced = reading.voiced && detected != null;
    final cents = reading.cents;
    final inTune = voiced && cents.abs() <= toleranceCents;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: voiced
                      ? (inTune ? AppColors.greenSoft : AppColors.blueSoft)
                      : AppColors.background,
                  border: Border.all(
                    color: voiced
                        ? (inTune ? AppColors.green : AppColors.blue)
                        : AppColors.borderStrong,
                    width: 3,
                  ),
                ),
                child: Icon(
                  voiced ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  color: voiced
                      ? (inTune ? AppColors.greenDark : AppColors.blueDark)
                      : AppColors.textLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: voiced
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                detected.display,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${cents.toStringAsFixed(0)}¢',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: inTune
                                      ? AppColors.greenDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            inTune
                                ? 'Hold it there…'
                                : '${cents > 0 ? 'A little sharp' : 'A little flat'} — tune the note',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            starting ? 'Starting microphone…' : 'Listening…',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Play the note and hold it for a moment.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _CentsRuler(cents: voiced ? cents : null),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlineDuoButton(
                label: 'USE NOTE NAMES',
                onPressed: onUseNames,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlineDuoButton(
                label: 'SKIP',
                onPressed: onSkip,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CentsRuler extends StatelessWidget {
  const _CentsRuler({required this.cents});

  final double? cents;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final clamped = cents?.clamp(-50.0, 50.0);
        final position = clamped == null ? null : (clamped + 50) / 100 * width;
        return SizedBox(
          height: 22,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: Container(height: 2, color: AppColors.border),
              ),
              Positioned(
                left: width / 2 - 1,
                top: 4,
                child: Container(width: 2, height: 14, color: AppColors.green),
              ),
              if (position != null)
                Positioned(
                  left: (position - 6).clamp(0.0, width - 12),
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: clamped!.abs() <= 5
                          ? AppColors.green
                          : AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  '−50',
                  style: TextStyle(fontSize: 9, color: AppColors.textLight),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Text(
                  '+50',
                  style: TextStyle(fontSize: 9, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedbackForRun extends StatelessWidget {
  const _FeedbackForRun({
    super.key,
    required this.run,
    required this.onContinue,
    required this.onRetry,
  });

  final LessonRun run;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final outcome = run.lastOutcome ?? AttemptOutcome.incorrect;
    if (outcome == AttemptOutcome.indeterminate) {
      return FeedbackPanel(
        correct: false,
        indeterminate: true,
        title: 'Could not hear that clearly',
        subtitle: 'Try again — nothing was scored.',
        detail: 'Your progress, hearts, and streak are unchanged.',
        onContinue: onRetry,
        continueLabel: 'TRY AGAIN',
      );
    }

    final correct = outcome == AttemptOutcome.correct;
    final target = run.lastTarget;
    final position = target == null ? null : Guitar.bestPosition(target);
    final cents = run.lastCents;
    final detected = run.lastDetected;
    final detectedWritten = _writtenFromSounding(detected, target);

    final octaveError = !correct && run.lastOctaveError;
    final outOfLives = !run.isPractice && !correct && run.outOfLives;
    final title = outOfLives
        ? 'Out of hearts'
        : correct
        ? (run.combo >= 3 ? 'Combo x${run.combo}!' : 'Correct!')
        : octaveError
        ? 'Right note, wrong octave'
        : 'Not quite';

    final subtitle = correct
        ? '${target?.display ?? ''}${position == null ? '' : '  ·  ${position.label}'}'
        : octaveError
        ? 'You played ${detectedWritten?.display ?? 'the same note'} in the wrong octave.'
        : 'The correct note is ${target?.display ?? ''}';

    String? detail;
    if (!correct) {
      final parts = <String>[];
      if (position != null) parts.add(position.label);
      if (detectedWritten != null && !octaveError) {
        parts.add('You played ${detectedWritten.display}');
      }
      if (octaveError) {
        parts.add('Check which string and octave you are using');
      }
      if (parts.isNotEmpty) detail = parts.join('  ·  ');
    } else if (cents != null) {
      detail =
          '${cents.abs().toStringAsFixed(0)} cents ${cents >= 0 ? 'sharp' : 'flat'} — nicely matched.';
    }

    return FeedbackPanel(
      correct: correct,
      title: title,
      subtitle: subtitle,
      detail: detail,
      onContinue: onContinue,
      continueLabel: outOfLives
          ? 'SEE RESULTS'
          : run.index >= run.exercises.length - 1
          ? 'FINISH'
          : 'CONTINUE',
    );
  }
}

class LessonCompleteView extends ConsumerStatefulWidget {
  const LessonCompleteView({
    super.key,
    required this.result,
    required this.onContinue,
    required this.onRetry,
  });

  final LessonResult result;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  ConsumerState<LessonCompleteView> createState() =>
      _LessonCompleteViewState();
}

class _LessonCompleteViewState extends ConsumerState<LessonCompleteView> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 1));
    if (widget.result.passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
    unawaited(_playResultSounds());
  }

  Future<void> _playResultSounds() async {
    final result = widget.result;
    final sounds = <Sfx>[];
    if (!result.passed) {
      sounds.add(Sfx.lessonFailed);
    } else if (result.isPractice) {
      sounds.add(Sfx.practiceComplete);
    } else if (result.accuracy >= 1) {
      sounds.add(Sfx.lessonPerfect);
    } else {
      sounds.add(Sfx.lessonComplete);
    }

    if (result.leveledUp) {
      sounds.add(Sfx.rewardLevelUp);
    } else if (result.dailyGoalReached) {
      sounds.add(Sfx.rewardDailyGoal);
    } else if (result.streakMilestone) {
      sounds.add(Sfx.rewardStreakMilestone);
    } else if (result.streakAdvanced) {
      sounds.add(Sfx.rewardStreak);
    } else if (result.lessonUnlocked) {
      sounds.add(Sfx.rewardUnlock);
    }
    if (result.xp > 0) sounds.add(Sfx.xpTick);

    await ref.read(soundServiceProvider).playSequence(sounds);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isCheckpoint = lessonById[result.lessonId]?.isReview ?? false;
    final progress = ref.watch(appControllerProvider).asData?.value.progress;
    final hearts = progress?.hearts ?? maxHearts;
    final canRefill =
        !result.passed && hearts <= 0 && (progress?.gems ?? 0) >= heartRefillCost;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: PageFrame(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    Mascot(
                      size: 140,
                      mood: result.passed
                          ? MascotMood.cheer
                          : MascotMood.thinking,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.passed
                          ? (result.isPractice
                                ? 'Practice complete!'
                                : result.lessonId.startsWith('jump_')
                                ? 'Section unlocked!'
                                : isCheckpoint
                                ? 'Unit complete!'
                                : 'Lesson complete!')
                          : 'Out of hearts',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.passed
                          ? '${result.title} · ${(result.accuracy * 100).round()}% accuracy'
                          : 'You answered ${result.answered} exercises. Try again — your notes are still saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultStat(
                            icon: Icons.bolt_rounded,
                            color: AppColors.yellowDark,
                            value: '+${result.xp}',
                            label: 'XP',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ResultStat(
                            icon: Icons.speed_rounded,
                            color: AppColors.blue,
                            value: '${(result.accuracy * 100).round()}%',
                            label: 'Accuracy',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ResultStat(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF9600),
                            value: '${result.streak}',
                            label: 'Streak',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (result.passed)
                      DuoButton(label: 'CONTINUE', onPressed: widget.onContinue)
                    else ...[
                      if (canRefill)
                        DuoButton(
                          label: 'REFILL & RETRY',
                          onPressed: () async {
                            final bought = await ref
                                .read(appControllerProvider.notifier)
                                .buyHeartRefill();
                            if (bought) widget.onRetry();
                          },
                        )
                      else if (hearts <= 0)
                        DuoButton(label: 'OUT OF HEARTS', onPressed: null)
                      else
                        DuoButton(label: 'TRY AGAIN', onPressed: widget.onRetry),
                      const SizedBox(height: 8),
                      OutlineDuoButton(
                        label: 'BACK TO PATH',
                        onPressed: widget.onContinue,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 18,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.2,
              colors: const [
                AppColors.green,
                AppColors.yellow,
                AppColors.blue,
                AppColors.purple,
              ],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
