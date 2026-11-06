import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/technique/technique_content.dart';
import 'package:hear_me_out/core/learning/technique.dart';

void main() {
  const v1Stages = [1, 2, 3, 5, 9, 10, 11, 12];

  test('the V1 technique strand covers exactly the planned stages', () {
    expect(
      allTechniqueChecklists.map((checklist) => checklist.stage).toList(),
      v1Stages,
    );
    for (final stage in v1Stages) {
      expect(techniqueForStage(stage), isNotNull, reason: 'stage $stage');
    }
    for (final stage in [4, 6, 7, 8, 13]) {
      expect(techniqueForStage(stage), isNull, reason: 'stage $stage');
    }
  });

  test('every checklist has exactly three items and three rubric rows', () {
    for (final checklist in allTechniqueChecklists) {
      expect(checklist.items, hasLength(3), reason: 'stage ${checklist.stage}');
      expect(
        checklist.rubric,
        hasLength(3),
        reason: 'stage ${checklist.stage}',
      );
      expect(
        checklist.items.every((item) => item.trim().split(' ').length >= 5),
        isTrue,
        reason: 'stage ${checklist.stage} items must be specific',
      );
    }
  });

  test('stage areas follow the technique focus', () {
    expect(techniqueForStage(1)!.area, TechniqueArea.setup);
    expect(techniqueForStage(2)!.area, TechniqueArea.leftHand);
    expect(techniqueForStage(3)!.area, TechniqueArea.rightHand);
    expect(techniqueForStage(5)!.area, TechniqueArea.damping);
    expect(techniqueForStage(9)!.area, TechniqueArea.shifts);
    expect(techniqueForStage(10)!.area, TechniqueArea.slurs);
  });

  test('every drill lasts 60 seconds and names a tempo and repetitions', () {
    for (final checklist in allTechniqueChecklists) {
      final drill = checklist.drill;
      expect(drill.seconds, 60, reason: drill.id);
      expect(drill.tempoBpm, greaterThan(0), reason: drill.id);
      expect(drill.repetitions, greaterThan(0), reason: drill.id);
      expect(drill.instructions.trim(), isNotEmpty, reason: drill.id);
    }
  });

  test('every demo has three to five cues and no video asset yet', () {
    for (final checklist in allTechniqueChecklists) {
      final demo = checklist.demo;
      expect(demo.script.length, inInclusiveRange(3, 5), reason: demo.title);
      expect(demo.videoAsset, isNull, reason: demo.title);
      expect(demo.hasVideo, isFalse, reason: demo.title);
    }
  });

  test('the pain warning is explicit and makes no medical claim', () {
    for (final checklist in allTechniqueChecklists) {
      final warning = checklist.painWarning.toLowerCase();
      expect(warning, contains('pain'));
      expect(warning, contains('numbness'));
      expect(warning, contains('tingling'));
      expect(warning, contains('teacher'));
      expect(warning, contains('cannot assess'));
    }
    expect(techniquePainWarning.toLowerCase(), contains('stop'));
  });

  test('stage 11 stays generic and no checklist names an exam board', () {
    final stage11 = techniqueForStage(11)!;
    expect(stage11.title.toLowerCase(), contains('exam-style'));

    final corpus = allTechniqueChecklists
        .expand(
          (checklist) => [
            checklist.title,
            ...checklist.items,
            ...checklist.rubric,
            checklist.drill.title,
            checklist.drill.instructions,
            checklist.demo.title,
            ...checklist.demo.script,
          ],
        )
        .join(' ')
        .toLowerCase();
    for (final board in [
      'abrsm',
      'trinity',
      'royal conservatory',
      'rcm',
      'lcm',
      'rockschool',
      'rsl awards',
    ]) {
      expect(corpus, isNot(contains(board)), reason: board);
    }
  });

  test('checklists do not claim automated hand assessment', () {
    final corpus = allTechniqueChecklists
        .map((checklist) => '${checklist.title} ${checklist.painWarning}')
        .join(' ')
        .toLowerCase();
    expect(corpus, isNot(contains('automated hand assessment is available')));
    expect(corpus, contains('cannot assess your hands'));
  });
}
