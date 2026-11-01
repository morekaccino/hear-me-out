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
///
/// A chest gets its own slot on the path: if [chestAfterLessonId] names a
/// lesson in this unit, the nodes after it are pushed down by [chestSlot] so
/// the chest occupies the gap between its neighbors without overlapping them.
class PathLayout {
  PathLayout({
    required this.unit,
    required this.width,
    this.startOffset = 0,
    this.chestAfterLessonId,
  }) {
    final count = unit.lessons.length;
    final chestIndex = chestAfterLessonId == null
        ? -1
        : unit.lessons.indexWhere((lesson) => lesson.id == chestAfterLessonId);
    final amplitude = math.min(
      150.0,
      math.max(0, width / 2 - nodeSize / 2 - 12),
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
            topPadding +
                index * spacing +
                (chestIndex >= 0 && index > chestIndex ? chestSlot : 0),
          ),
        ),
    ];
  }

  static const double nodeSize = 84;
  static const double spacing = 116;
  static const double topPadding = 76;
  static const double bottomPadding = 32;
  static const double chestSlot = 120;
  static const double _period = 8;

  final UnitDefinition unit;
  final double width;
  final int startOffset;
  final String? chestAfterLessonId;
  late final List<PathNodeLayout> nodes;

  /// Center position of the chest that follows [chestAfterLessonId], or null
  /// when this unit has no chest slot or the slot borders no next node.
  Offset? get chestPosition {
    if (chestAfterLessonId == null) return null;
    final index = nodes.indexWhere(
      (node) => node.lesson.id == chestAfterLessonId,
    );
    if (index < 0 || index + 1 >= nodes.length) return null;
    final a = nodes[index].position;
    final b = nodes[index + 1].position;
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  double get height {
    if (nodes.isEmpty) return topPadding + bottomPadding;
    return nodes.last.position.dy + nodeSize / 2 + bottomPadding;
  }

  double get center => width / 2;
}
