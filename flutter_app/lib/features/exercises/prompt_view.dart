import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/learning/prompt.dart';
import '../../core/learning/verifier.dart';
import '../../core/music/chords.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/audio_button.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/feedback_panel.dart';
import '../../shared/widgets/tappable.dart';
import 'fret_tap_view.dart';
import 'staff_tap_view.dart';

/// Renders any non-note prompt and reports one [Answer].
class PromptView extends StatelessWidget {
  const PromptView({
    super.key,
    required this.prompt,
    required this.onAnswer,
  });

  final Prompt prompt;
  final ValueChanged<Answer> onAnswer;

  @override
  Widget build(BuildContext context) {
    return switch (prompt) {
      final StaffTapPrompt placement => _StaffPlacement(prompt: placement, onAnswer: onAnswer),
      final FretTapPrompt finding => _FretFinding(prompt: finding, onAnswer: onAnswer),
      final ChoicePrompt choice => _Choice(choice: choice, onAnswer: onAnswer),
      final OrderPrompt order => _Order(prompt: order, onAnswer: onAnswer),
      final RhythmPrompt rhythm => _Rhythm(prompt: rhythm, onAnswer: onAnswer),
      NotePrompt() => const SizedBox.shrink(),
    };
  }
}

String promptTitle(Prompt prompt) {
  return switch (prompt) {
    NotePrompt() => 'What note is this?',
    StaffTapPrompt() => 'Place the note',
    FretTapPrompt() => 'Find it on the neck',
    ChoicePrompt( :final audio) =>
      audio != null ? 'Listen and choose' : 'Choose the answer',
    OrderPrompt() => 'Build the answer',
    RhythmPrompt() => 'Tap the rhythm',
  };
}

class _StaffPlacement extends StatefulWidget {
  const _StaffPlacement({required this.prompt, required this.onAnswer});

  final StaffTapPrompt prompt;
  final ValueChanged<Answer> onAnswer;

  @override
  State<_StaffPlacement> createState() => _StaffPlacementState();
}

class _StaffPlacementState extends State<_StaffPlacement> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            children: [
              Text(
                widget.prompt.note.display,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the line or space where it belongs.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StaffTapView(
          enabled: !_answered,
          selected: _selected,
          correct: _answered ? widget.prompt.note.diatonicIndex : null,
          onPlace: (index) {
            if (_answered) return;
            setState(() {
              _selected = index;
              _answered = true;
            });
            widget.onAnswer(StaffAnswer(index));
          },
        ),
      ],
    );
  }
}

class _FretFinding extends StatefulWidget {
  const _FretFinding({required this.prompt, required this.onAnswer});

  final FretTapPrompt prompt;
  final ValueChanged<Answer> onAnswer;

  @override
  State<_FretFinding> createState() => _FretFindingState();
}

class _FretFindingState extends State<_FretFinding> {
  ({int string, int fret})? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final positions = positionsFor(prompt.note, prompt.maxFret);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            children: [
              Text(
                prompt.note.display,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the string and fret that play it.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FretTapView(
          maxFret: prompt.maxFret,
          positions: _answered ? positions : const [],
          selected: _selected,
          enabled: !_answered,
          onTapFret: (string, fret) {
            if (_answered) return;
            setState(() {
              _selected = (string: string, fret: fret);
              _answered = true;
            });
            widget.onAnswer(FretAnswer(string: string, fret: fret));
          },
        ),
      ],
    );
  }
}

class _Choice extends StatefulWidget {
  const _Choice({required this.choice, required this.onAnswer});

  final ChoicePrompt choice;
  final ValueChanged<Answer> onAnswer;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choice.chord != null) ...[
          Center(child: ChordDiagram(chord: choice.chord!)),
          const SizedBox(height: 12),
        ],
        if (choice.audio != null) ...[
          AudioPromptButton(spec: choice.audio!),
          const SizedBox(height: 12),
        ],
        Text(
          choice.question,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        if (choice.hint != null && _selected != null) ...[
          const SizedBox(height: 6),
          Text(
            choice.hint!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (var index = 0; index < choice.options.length; index += 1) ...[
          AnswerOption(
            label: choice.options[index].label,
            state: _stateFor(choice.options[index]),
            onTap: _selected != null || choice.reveal
                ? null
                : () {
                    setState(() => _selected = choice.options[index].id);
                    widget.onAnswer(ChoiceAnswer(choice.options[index].id));
                  },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  AnswerOptionState _stateFor(ChoiceOption option) {
    if (widget.choice.reveal) {
      return option.id == widget.choice.correctId
          ? AnswerOptionState.correct
          : AnswerOptionState.dimmed;
    }
    if (_selected == null) return AnswerOptionState.idle;
    if (option.id == widget.choice.correctId) {
      return AnswerOptionState.correct;
    }
    if (option.id == _selected) return AnswerOptionState.wrong;
    return AnswerOptionState.dimmed;
  }
}

class _Order extends StatefulWidget {
  const _Order({required this.prompt, required this.onAnswer});

  final OrderPrompt prompt;
  final ValueChanged<Answer> onAnswer;

  @override
  State<_Order> createState() => _OrderState();
}

class _OrderState extends State<_Order> {
  final List<String> _selected = [];
  bool _answered = false;

  void _add(String token) {
    if (_answered) return;
    setState(() => _selected.add(token));
  }

  void _removeAt(int index) {
    if (_answered) return;
    setState(() => _selected.removeAt(index));
  }

  void _check() {
    if (_answered) return;
    if (_selected.length != widget.prompt.correctOrder.length) return;
    setState(() => _answered = true);
    widget.onAnswer(OrderAnswer([..._selected]));
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    if (prompt.reveal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            prompt.question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in prompt.correctOrder)
                _OrderToken(label: value, correct: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is the order to remember.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt.question,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: _selected.isEmpty
              ? Text(
                  'Tap the tokens below in order.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _selected.length; index++)
                      _OrderToken(
                        key: ValueKey('order-selected-$index'),
                        label: _selected[index],
                        selected: true,
                        onTap: () => _removeAt(index),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in prompt.tokens)
              _OrderToken(
                key: ValueKey('order-token-$token'),
                label: token,
                onTap: _selected.length < prompt.correctOrder.length
                    ? () => _add(token)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(_selected.clear),
              child: const Text('CLEAR'),
            ),
            const Spacer(),
            SizedBox(
              width: 150,
              child: DuoButton(
                label: 'CHECK',
                height: 48,
                onPressed:
                    _selected.length == prompt.correctOrder.length
                    ? _check
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderToken extends StatelessWidget {
  const _OrderToken({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.correct = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final background = correct
        ? AppColors.greenSoft
        : selected
        ? AppColors.blueSoft
        : AppColors.background;
    final border = correct
        ? AppColors.green
        : selected
        ? AppColors.blue
        : AppColors.borderStrong;
    return DuoTappable(
      onTap: onTap ?? () {},
      enabled: onTap != null,
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: correct
                ? AppColors.greenDark
                : selected
                ? AppColors.blueDark
                : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class ChordDiagram extends StatelessWidget {
  const ChordDiagram({super.key, required this.chord});

  final ChordShape chord;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 190,
      child: CustomPaint(painter: _ChordPainter(chord)),
    );
  }
}

class _ChordPainter extends CustomPainter {
  const _ChordPainter(this.chord);

  final ChordShape chord;

  @override
  void paint(Canvas canvas, Size size) {
    const strings = 6;
    const frets = 5;
    final left = 16.0;
    final top = 28.0;
    final width = size.width - 32;
    final height = size.height - 42;
    final gapX = width / (strings - 1);
    final gapY = height / frets;

    _text(canvas, chord.name, Offset(left - 4, 0), AppColors.textMuted, 13);

    final board = Rect.fromLTWH(left - 8, top - 4, width + 16, height + 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(8)),
      Paint()..color = AppColors.fretboard,
    );

    for (var string = 0; string < strings; string++) {
      final x = left + gapX * string;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        Paint()
          ..color = AppColors.textMuted
          ..strokeWidth = 2.6 - string * 0.3
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var fret = 0; fret <= frets; fret++) {
      final y = top + gapY * fret;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + width, y),
        Paint()
          ..color = fret == 0 ? AppColors.textMuted : AppColors.fretboardLine
          ..strokeWidth = fret == 0 ? 4 : 1.6,
      );
    }

    for (var string = 0; string < strings; string++) {
      final fret = chord.frets[string];
      final x = left + gapX * string;
      if (fret == null) {
        _drawMuted(canvas, x, top);
      } else if (fret == 0) {
        _drawOpen(canvas, x, top);
      } else {
        final y = top + gapY * (fret - 0.5);
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = AppColors.green);
        canvas.drawCircle(
          Offset(x, y),
          8,
          Paint()
            ..color = AppColors.greenDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
  }

  void _drawOpen(Canvas canvas, double x, double top) {
    canvas.drawCircle(
      Offset(x, top - 12),
      4.5,
      Paint()
        ..color = AppColors.textMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawMuted(Canvas canvas, double x, double top) {
    final paint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 4, top - 16), Offset(x + 4, top - 8), paint);
    canvas.drawLine(Offset(x + 4, top - 16), Offset(x - 4, top - 8), paint);
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Nunito',
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChordPainter oldDelegate) =>
      oldDelegate.chord.id != chord.id;
}

class _Rhythm extends StatefulWidget {
  const _Rhythm({required this.prompt, required this.onAnswer});

  final RhythmPrompt prompt;
  final ValueChanged<Answer> onAnswer;

  @override
  State<_Rhythm> createState() => _RhythmState();
}

class _RhythmState extends State<_Rhythm> {
  static const int _bpm = 80;

  Timer? _timer;
  DateTime? _startedAt;
  final List<double> _taps = [];
  int _beat = 0;
  bool _running = false;
  bool _done = false;

  double get _beatMs => 60000 / _bpm;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _done = false;
      _taps.clear();
      _beat = 0;
      _startedAt = DateTime.now();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _tick() {
    final started = _startedAt;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started).inMilliseconds / _beatMs;
    final countIn = widget.prompt.pattern.beats.toDouble();
    final end = countIn + widget.prompt.pattern.beats + 1;

    if (elapsed >= end) {
      _finish();
      return;
    }
    final beat = elapsed < countIn ? elapsed.floor() : (elapsed - countIn).floor();
    if (beat != _beat) {
      setState(() => _beat = beat);
    }
  }

  void _tap() {
    if (!_running || _done) return;
    final started = _startedAt;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started).inMilliseconds / _beatMs;
    final countIn = widget.prompt.pattern.beats.toDouble();
    if (elapsed < countIn - 0.25 || elapsed > countIn + widget.prompt.pattern.beats + 0.75) {
      return;
    }
    setState(() {
      _taps.add((elapsed - countIn).clamp(0.0, 99.0));
    });
  }

  void _finish() {
    _timer?.cancel();
    if (_done) return;
    setState(() {
      _running = false;
      _done = true;
    });
    widget.onAnswer(RhythmAnswer([..._taps]));
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.prompt.pattern;
    final counting = _running && _beat < pattern.beats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.prompt.question,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '${pattern.beats} beats at $_bpm BPM',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < pattern.beats; index++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _running && _beat % pattern.beats == index
                      ? AppColors.green
                      : AppColors.border,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        DuoTappable(
          onTap: _tap,
          pressedScale: 0.99,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderStrong, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              counting
                  ? 'Count in…'
                  : _running
                  ? 'TAP'
                  : _done
                  ? '${_taps.length} taps'
                  : 'Ready?',
              style: TextStyle(
                fontSize: counting ? 20 : 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DuoButton(
          label: _running ? 'STOP' : 'START',
          onPressed: _running ? _finish : _start,
          color: AppColors.blue,
        ),
      ],
    );
  }
}
