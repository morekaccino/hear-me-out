import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/pieces/phrase_objectives.dart';
import '../../core/audio/phrase_prompt.dart';
import '../../core/audio/phrase_recorder.dart';
import '../../core/audio/phrase_verifier.dart';
import '../../core/audio/scored_take_gate.dart';
import '../../core/learning/attempt_outcome.dart';
import '../../core/music/phrase.dart';
import '../../shared/audio/audio_engine.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/feedback_panel.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/progress_widgets.dart';
import '../../shared/widgets/tappable.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import 'phrase_loop_flag.dart';

/// The only supported entry point for the phrase player.
///
/// Returns null while decision 0001's [phraseLoopEnabled] gate is closed. No
/// existing navigation calls this yet; T1.7 must pass before any caller wires
/// it into Learn, Today, or Practice.
Widget? phrasePlayerFor(Phrase phrase) =>
    phraseLoopEnabled ? PhrasePlayerScreen(phrase: phrase) : null;

/// Opens a registered phrase by its stable id.
///
/// This is the T2.11 integration point: the phrase comes from
/// [PhraseObjectiveRegistry], not from a second content registry. Unknown ids
/// return null, and the decision-0001 gate still returns null before T1.7.
Widget? phrasePlayerForPhraseId(
  String phraseId, {
  PhraseObjectiveRegistry? registry,
}) {
  if (!phraseLoopEnabled) return null;
  final record = (registry ?? phraseObjectiveRegistry).recordFor(phraseId);
  if (record == null) return null;
  return PhrasePlayerScreen(phrase: record.phrase, pieceId: record.piece.id);
}

/// Gated phrase practice: read a phrase, hear it, play it, and get one
/// correction.
///
/// This surface is unreachable from main navigation while [phraseLoopEnabled]
/// is false. It makes no validated-accuracy claim. A take is only persisted
/// when [ScoredTakeGate.allowsScoredTake] is true and the verifier says the
/// take is complete and determinate.
class PhrasePlayerScreen extends ConsumerStatefulWidget {
  const PhrasePlayerScreen({
    super.key,
    required this.phrase,
    this.pieceId,
    this.clockVerified = false,
    this.headphonesConfirmed = false,
    this.verifier = const PhraseVerifier(),
  });

  final Phrase phrase;

  /// Stable piece id when the phrase came from the content registry, so the
  /// attempt can record its repertoire skill. Null for a direct test build.
  final String? pieceId;

  /// True when a loopback calibration verified the device clock.
  final bool clockVerified;

  /// Initial value for the learner's wired-headphones confirmation.
  final bool headphonesConfirmed;

  final PhraseVerifier verifier;

  @override
  ConsumerState<PhrasePlayerScreen> createState() => _PhrasePlayerScreenState();
}

class _PhrasePlayerScreenState extends ConsumerState<PhrasePlayerScreen> {
  late final PhrasePlayPrompt _prompt;
  late final AudioEngine _audioEngine;

  PhraseRecorder? _recorder;
  PhraseVerification? _verification;
  Timer? _countInTimer;
  Timer? _autoStopTimer;
  String? _error;
  bool _starting = false;
  bool _recording = false;
  bool _analyzing = false;
  bool _saved = false;
  bool _headphonesConfirmed = false;
  int _countInRemaining = 0;
  int _generation = 0;

  ScoredTakeGate get _gate => ScoredTakeGate(
    headphonesConfirmed: _headphonesConfirmed,
    clockVerified: widget.clockVerified,
  );

  @override
  void initState() {
    super.initState();
    _prompt = PhrasePlayPrompt(phrase: widget.phrase);
    _audioEngine = ref.read(audioEngineProvider);
    _headphonesConfirmed = widget.headphonesConfirmed;
    _countInRemaining = _prompt.countInBeats;
  }

  @override
  void dispose() {
    _countInTimer?.cancel();
    _autoStopTimer?.cancel();
    _generation++;
    unawaited(_audioEngine.stop());
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) unawaited(recorder.dispose());
    super.dispose();
  }

  Future<void> _playPreview() async {
    if (_starting || _recording || _analyzing) return;
    await _audioEngine.play(_prompt.previewSpec);
  }

  Future<void> _startTake() async {
    if (_starting || _recording || _analyzing || _recorder != null) return;
    final generation = ++_generation;
    _countInTimer?.cancel();
    _autoStopTimer?.cancel();
    setState(() {
      _starting = true;
      _error = null;
      _verification = null;
      _saved = false;
      _countInRemaining = _prompt.countInBeats;
    });

    // A preview must never play while the recorder is listening.
    await _audioEngine.stop();
    final recorder = ref.read(phraseRecorderFactoryProvider)();
    try {
      final started = await recorder.start();
      if (!mounted || generation != _generation) {
        await recorder.dispose();
        return;
      }
      if (!started) {
        await recorder.dispose();
        setState(() {
          _starting = false;
          _error = 'Microphone unavailable. Check permissions, or use Play to hear the phrase.';
        });
        return;
      }
      _recorder = recorder;
      setState(() {
        _starting = false;
        _recording = true;
      });
      _armTimers();
    } catch (_) {
      await recorder.dispose();
      if (!mounted || generation != _generation) return;
      setState(() {
        _starting = false;
        _error = 'Could not start the microphone.';
      });
    }
  }

  void _armTimers() {
    final beat = Duration(microseconds: (60000000 / _prompt.bpm).round());
    if (_prompt.countInBeats > 0) {
      _countInTimer = Timer.periodic(beat, (timer) {
        if (!mounted || !_recording) {
          timer.cancel();
          return;
        }
        setState(() {
          _countInRemaining--;
          if (_countInRemaining <= 0) {
            _countInRemaining = 0;
            timer.cancel();
          }
        });
      });
    }
    final takeEnd = _prompt.recordingDurationSeconds + 1.0;
    _autoStopTimer = Timer(
      Duration(milliseconds: (takeEnd * 1000).round()),
      () {
        if (mounted && _recording) unawaited(_stopTake());
      },
    );
  }

  Future<void> _stopTake() async {
    final recorder = _recorder;
    if (recorder == null) return;
    _recorder = null;
    final generation = ++_generation;
    _countInTimer?.cancel();
    _countInTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    setState(() {
      _recording = false;
      _analyzing = true;
      _countInRemaining = 0;
    });

    PhraseTake take;
    try {
      take = await recorder.stop();
    } catch (_) {
      await recorder.dispose();
      if (!mounted || generation != _generation) return;
      setState(() {
        _analyzing = false;
        _error = 'Could not read the take. Try again.';
      });
      return;
    }
    await recorder.dispose();
    if (!mounted || generation != _generation) return;

    final verification = widget.verifier.verify(
      prompt: _prompt,
      samples: take.samples,
      sampleRate: take.sampleRate,
    );

    var saved = false;
    if (_gate.allowsScoredTake && verification.updatesProgress) {
      try {
        // The controller may still be loading if this preview screen is opened
        // before the app's first frame. Wait for it, then record the take.
        await ref.read(appControllerProvider.future);
        saved = await ref
            .read(appControllerProvider.notifier)
            .recordPhraseResult(
              phraseId: widget.phrase.id,
              result: verification.result,
              tempoBpm: _prompt.bpm,
              pieceId: widget.pieceId,
              contentVersion: widget.phrase.contentVersion,
            );
      } catch (_) {
        saved = false;
      }
    }

    if (!mounted || generation != _generation) return;
    setState(() {
      _verification = verification;
      _analyzing = false;
      _saved = saved;
    });
  }

  void _retry() {
    if (_starting || _recording || _analyzing) return;
    _countInTimer?.cancel();
    _autoStopTimer?.cancel();
    _generation++;
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) unawaited(recorder.dispose());
    setState(() {
      _verification = null;
      _error = null;
      _saved = false;
      _countInRemaining = _prompt.countInBeats;
    });
  }

  String get _recordLabel {
    if (_starting) return 'STARTING';
    if (_recording) return 'STOP';
    return 'RECORD';
  }

  String get _statusText {
    if (_starting) return 'Starting the microphone…';
    if (_analyzing) return 'Checking your take…';
    if (_recording && _countInRemaining > 0) {
      return 'Count-in: $_countInRemaining';
    }
    if (_recording) return 'Recording — play the phrase.';
    if (_verification != null) {
      return switch (_verification!.outcome) {
        AttemptOutcome.correct => 'Clean take.',
        AttemptOutcome.incorrect => 'Not quite.',
        AttemptOutcome.indeterminate => 'Let’s try that again.',
      };
    }
    return 'Listen once, then record a take.';
  }

  String? get _takeNote {
    final verification = _verification;
    if (verification == null) return null;
    if (!_gate.allowsScoredTake) {
      return 'Practice only — this take was not saved.';
    }
    if (!verification.updatesProgress) {
      return 'Not saved. Incomplete takes never update progress.';
    }
    if (_saved) return 'Saved to phrase progress.';
    return 'The take was scored but not saved.';
  }

  @override
  Widget build(BuildContext context) {
    final canRecord = !_starting && !_analyzing;
    final canPlay = !_starting && !_recording && !_analyzing;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageFrame(
          maxWidth: 720,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: DuoSpacing.sm),
                _phraseCard(),
                const SizedBox(height: DuoSpacing.md),
                _controls(canPlay: canPlay, canRecord: canRecord),
                const SizedBox(height: DuoSpacing.sm),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: DuoSpacing.sm),
                  _errorCard(_error!),
                ],
                const SizedBox(height: DuoSpacing.md),
                _gateCard(),
                if (_verification != null) ...[
                  const SizedBox(height: DuoSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _feedbackCard(_verification!),
                  ),
                ],
                const SizedBox(height: DuoSpacing.lg),
                Text(
                  'Preview build. Phrase scoring is not validated yet and stays '
                  'out of your course until the microphone gate passes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canPop)
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          )
        else
          const SizedBox(width: DuoSpacing.xxs),
        Expanded(
          child: Text(
            'Phrase practice',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue, width: 1.5),
          ),
          child: Text(
            'PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.blueDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _phraseCard() {
    final phrase = widget.phrase;
    final bars = phrase.bars;
    final lastBar = phrase.startBar + (bars > 0 ? bars - 1 : 0);
    final barLabel = lastBar > phrase.startBar
        ? 'Bars ${phrase.startBar}–$lastBar'
        : 'Bar ${phrase.startBar}';
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phrase.title ?? 'Phrase ${phrase.id}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: DuoSpacing.xs),
          Text(
            'Level ${phrase.difficulty} · ${_prompt.bpm} BPM · '
            '$bars ${bars == 1 ? 'bar' : 'bars'} · '
            '${phrase.timeSignature} · $barLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: DuoSpacing.md),
          _PhraseStrip(prompt: _prompt),
        ],
      ),
    );
  }

  Widget _controls({required bool canPlay, required bool canRecord}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: OutlineDuoButton(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            onPressed: canPlay ? () => unawaited(_playPreview()) : null,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(width: DuoSpacing.sm),
        Expanded(
          child: DuoButton(
            label: _recordLabel,
            icon: _recording ? Icons.stop_rounded : Icons.mic_rounded,
            color: _recording ? AppColors.red : AppColors.green,
            onPressed: canRecord
                ? () {
                    if (_recording) {
                      unawaited(_stopTake());
                    } else {
                      unawaited(_startTake());
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _gateCard() {
    final gate = _gate;
    final accent = gate.allowsScoredTake
        ? AppColors.blue
        : AppColors.borderStrong;
    return SectionCard(
      color: gate.allowsScoredTake ? AppColors.blueSoft : AppColors.surface,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                gate.allowsScoredTake
                    ? Icons.verified_rounded
                    : Icons.headphones_rounded,
                color: gate.allowsScoredTake
                    ? AppColors.blueDark
                    : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: DuoSpacing.xs),
              Expanded(
                child: Text(
                  gate.allowsScoredTake ? 'Scored take ready' : 'Scored take',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DuoSpacing.xxs),
          Text(
            gate.reason,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          DuoTappable(
            enabled: !_starting && !_recording && !_analyzing,
            onTap: () {
              setState(() => _headphonesConfirmed = !_headphonesConfirmed);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _headphonesConfirmed,
                    onChanged: _starting || _recording || _analyzing
                        ? null
                        : (value) {
                            setState(
                              () => _headphonesConfirmed = value ?? false,
                            );
                          },
                    activeColor: AppColors.green,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: DuoSpacing.xxs),
                  Expanded(
                    child: Text(
                      'Wired headphones connected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                widget.clockVerified
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: widget.clockVerified
                    ? AppColors.greenDark
                    : AppColors.textLight,
                size: 18,
              ),
              const SizedBox(width: DuoSpacing.xxs),
              Expanded(
                child: Text(
                  widget.clockVerified
                      ? 'Device clock verified'
                      : 'Device clock not verified',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return SectionCard(
      color: AppColors.redSoft,
      borderColor: AppColors.red,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.redDark),
          const SizedBox(width: DuoSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard(PhraseVerification verification) {
    final indeterminate = verification.outcome == AttemptOutcome.indeterminate;
    return FeedbackPanel(
      correct: verification.outcome == AttemptOutcome.correct,
      indeterminate: indeterminate,
      title: switch (verification.outcome) {
        AttemptOutcome.correct => 'Clean take',
        AttemptOutcome.incorrect => 'Not quite',
        AttemptOutcome.indeterminate => 'Let’s try that again',
      },
      subtitle: verification.correction,
      detail: _takeNote,
      continueLabel: 'TRY AGAIN',
      onContinue: _retry,
    );
  }
}

class _PhraseStrip extends StatelessWidget {
  const _PhraseStrip({required this.prompt});

  final PhrasePlayPrompt prompt;

  @override
  Widget build(BuildContext context) {
    if (prompt.targets.isEmpty) {
      return Text(
        'This phrase has no notes to play.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      );
    }

    final byBar = <int, List<PhrasePlayTarget>>{};
    for (final target in prompt.targets) {
      byBar
          .putIfAbsent(target.displayBar, () => <PhrasePlayTarget>[])
          .add(target);
    }
    final bars = byBar.keys.toList()..sort();

    return Wrap(
      spacing: DuoSpacing.xs,
      runSpacing: DuoSpacing.xs,
      children: [
        for (final bar in bars) _BarNotes(bar: bar, notes: byBar[bar]!),
      ],
    );
  }
}

class _BarNotes extends StatelessWidget {
  const _BarNotes({required this.bar, required this.notes});

  final int bar;
  final List<PhrasePlayTarget> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BAR $bar',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final note in notes) _NoteChip(note: note)],
          ),
        ],
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.note});

  final PhrasePlayTarget note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.writtenNote.display,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _beatLabel(note.beatInBar),
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

  String _beatLabel(double beat) {
    final whole = beat.floor();
    final fraction = beat - whole;
    if (fraction.abs() < 0.01) return '$whole';
    if ((fraction - 0.5).abs() < 0.01) return '$whole½';
    return beat.toStringAsFixed(1);
  }
}
