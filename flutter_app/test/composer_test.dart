import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/note_reading/objectives.dart';
import 'package:hear_me_out/content/packs.dart';
import 'package:hear_me_out/core/learning/composer.dart';
import 'package:hear_me_out/core/learning/content_pack.dart';
import 'package:hear_me_out/core/learning/objective.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/session_shape.dart';
import 'package:hear_me_out/core/learning/template.dart';
import 'package:hear_me_out/core/music/note.dart';

/// A template that pretends to teach something that is not a note.
class _RhythmTemplate implements ExerciseTemplate {
  const _RhythmTemplate(this.id, this.roles, this.usesMicrophone);

  @override
  final String id;

  @override
  final Set<SlotRole> roles;

  @override
  final bool usesMicrophone;

  @override
  SkillFamily get family => SkillFamily.rhythm;

  @override
  Set<Capability> get requires => const {};

  @override
  int get priority => 0;

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final teach = roles.contains(SlotRole.teach);
    return NotePrompt(
      objective: objective,
      templateId: id,
      task: teach ? NoteTask.teach : NoteTask.name,
      note: const Note('C', 4),
      choices: const [Note('C', 4), Note('D', 4)],
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

void main() {
  const pack = ContentPack(
    id: 'test.rhythm',
    templates: [
      _RhythmTemplate('rhythm.teach', {SlotRole.teach}, false),
      _RhythmTemplate('rhythm.ask', {
        SlotRole.guided,
        SlotRole.apply,
        SlotRole.review,
      }, false),
    ],
  );

  test('the composer works for a family it has never heard of', () {
    final prompts = const SessionComposer(pack).compose(
      shape: SessionShape.standard(total: 12, newObjectives: 2),
      newObjectives: const [
        ObjectiveRef('rhythm.quarter', family: SkillFamily.rhythm),
        ObjectiveRef('rhythm.eighth', family: SkillFamily.rhythm),
      ],
      reviewPool: const [
        ObjectiveRef('rhythm.rest', family: SkillFamily.rhythm),
      ],
      mode: AnswerMode.name,
      capabilities: const {},
      random: Random(1),
    );

    expect(prompts, hasLength(12));
    expect(
      prompts.map((prompt) => prompt.objective.family),
      everyElement(SkillFamily.rhythm),
    );
    expect(prompts.where((prompt) => prompt.isTeach), hasLength(2));
  });

  test('the composer is deterministic for a seeded source', () {
    List<String> build() => const SessionComposer(appContentPack)
        .compose(
          shape: SessionShape.standard(total: 12, newObjectives: 2),
          newObjectives: [
            noteObjective(Note.parse('E4')),
            noteObjective(Note.parse('F4')),
          ],
          reviewPool: [noteObjective(Note.parse('G4'))],
          mode: AnswerMode.mixed,
          capabilities: const {Capability.microphone},
          random: Random(7),
        )
        .map((prompt) => '${prompt.objective.id}:${prompt.templateId}')
        .toList();

    expect(build(), build());
  });

  test('a shape never asks for more review slots than it has', () {
    final shape = SessionShape.standard(total: 12, newObjectives: 2);
    expect(shape.total, 12);
    expect(shape.newObjectives, 2);
    expect(shape.reviewSlots, 4);
  });

  test('a session that cannot be filled fails loudly', () {
    expect(
      () => const SessionComposer(pack).compose(
        shape: SessionShape.standard(total: 12, newObjectives: 1),
        newObjectives: const [
          ObjectiveRef('rhythm.quarter', family: SkillFamily.rhythm),
        ],
        reviewPool: const [],
        mode: AnswerMode.name,
        capabilities: const {},
        random: Random(1),
      ),
      throwsStateError,
    );
  });

  test('core does not import content or features', () {
    final imports = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    final violations = <String>[];

    for (final entity in Directory('lib/core').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      final directory = entity.parent.path.replaceAll(r'\', '/');

      for (final match in imports.allMatches(source)) {
        final uri = match.group(1)!;
        final target = uri.startsWith('package:hear_me_out/')
            ? 'lib/${uri.substring('package:hear_me_out/'.length)}'
            : uri.startsWith('.')
            ? _resolve(directory, uri)
            : null;
        if (target == null) continue;
        if (target.startsWith('lib/content/') ||
            target.startsWith('lib/features/')) {
          violations.add('${entity.path} -> $uri');
        }
      }
    }

    expect(violations, isEmpty);
  });
}

/// Resolves a relative import against [directory], without package:path.
String _resolve(String directory, String relative) {
  final parts = directory.split('/');
  for (final segment in relative.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}
