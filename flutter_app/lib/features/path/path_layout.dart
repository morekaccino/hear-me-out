import 'dart:math' as math;
import 'dart:ui';

import '../../core/music/curriculum.dart';

class PathNodeLayout {
  const PathNodeLayout({
    required this.lesson,
    required this.index,
    required this.position,
  });

  final LessonDefinition lesson;
  final int index;
  final Offset position;
}

/// Pure geometry for one unit's winding lesson path.
///
/// Units continue the same section-wide curve instead of restarting at an
/// arbitrary sine phase. `startOffset` is the number of lessons that precede
/// this unit inside its section.
class PathLayout {
  PathLayout({
    required this.unit,
    required this.width,
    this.startOffset = 0,
  }) {
    final count = unit.lessons.length;
    final amplitude = math.min(
      112.0,
      math.max(0, width / 2 - nodeSize / 2 - 8),
    );
    final center = width / 2;

    nodes = [
      for (var index = 0; index < count; index++)
        PathNodeLayout(
          lesson: unit.lessons[index],
          index: index,
          position: Offset(
            count == 1
                ? center
                : center +
                    amplitude *
                        math.sin(
                          2 * math.pi * (index + startOffset) / _period,
                        ),
            topPadding + index * spacing,
          ),
        ),
    ];
  }

  static const double nodeSize = 76;
  static const double spacing = 88;
  static const double topPadding = 64;
  static const double bottomPadding = 24;
  static const double _period = 8;

  final UnitDefinition unit;
  final double width;
  final int startOffset;
  late final List<PathNodeLayout> nodes;

  double get height {
    if (nodes.isEmpty) return topPadding + bottomPadding;
    return nodes.last.position.dy + nodeSize / 2 + bottomPadding;
  }

  double get center => width / 2;
}
