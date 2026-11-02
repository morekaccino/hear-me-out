import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Opens a lesson with a short upward slide.
///
/// Deliberately no opacity: fading a full-screen page forces `saveLayer` on
/// every frame and is the most expensive transition we can run on mobile
/// Safari. A translate is compositor-only.
Route<T> duoLessonRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: DuoMotion.base,
    reverseTransitionDuration: DuoMotion.fast,
    pageBuilder: (context, animation, secondaryAnimation) =>
        RepaintBoundary(child: builder(context)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: DuoMotion.enter,
        reverseCurve: DuoMotion.exit,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
