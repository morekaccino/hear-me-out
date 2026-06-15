import 'package:flutter/material.dart';

class StaffPainter extends CustomPainter {
  final String? noteValue;
  final bool showClef;
  final Color staffColor;
  final Color noteColor;

  StaffPainter({
    this.noteValue,
    this.showClef = true,
    this.staffColor = Colors.white24,
    this.noteColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStaffLines(canvas, size);
    if (showClef) _drawTrebleClef(canvas, size);
    if (noteValue != null) _drawNote(canvas, size, noteValue!);
  }

  void _drawStaffLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.5;

    final staffHeight = size.height * 0.5;
    final topY = (size.height - staffHeight) / 2;
    final lineSpacing = staffHeight / 4;

    for (int i = 0; i < 5; i++) {
      final y = topY + i * lineSpacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawTrebleClef(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\u{1D11E}', // 𝄞 — musical symbol G clef (Unicode)
        style: TextStyle(fontSize: size.height * 0.6, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(4, (size.height - textPainter.height) / 2),
    );
  }

  void _drawNote(Canvas canvas, Size size, String noteValue) {
    final staffHeight = size.height * 0.5;
    final topY = (size.height - staffHeight) / 2;
    final lineSpacing = staffHeight / 4;

    final noteY = _noteYPosition(noteValue, topY, lineSpacing);

    // Draw note head (filled oval)
    final notePaint = Paint()..color = noteColor;
    final noteX = size.width * 0.55;
    final noteRadius = lineSpacing * 0.55;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(noteX, noteY),
        width: noteRadius * 2 * 1.4, // Slightly wider than tall
        height: noteRadius * 2,
      ),
      notePaint,
    );

    // Draw ledger lines if needed
    _drawLedgerLines(canvas, noteY, topY, size.width, lineSpacing, noteX, noteRadius);
  }

  double _noteYPosition(String noteValue, double topY, double lineSpacing) {
    // Map note name to staff position.
    // In treble clef, bottom line = E4, top line = F5.
    // Positions are in half-steps from bottom line:
    // E4=0, F4=1, G4=2, A4=3, B4=4, C5=5, D5=6, E5=7, F5=8
    const noteSemitonesFromE4 = {
      'E': 0, 'F': 1, 'G': 2, 'A': 3, 'B': 4, 'C': 5, 'D': 6,
    };

    // Extract note letter and octave
    final noteLetter = noteValue.replaceAll(RegExp(r'[#b\d]'), '');
    final basePos = noteSemitonesFromE4[noteLetter] ?? 3.0;

    // Extract octave
    final octaveStr = noteValue.replaceAll(RegExp(r'[^0-9]'), '');
    final octave = int.tryParse(octaveStr) ?? 4;
    // Each octave shift = 7 staff positions (diatonic steps) / 2 = 3.5 line spaces
    final octaveShift = (octave - 4) * 3.5;

    // Handle sharps (same position as natural, accidental drawn separately)
    // For now: position doesn't change for accidentals

    // Bottom line = topY + 4 * lineSpacing
    // Position 0 (E4) = bottom line
    // Position goes UP (decreasing Y) by 0.5 lineSpace per semitone
    return topY + 4 * lineSpacing - (basePos + octaveShift) * lineSpacing * 0.5;
  }

  void _drawLedgerLines(
    Canvas canvas,
    double noteY,
    double topY,
    double width,
    double lineSpacing,
    double noteX,
    double noteRadius,
  ) {
    final paint = Paint()
      ..color = staffColor
      ..strokeWidth = 1.5;

    final staffBottom = topY + 4 * lineSpacing;

    // Ledger lines below staff (for notes below E4)
    if (noteY > staffBottom) {
      for (double y = staffBottom + lineSpacing; y <= noteY + lineSpacing * 0.5; y += lineSpacing) {
        canvas.drawLine(
          Offset(noteX - noteRadius * 2.5, y),
          Offset(noteX + noteRadius * 2.5, y),
          paint,
        );
      }
    }

    // Ledger lines above staff (for notes above F5)
    if (noteY < topY) {
      for (double y = topY - lineSpacing; y >= noteY - lineSpacing * 0.5; y -= lineSpacing) {
        canvas.drawLine(
          Offset(noteX - noteRadius * 2.5, y),
          Offset(noteX + noteRadius * 2.5, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.noteValue != noteValue || oldDelegate.showClef != showClef;
  }
}
