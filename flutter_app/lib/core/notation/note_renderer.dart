import 'package:flutter/material.dart';
import 'staff_painter.dart';

class NoteRenderer extends StatelessWidget {
  final String? noteValue;
  final double height;

  const NoteRenderer({
    super.key,
    required this.noteValue,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: StaffPainter(
          noteValue: noteValue,
          showClef: true,
          staffColor: Colors.white.withValues(alpha: 0.15),
          noteColor: Colors.white,
        ),
        size: Size.infinite,
      ),
    );
  }
}
