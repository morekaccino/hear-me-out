import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/features/path/path_layout.dart';

void main() {
  test('path nodes stay inside the available width', () {
    for (final unit in curriculum) {
      final layout = PathLayout(unit: unit, width: 390);
      for (final node in layout.nodes) {
        expect(node.position.dx, greaterThan(0), reason: unit.id);
        expect(node.position.dx, lessThan(390), reason: unit.id);
      }
    }
  });

  test('units continue one section-wide curve', () {
    final first = PathLayout(unit: curriculum[0], width: 390);
    final second = PathLayout(
      unit: curriculum[1],
      width: 390,
      startOffset: curriculum[0].lessons.length,
    );

    expect(first.nodes.first.position.dx, closeTo(195, 0.001));
    expect(first.nodes.last.position.dx, closeTo(195, 0.001));
    expect(first.nodes[1].position.dx, greaterThan(195));

    // The second unit picks up the section curve instead of restarting
    // centered, so it should swing to the other side of the path.
    expect(second.nodes.first.position.dx, lessThan(195));
    expect(second.nodes.first.position.dx, isNot(closeTo(195, 0.001)));
  });

  test('path spacing is consistent and vertical', () {
    final layout = PathLayout(unit: curriculum.first, width: 390);
    for (var index = 1; index < layout.nodes.length; index++) {
      expect(
        layout.nodes[index].position.dy - layout.nodes[index - 1].position.dy,
        closeTo(PathLayout.spacing, 0.001),
      );
    }
    expect(layout.height, greaterThan(layout.nodes.last.position.dy));
  });

  test('the first unit starts and ends centered', () {
    final layout = PathLayout(unit: curriculum.first, width: 390);
    expect(layout.nodes.first.position.dx, closeTo(195, 0.001));
    expect(layout.nodes.last.position.dx, closeTo(195, 0.001));
  });

  test('a unit can start mid-curve when offset into the section', () {
    final layout = PathLayout(
      unit: curriculum.first,
      width: 390,
      startOffset: 1,
    );
    expect(layout.nodes.first.position.dx, isNot(closeTo(195, 0.001)));
  });

  test('node positions are independent of paint-time state', () {
    final first = PathLayout(unit: curriculum.first, width: 390);
    final second = PathLayout(unit: curriculum.first, width: 390);
    expect(
      first.nodes.map((node) => node.position).toList(),
      second.nodes.map((node) => node.position).toList(),
    );
    expect(first.nodes.first.position, isA<Offset>());
  });

  test('chest slots clear neighboring lesson nodes and stay on screen', () {
    const chestRadius = 29.0;
    final required = PathLayout.nodeSize / 2 + chestRadius + 6;

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

      // Nodes after the chest slide down by the chest slot height.
      final chestIndex = layout.nodes.indexWhere(
        (node) => node.lesson.id == chest?.afterLessonId,
      );
      expect(
        layout.nodes[chestIndex + 1].position.dy -
            layout.nodes[chestIndex].position.dy,
        closeTo(PathLayout.spacing + PathLayout.chestSlot, 0.001),
        reason: unit.id,
      );
    }
  });
}
