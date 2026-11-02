import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Opens a lesson with a fade and a small scale, so it feels like the lesson
/// grows out of the path rather than sliding in from the edge.
///
/// Closing is faster than opening: leaving should feel light, arriving should
/// feel deliberate.
Route<T> duoLessonRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: DuoMotion.slow,
    reverseTransitionDuration: DuoMotion.base,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: DuoMotion.enter,
        reverseCurve: DuoMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
