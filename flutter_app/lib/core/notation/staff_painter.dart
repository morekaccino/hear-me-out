import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../music/note.dart';
import 'staff_geometry.dart';

class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    required this.note,
    this.height = 230,
    this.staffColor = const Color(0xFFB8B8B8),
    this.noteColor = const Color(0xFF3C3C3C),
  });

  final Note note;
  final double height;
  final Color staffColor;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Treble staff, note ${note.display}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: StaffPainter(
            note: note,
            staffColor: staffColor,
            noteColor: noteColor,
          ),
        ),
      ),
    );
  }
}

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.note,
    required this.staffColor,
    required this.noteColor,
  });

  final Note note;
  final Color staffColor;
  final Color noteColor;

  static const _gClef = '\uE050';
  static const _sharp = '\uE262';
  static const _flat = '\uE260';

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = StaffGeometry(size: size);
    _paintStaff(canvas, geometry);
    _paintClef(canvas, geometry);
    _paintLedgerLines(canvas, geometry);
    _paintAccidental(canvas, geometry);
    _paintNote(canvas, geometry);
  }

  void _paintStaff(Canvas canvas, StaffGeometry geometry) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var line = 0; line < 5; line++) {
      final y = geometry.staffTop + geometry.lineGap * line;
      canvas.drawLine(Offset(0, y), Offset(geometry.size.width, y), paint);
    }
  }

  void _paintClef(Canvas canvas, StaffGeometry geometry) {
    final painter = TextPainter(
      text: TextSpan(
        text: _gClef,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: geometry.lineGap * 3.4,
          color: staffColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(canvas, Offset(10, geometry.gLine - baseline));
  }

  void _paintLedgerLines(Canvas canvas, StaffGeometry geometry) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final y in geometry.ledgerLineYs(note)) {
      canvas.drawLine(
        Offset(geometry.noteX - geometry.lineGap * 1.6, y),
        Offset(geometry.noteX + geometry.lineGap * 1.6, y),
        paint,
      );
    }
  }

  void _paintAccidental(Canvas canvas, StaffGeometry geometry) {
    final glyph = switch (note.accidental) {
      Accidental.natural => null,
      Accidental.sharp => _sharp,
      Accidental.flat => _flat,
    };
    if (glyph == null) return;

    final painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: geometry.lineGap * 2.7,
          color: noteColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(
      canvas,
      Offset(
        geometry.noteX - geometry.lineGap * 2.45,
        geometry.yFor(note) + geometry.lineGap * 0.55 - baseline,
      ),
    );
  }

  void _paintNote(Canvas canvas, StaffGeometry geometry) {
    final center = Offset(geometry.noteX, geometry.yFor(note));
    final headWidth = geometry.lineGap * 1.3;
    final headHeight = geometry.lineGap * 0.95;
    final notePaint = Paint()..color = noteColor;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: headWidth,
        height: headHeight,
      ),
      notePaint,
    );
    canvas.restore();

    final stemUp = note.diatonicIndex <= Note('B', 4).diatonicIndex;
    final stemX = center.dx + (stemUp ? headWidth * 0.46 : -headWidth * 0.46);
    final stemLength = geometry.lineGap * 3.4;
    final stemStart =
        center.dy + (stemUp ? -headHeight * 0.25 : headHeight * 0.25);
    final stemEnd = center.dy + (stemUp ? -stemLength : stemLength);
    canvas.drawLine(
      Offset(stemX, stemStart),
      Offset(stemX, stemEnd),
      Paint()
        ..color = noteColor
        ..strokeWidth = math.max(1.4, geometry.lineGap * 0.09)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) =>
      oldDelegate.note != note ||
      oldDelegate.staffColor != staffColor ||
      oldDelegate.noteColor != noteColor;
}
