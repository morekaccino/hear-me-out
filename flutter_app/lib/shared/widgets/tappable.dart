import 'package:flutter/material.dart';

import '../theme/motion.dart';
import 'hover_region.dart';

/// A tap target that behaves correctly for both a finger and a mouse:
/// pointer cursor, press scale, and optional hover scale.
class DuoTappable extends StatefulWidget {
  const DuoTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.hoverScale = 1,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final double hoverScale;
  final bool enabled;

  @override
  State<DuoTappable> createState() => _DuoTappableState();
}

class _DuoTappableState extends State<DuoTappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return HoverRegion(
      enabled: widget.enabled,
      builder: (context, hovered) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed
              ? widget.pressedScale
              : hovered
              ? widget.hoverScale
              : 1,
          duration: DuoMotion.fast,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
