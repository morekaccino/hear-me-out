import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the app in a phone-like column on tablets and desktop browsers.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
            child: child,
          ),
        );
      },
    );
  }
}
