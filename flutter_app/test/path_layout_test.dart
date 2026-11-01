import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/features/path/path_layout.dart';

void main() {
  test('path nodes stay inside the available width', () {
    for (final unit in curriculum) {
      final layout = PathLayout(unit: unit, width: 390);
      for (final node in layout.nodes) {
        expect(
          node.position.dx - PathLayout.nodeSize / 2,
          greaterThanOrEqualTo(0),
          reason: unit.id,
        );
        expect(
          node.position.dx + PathLayout.nodeSize / 2,
          lessThanOrEqualTo(390),
          reason: unit.id,
        );
      }
    }
  });

  test('the zigzag continues across unit boundaries', () {
    final first = PathLayout(unit: curriculum[0], width: 390);
    final fifth = PathLayout(
      unit: curriculum[4],
      width: 390,
      startOffset: curriculum
          .take(4)
          .fold(0, (sum, unit) => sum + unit.lessons.length),
    );
    final second = PathLayout(
      unit: curriculum[1],
      width: 390,
      startOffset: curriculum[0].lessons.length,
    );

    expect(first.nodes.first.position.dx, closeTo(195, 0.001));
    expect(first.nodes[1].position.dx, greaterThan(195));
    expect(first.nodes[2].position.dx, greaterThan(195));
    expect(fifth.nodes.first.position.dx, lessThan(195));
    // The next unit keeps the wave phase instead of snapping to center.
    expect(second.nodes.first.position.dx, lessThan(195));
    expect(second.nodes.first.position.dx, isNot(closeTo(195, 0.001)));
  });

  test('path spacing is consistent except for the chest slot', () {
    for (final unit in curriculum) {
      final chest = chestForUnit(unit.id);
      final layout = PathLayout(
        unit: unit,
        width: 390,
        chestAfterLessonId: chest?.afterLessonId,
      );
      final chestIndex = layout.nodes.indexWhere(
        (node) => node.lesson.id == chest?.afterLessonId,
      );
      for (var index = 1; index < layout.nodes.length; index++) {
        final gap =
            layout.nodes[index].position.dy -
            layout.nodes[index - 1].position.dy;
        final expected = index - 1 == chestIndex
            ? PathLayout.spacing + PathLayout.chestSlot
            : PathLayout.spacing;
        expect(gap, closeTo(expected, 0.001), reason: unit.id);
      }
      expect(layout.height, greaterThan(layout.nodes.last.position.dy));
    }
  });

  test('the active lesson reserves room for the START bubble', () {
    final unit = curriculum.first;
    final current = unit.lessons[1];
    final layout = PathLayout(
      unit: unit,
      width: 390,
      currentLessonId: current.id,
    );
    expect(
      layout.nodes[1].position.dy - layout.nodes[0].position.dy,
      closeTo(PathLayout.spacing + PathLayout.startSlot, 0.001),
    );
    expect(
      layout.nodes[2].position.dy - layout.nodes[1].position.dy,
      closeTo(PathLayout.spacing, 0.001),
    );
  });

  test('node positions are independent of paint-time state', () {
    final first = PathLayout(unit: curriculum.first, width: 390);
    final second = PathLayout(unit: curriculum.first, width: 390);
    expect(
      first.nodes.map((node) => node.position).toList(),
      second.nodes.map((node) => node.position).toList(),
    );
  });

  test('chest slots clear neighboring lesson nodes and stay on screen', () {
    const chestRadius = PathLayout.chestSize / 2;
    final required = PathLayout.nodeSize / 2 + chestRadius + 4;

    for (final unit in curriculum) {
      final chest = chestForUnit(unit.id);
      final layout = PathLayout(
        unit: unit,
        width: 390,
        chestAfterLessonId: chest?.afterLessonId,
      );
      final position = layout.chestPosition;
      expect(position, isNotNull, reason: unit.id);
      final center = position!;
      for (final node in layout.nodes) {
        expect(
          (node.position - center).distance,
          greaterThanOrEqualTo(required),
          reason: '${unit.id}: ${node.lesson.id} overlaps the chest',
        );
      }
      expect(position.dx - chestRadius, greaterThanOrEqualTo(0));
      expect(position.dx + chestRadius, lessThanOrEqualTo(390));
    }
  });
}
