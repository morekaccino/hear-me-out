import 'package:flutter/material.dart';

/// Gives any surface a pointer cursor and a hover state, so the app behaves
/// like a desktop app on desktop and a touch app on a phone.
class HoverRegion extends StatefulWidget {
  const HoverRegion({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.enabled = true,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor cursor;
  final bool enabled;

  @override
  State<HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<HoverRegion> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : MouseCursor.defer,
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: widget.builder(context, _hovered && widget.enabled),
    );
  }
}
