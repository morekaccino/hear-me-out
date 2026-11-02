import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

/// A treble staff the learner taps to place a note.
///
/// Uses its own geometry rather than [StaffGeometry] because a 72 px staff is
/// impossible to hit with a thumb. The staff is drawn larger so every line and
/// space gets a real tap target.
class StaffTapView extends StatefulWidget {
  const StaffTapView({
    super.key,
    required this.onPlace,
    this.selected,
    this.correct,
    this.enabled = true,
  });

  /// Called with the diatonic index of the tapped line or space.
  final ValueChanged<int> onPlace;

  /// The step the learner tapped, drawn once they commit.
  final int? selected;

  /// The right answer, revealed after the committed tap.
  final int? correct;

  final bool enabled;

  /// C4 (ledger below) through F5 (top line).
  static const int firstStep = 28;
  static const int lastStep = 38;

  static const double height = 280;
  static const double _lineGap = 34;
  static const double _staffTop = 54;
  static const double _bottomLine = _staffTop + _lineGap * 4; // E4
  static const int _bottomLineIndex = 30;

  /// Half of one line-to-space step, and the tap target height.
  static const double stepSize = _lineGap / 2;

  static double yFor(int diatonicIndex) =>
      _bottomLine - (diatonicIndex - _bottomLineIndex) * (_lineGap / 2);

  /// Vertical position of staff line 0 (top) through 4 (bottom).
  static double lineY(int line) => _staffTop + _lineGap * line;

  static double get ledgerY => _staffTop + _lineGap * 5;

  @override
  State<StaffTapView> createState() => _StaffTapViewState();
}

class _StaffTapViewState extends State<StaffTapView> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Treble staff. Tap a line or space to place the note.',
      child: SizedBox(
        height: StaffTapView.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StaffTapPainter(
                  lineGap: StaffTapView._lineGap,
                  staffTop: StaffTapView._staffTop,
                  selected: widget.selected,
                  correct: widget.correct,
                  hovered: widget.enabled ? _hovered : null,
                ),
              ),
            ),
            for (
              var index = StaffTapView.firstStep;
              index <= StaffTapView.lastStep;
              index++
            )
              Positioned(
                left: 0,
                right: 0,
                top: StaffTapView.yFor(index) - StaffTapView.stepSize / 2,
                height: StaffTapView.stepSize,
                child: MouseRegion(
                  cursor: widget.enabled
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  onEnter: (_) => setState(() => _hovered = index),
                  onExit: (_) => setState(() => _hovered = null),
                  child: GestureDetector(
                    key: ValueKey('staff-step-$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enabled
                        ? () => widget.onPlace(index)
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffTapPainter extends CustomPainter {
  const _StaffTapPainter({
    required this.lineGap,
    required this.staffTop,
    required this.selected,
    required this.correct,
    required this.hovered,
  });

  final double lineGap;
  final double staffTop;
  final int? selected;
  final int? correct;
  final int? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final hover = hovered;
    if (hover != null) {
      final y = StaffTapView.yFor(hover);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y - lineGap / 4, size.width, lineGap / 2),
          const Radius.circular(8),
        ),
        Paint()..color = AppColors.blueSoft.withValues(alpha: 0.7),
      );
    }

    final line = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1.4;
    for (var index = 0; index < 5; index++) {
      final y = StaffTapView.lineY(index);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // A ledger line under C4.
    final ledgerY = StaffTapView.ledgerY;
    canvas.drawLine(
      Offset(size.width * 0.36, ledgerY),
      Offset(size.width * 0.68, ledgerY),
      line,
    );

    _paintClef(canvas);

    final answer = correct;
    if (answer != null) {
      _paintHead(canvas, size, answer, AppColors.green, AppColors.greenDark);
      if (answer == 28) _paintLedger(canvas, size, 28);
    }

    final tap = selected;
    if (tap != null && tap != answer) {
      _paintCross(canvas, size, tap);
    }
  }

  void _paintLedger(Canvas canvas, Size size, int step) {
    final painter = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1.4;
    final y = StaffTapView.yFor(step);
    canvas.drawLine(
      Offset(size.width * 0.36, y),
      Offset(size.width * 0.68, y),
      painter,
    );
  }

  void _paintHead(
    Canvas canvas,
    Size size,
    int step,
    Color fill,
    Color stroke,
  ) {
    final center = Offset(size.width * 0.5, StaffTapView.yFor(step));
    final head = Rect.fromCenter(
      center: center,
      width: lineGap * 1.35,
      height: lineGap * 1.0,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: head.width,
        height: head.height,
      ),
      Paint()..color = fill,
    );
    canvas.restore();
    canvas.drawOval(
      head,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCross(Canvas canvas, Size size, int step) {
    final center = Offset(size.width * 0.5, StaffTapView.yFor(step));
    final paint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-8, -8),
      center.translate(8, 8),
      paint,
    );
    canvas.drawLine(
      center.translate(8, -8),
      center.translate(-8, 8),
      paint,
    );
  }

  void _paintClef(Canvas canvas) {
    final painter = TextPainter(
      text: TextSpan(
        text: '\uE050',
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: lineGap * 3.4,
          color: AppColors.textLight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final gLine = StaffTapView.lineY(3);
    painter.paint(canvas, Offset(10, gLine - baseline));
  }

  @override
  bool shouldRepaint(_StaffTapPainter oldDelegate) =>
      oldDelegate.lineGap != lineGap ||
      oldDelegate.staffTop != staffTop ||
      oldDelegate.selected != selected ||
      oldDelegate.correct != correct ||
      oldDelegate.hovered != hovered;
}
