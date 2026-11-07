import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/phrase_prompt.dart';
import '../../core/audio/phrase_verifier.dart';
import '../../core/learning/attempt_outcome.dart';
import '../../core/media/recording_index.dart';
import '../../core/music/guitar.dart';
import '../../core/music/note.dart';
import '../../core/music/note_event.dart';
import '../../core/music/phrase.dart';
import '../../core/music/piece.dart';
import '../../core/retention/retention_event.dart';
import '../../shared/navigation/duo_route.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/feedback_panel.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../../state/recording_controller.dart';
import '../../state/retention_controller.dart';
import '../phrase/phrase_player_screen.dart';

/// The four written notes of the first-session phrase.
///
/// Ode to Joy, first phrase, written E5 E5 F5 G5 (sounding one octave lower).
/// It is monophonic, first position, and on string 1 only.
Phrase firstSessionPhrase() {
  const e5 = Note('E', 5);
  const f5 = Note('F', 5);
  const g5 = Note('G', 5);
  NoteEvent event(double beat, Note note, int fret) => NoteEvent(
    startBeat: beat,
    durationBeats: 1,
    kind: NoteEventKind.note,
    writtenNote: note,
    soundingMidi: Guitar.soundingMidiForWritten(note),
    string: 1,
    fret: fret,
  );
  return Phrase(
    id: 'first-session-ode',
    bars: 1,
    timeSignature: const TimeSignature(4, 4),
    events: <NoteEvent>[
      event(0, e5, 0),
      event(1, e5, 0),
      event(2, f5, 1),
      event(3, g5, 3),
    ],
    targetTempoBpm: 60,
    title: 'Ode to Joy — first four notes',
    difficulty: 1,
  );
}

/// A guided first session: hear four notes, play them, see one correction, and
/// record ten seconds.
///
/// This is practice-only. It never writes FSRS, mastery, XP, or streak evidence
/// from the phrase take; the recording is the only saved artifact. The phrase
/// loop's scored path remains behind decision 0001.
class FirstSessionScreen extends ConsumerStatefulWidget {
  const FirstSessionScreen({
    super.key,
    this.playerBuilder,
    this.recordingBuilder,
  });

  /// Test seam: returns a widget that eventually pops a [PhraseVerification].
  /// Production pushes the real practice-only phrase player.
  final WidgetBuilder? playerBuilder;

  /// Test seam for the 10-second recording step.
  final FirstRecordingStepBuilder? recordingBuilder;

  @override
  ConsumerState<FirstSessionScreen> createState() => _FirstSessionScreenState();
}

/// Builds the recording step with its completion callbacks. Tests inject a
/// lightweight stand-in; production uses [_FirstRecordingStep].
typedef FirstRecordingStepBuilder =
    Widget Function(
      BuildContext context,
      void Function(RecordingTake? take) onSaved,
      VoidCallback onSkip,
    );

enum _Step { intro, hear, play, correction, record, done }

class _FirstSessionScreenState extends ConsumerState<FirstSessionScreen> {
  final Stopwatch _clock = Stopwatch();
  _Step _step = _Step.intro;
  PhraseVerification? _verification;
  bool _finished = false;
  bool _firstNoteRecorded = false;
  bool _firstPhraseRecorded = false;
  String? _notice;

  Phrase get _phrase => firstSessionPhrase();

  @override
  void initState() {
    super.initState();
    _clock.start();
    unawaited(
      ref
          .read(retentionControllerProvider.notifier)
          .record(RetentionEventName.sessionStart),
    );
  }

  @override
  void dispose() {
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 600,
          child: ListView(
            key: const ValueKey('first-session-list'),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _progress(),
              const SizedBox(height: 20),
              switch (_step) {
                _Step.intro => _intro(),
                _Step.hear => _hear(),
                _Step.play => _playWaiting(),
                _Step.correction => _correction(),
                _Step.record => _record(),
                _Step.done => _done(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _progress() {
    final index = switch (_step) {
      _Step.intro => 0,
      _Step.hear => 1,
      _Step.play => 2,
      _Step.correction => 3,
      _Step.record => 4,
      _Step.done => 5,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: i == index - 1 ? 26 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= index - 1 ? AppColors.green : AppColors.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    );
  }

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your first 3 minutes',
          key: const ValueKey('first-session-title'),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hear four notes, play them back, see one correction, then record '
          'ten seconds. That is enough for today.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        const _NoteChips(),
        const SizedBox(height: 24),
        DuoButton(
          key: const ValueKey('first-session-start'),
          label: 'START',
          height: 56,
          onPressed: () => setState(() => _step = _Step.hear),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('first-session-skip'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('SKIP FOR NOW'),
        ),
      ],
    );
  }

  Widget _hear() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hear the first four notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Listen once. You do not need to read the staff yet — just copy what '
          'you hear.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        const _NoteChips(),
        const SizedBox(height: 20),
        OutlineDuoButton(
          key: const ValueKey('first-session-hear'),
          label: 'HEAR 4 NOTES',
          icon: Icons.play_arrow_rounded,
          onPressed: _playPreview,
        ),
        const SizedBox(height: 10),
        DuoButton(
          key: const ValueKey('first-session-ready'),
          label: 'I’M READY TO PLAY',
          height: 56,
          onPressed: _openPlayer,
        ),
      ],
    );
  }

  Widget _playWaiting() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Listen for the four notes and play them back.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _correction() {
    final verification = _verification;
    if (verification == null) {
      setState(() => _step = _Step.hear);
      return const SizedBox.shrink();
    }
    final correct = verification.outcome == AttemptOutcome.correct;
    final indeterminate = verification.outcome == AttemptOutcome.indeterminate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'One correction',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        FeedbackPanel(
          correct: correct,
          indeterminate: indeterminate,
          title: indeterminate
              ? 'Could not hear that clearly'
              : correct
              ? 'That was the phrase'
              : 'Not quite',
          subtitle: indeterminate
              ? 'Try again — nothing was scored.'
              : verification.correction,
          detail: correct
              ? 'Keep the same steady pulse. You can record it now.'
              : 'Try once more, or record what you have. This is practice, '
                    'not a test.',
          onContinue: () => setState(() => _step = _Step.record),
          continueLabel: 'RECORD 10 SECONDS',
        ),
        const SizedBox(height: 8),
        OutlineDuoButton(
          key: const ValueKey('first-session-retry'),
          label: 'TRY AGAIN',
          onPressed: _openPlayer,
        ),
      ],
    );
  }

  Widget _record() {
    final builder = widget.recordingBuilder;
    void onSaved(RecordingTake? take) {
      if (take != null) {
        setState(() => _notice = 'Take saved on this device.');
      }
      setState(() => _step = _Step.done);
    }

    void onSkip() {
      setState(() => _step = _Step.done);
    }

    if (builder != null) return builder(context, onSaved, onSkip);
    return _FirstRecordingStep(onSaved: onSaved, onSkip: onSkip);
  }

  Widget _done() {
    if (!_finished) {
      _finished = true;
      unawaited(_finish());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You played your first phrase',
          key: const ValueKey('first-session-done'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _notice ??
              'That is a real start. Come back tomorrow for five more minutes.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        DuoButton(
          key: const ValueKey('first-session-finish'),
          label: 'GO TO LEARN',
          height: 56,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Future<void> _finish() async {
    final elapsed = _clock.elapsed;
    try {
      await ref
          .read(retentionControllerProvider.notifier)
          .record(RetentionEventName.sessionComplete);
      await ref
          .read(retentionControllerProvider.notifier)
          .recordDailyActive();
    } catch (_) {
      // Instrumentation is best-effort and must not block the done screen.
    }
    try {
      await ref
          .read(appControllerProvider.notifier)
          .recordTodayPractice(instrumentTime: elapsed);
    } catch (_) {
      // The learner already had the session; a save hiccup is not a failure.
    }
  }

  Future<void> _playPreview() async {
    final prompt = PhrasePlayPrompt(phrase: _phrase);
    await ref.read(audioEngineProvider).play(prompt.previewSpec);
  }

  Future<void> _openPlayer() async {
    setState(() => _step = _Step.play);
    final builder =
        widget.playerBuilder ??
        (context) => PhrasePlayerScreen(
          phrase: _phrase,
          practiceOnly: true,
          recordProgress: false,
          onVerification: (verification) {
            if (!context.mounted) return;
            Navigator.of(context).pop(verification);
          },
        );
    final verification = await Navigator.of(context).push<PhraseVerification>(
      duoLessonRoute(builder),
    );
    if (!mounted) return;
    if (verification == null) {
      setState(() => _step = _Step.hear);
      return;
    }
    if (!_firstNoteRecorded && verification.complete) {
      _firstNoteRecorded = true;
      await ref.read(retentionControllerProvider.notifier).recordFirstNote();
    }
    if (!_firstPhraseRecorded && verification.complete) {
      _firstPhraseRecorded = true;
      await ref.read(retentionControllerProvider.notifier).recordFirstPhrase();
    }
    setState(() {
      _verification = verification;
      _step = _Step.correction;
    });
  }
}

class _NoteChips extends StatelessWidget {
  const _NoteChips();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _NoteChip(label: 'E5', detail: 'string 1, open'),
        _NoteChip(label: 'E5', detail: 'string 1, open'),
        _NoteChip(label: 'F5', detail: 'string 1, fret 1'),
        _NoteChip(label: 'G5', detail: 'string 1, fret 3'),
      ],
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 10-second take. It uses the same recording controller as the recordings
/// screen: one live take, typed failures, and no second recorder.
class _FirstRecordingStep extends ConsumerStatefulWidget {
  const _FirstRecordingStep({required this.onSaved, required this.onSkip});

  final void Function(RecordingTake? take) onSaved;
  final VoidCallback onSkip;

  @override
  ConsumerState<_FirstRecordingStep> createState() => _FirstRecordingStepState();
}

class _FirstRecordingStepState extends ConsumerState<_FirstRecordingStep> {
  Timer? _timer;
  int _remaining = 10;
  bool _started = false;
  bool _saving = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recordingControllerProvider);
    final state = async.asData?.value;
    final recording = state?.recording ?? false;
    final failure = state?.failure;
    final saved = state?.lastSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record 10 seconds',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Play the four notes once. Stop whenever you like; ten seconds is the '
          'limit.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        if (recording)
          Center(
            child: Text(
              'Listening… ${_remaining}s',
              key: const ValueKey('first-session-recording-timer'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
        if (failure != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            color: AppColors.redSoft,
            borderColor: AppColors.red,
            child: Text(
              failure.message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            color: AppColors.redSoft,
            borderColor: AppColors.red,
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            color: AppColors.greenSoft,
            borderColor: AppColors.green,
            child: Text(
              _notice!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (!_started)
          DuoButton(
            key: const ValueKey('first-session-record-start'),
            label: 'START RECORDING',
            icon: Icons.mic_rounded,
            height: 56,
            onPressed: _start,
          )
        else if (recording)
          DuoButton(
            key: const ValueKey('first-session-record-stop'),
            label: 'STOP',
            icon: Icons.stop_rounded,
            color: AppColors.red,
            height: 56,
            onPressed: _stop,
          )
        else ...[
          if (saved != null)
            DuoButton(
              key: const ValueKey('first-session-record-continue'),
              label: 'CONTINUE',
              height: 56,
              onPressed: () => widget.onSaved(saved),
            ),
          const SizedBox(height: 8),
          OutlineDuoButton(
            key: const ValueKey('first-session-record-skip'),
            label: 'SKIP RECORDING',
            onPressed: widget.onSkip,
          ),
        ],
      ],
    );
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _error = null;
      _notice = null;
      _remaining = 10;
    });
    await ref
        .read(recordingControllerProvider.notifier)
        .startTake(pieceId: 'ode-to-joy', phraseId: 'ode-to-joy-1');
    if (!mounted) return;
    final state = ref.read(recordingControllerProvider).asData?.value;
    if (state?.recording != true) {
      setState(() {
        _error =
            state?.failure?.message ??
            'The microphone did not start. You can skip this step.';
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        unawaited(_stop());
      }
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(recordingControllerProvider.notifier).stopTake();
    if (!mounted) return;
    setState(() => _saving = false);
  }
}
