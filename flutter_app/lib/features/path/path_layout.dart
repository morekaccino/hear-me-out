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

  /// Center of the node in the unit's coordinate space.
  final Offset position;
}

/// Pure geometry for one unit's lesson path.
///
/// Mirrors Duolingo's path: a tight, repeating zigzag that restarts at the
/// center for every unit, with no continuous line between units. The path is
/// laid out from the top of the unit (below its banner) and each chest takes
/// its own vertical slot.
class PathLayout {
  PathLayout({
    required this.unit,
    required this.width,
    this.startOffset = 0,
    this.chestAfterLessonId,
    this.currentLessonId,
  }) {
    final count = unit.lessons.length;
    final chestIndex = chestAfterLessonId == null
        ? -1
        : unit.lessons.indexWhere((lesson) => lesson.id == chestAfterLessonId);
    final currentIndex = currentLessonId == null
        ? -1
        : unit.lessons.indexWhere((lesson) => lesson.id == currentLessonId);
    final center = width / 2;
    final amplitude = math.min(80.0, width / 2 - nodeSize / 2 - 16);

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
                            2 * math.pi * (startOffset + index) / _period,
                          ),
            topPadding +
                nodeHeight / 2 +
                index * spacing +
                (chestIndex >= 0 && index > chestIndex ? chestSlot : 0) +
                (currentIndex >= 0 && index >= currentIndex ? startSlot : 0),
          ),
        ),
    ];
  }

  /// Node width. The face is an ellipse: [nodeSize] wide and [faceHeight] tall.
  /// The face sits on an 8 px extruded base, so the hit area is [nodeHeight].
  static const double nodeSize = 80;
  static const double faceHeight = 72;
  static const double nodeHeight = 84;

  /// Duolingo's 4 px rhythm: 84 px node plus a 20 px gap.
  static const double spacing = 104;
  static const double topPadding = 72;
  static const double bottomPadding = 32;
  static const double chestSlot = 96;
  static const double chestSize = 72;

  /// Extra room above the active lesson for the START bubble.
  static const double startSlot = 48;

  static const double _period = 6;

  final UnitDefinition unit;
  final double width;

  /// Lessons that come before this unit in the course. The zigzag phase
  /// continues across unit banners instead of resetting.
  final int startOffset;
  final String? chestAfterLessonId;
  final String? currentLessonId;
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
    return nodes.last.position.dy + nodeHeight / 2 + bottomPadding;
  }

  double get center => width / 2;
}
