import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 110, this.mood = MascotMood.happy});

  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter(mood: mood)),
    );
  }
}

enum MascotMood { happy, cheer, thinking }

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.mood});

  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.58);
    final radius = size.width * 0.31;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.9),
        width: radius * 1.5,
        height: radius * 0.28,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    final body = Paint()..color = AppColors.green;
    canvas.drawCircle(center, radius, body);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = AppColors.greenDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.16
        ..strokeCap = StrokeCap.round,
    );

    final stemPaint = Paint()
      ..color = AppColors.greenDark
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round;
    final stemX = center.dx + radius * 0.55;
    canvas.drawLine(
      Offset(stemX, center.dy - radius * 0.1),
      Offset(stemX, center.dy - radius * 1.15),
      stemPaint,
    );
    final flag = Path()
      ..moveTo(stemX, center.dy - radius * 1.13)
      ..quadraticBezierTo(
        stemX + radius * 0.55,
        center.dy - radius * 1.3,
        stemX + radius * 0.7,
        center.dy - radius * 0.9,
      );
    canvas.drawPath(
      flag,
      Paint()
        ..color = AppColors.greenDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.14
        ..strokeCap = StrokeCap.round,
    );

    final eyeY = center.dy - radius * 0.16;
    for (final dx in [-radius * 0.36, radius * 0.28]) {
      canvas.drawCircle(
        Offset(center.dx + dx, eyeY),
        radius * 0.19,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(center.dx + dx + radius * 0.045, eyeY + radius * 0.02),
        radius * 0.075,
        Paint()..color = AppColors.ink,
      );
    }

    final smile = Path()
      ..moveTo(center.dx - radius * 0.2, center.dy + radius * 0.24);
    if (mood == MascotMood.thinking) {
      smile
        ..lineTo(center.dx + radius * 0.18, center.dy + radius * 0.24)
        ..lineTo(center.dx + radius * 0.18, center.dy + radius * 0.2);
    } else {
      smile.quadraticBezierTo(
        center.dx + radius * 0.02,
        center.dy + radius * (mood == MascotMood.cheer ? 0.55 : 0.42),
        center.dx + radius * 0.26,
        center.dy + radius * 0.22,
      );
    }
    canvas.drawPath(
      smile,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.075
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
