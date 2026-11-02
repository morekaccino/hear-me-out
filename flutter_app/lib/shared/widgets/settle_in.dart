import 'package:flutter/material.dart';

import '../../shared/theme/motion.dart';

/// Slides new content up into place without an opacity layer.
///
/// A full fade of a large column forces `saveLayer` on every frame, which is
/// what makes lesson transitions stutter on mobile Safari. A translate is a
/// compositor-only change: cheap on every device.
class SettleIn extends StatelessWidget {
  const SettleIn({
    super.key,
    required this.slideKey,
    required this.child,
    this.offset = const Offset(0, 12),
  });

  /// Changing this value replays the animation.
  final Object slideKey;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(slideKey),
      tween: Tween(begin: 1, end: 0),
      duration: DuoMotion.base,
      curve: DuoMotion.enter,
      builder: (context, value, child) =>
          Transform.translate(offset: offset * value, child: child),
      // The boundary is what makes this cheap: without it every frame repaints
      // the staff and cards instead of moving a cached layer.
      child: RepaintBoundary(child: child),
    );
  }
}
