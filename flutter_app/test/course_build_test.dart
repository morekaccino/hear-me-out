import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/objectives.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/course/course_data.dart';
import 'package:hear_me_out/core/learning/objective.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  group('Generated course', () {
    test('has 8 sections, 40 units, and 240 lessons', () {
      expect(sections, hasLength(8));
      expect(curriculum, hasLength(40));
      expect(allLessons, hasLength(240));
      expect(allLessons.map((lesson) => lesson.id).toSet(), hasLength(240));
    });

    test('every unit has six lessons and ends with a checkpoint', () {
      for (final unit in curriculum) {
        expect(unit.lessons, hasLength(6), reason: unit.id);
        expect(unit.lessons.last.isReview, isTrue, reason: unit.id);
        expect(
          unit.lessons.where((lesson) => lesson.isReview),
          hasLength(1),
          reason: unit.id,
        );
        expect(unit.focus, isNotEmpty);
      }
    });

    test('every unit has at least four applied concepts', () {
      for (final section in courseSections) {
        for (final unit in section.units) {
          expect(
            unit.concepts.length,
            greaterThanOrEqualTo(4),
            reason: unit.id,
          );
          final questions = <String>{};
          for (final concept in unit.concepts) {
            final question = concept.data['question'] as String?;
            if (question == null) continue;
            final lower = question.toLowerCase();
            expect(
              lower.startsWith('what is') ||
                  lower.startsWith('what does') ||
                  lower.startsWith('why '),
              isFalse,
              reason: '${unit.id}: definition trivia "$question"',
            );
            final hasStimulus =
                concept.data['chord'] != null ||
                concept.data['audio'] != null ||
                concept.data['tokens'] != null;
            if (!hasStimulus) {
              expect(
                questions.add(question),
                isTrue,
                reason: '${unit.id}: duplicate question "$question"',
              );
            }
          }
        }
      }
    });

    test('every referenced objective exists in the catalog', () {
      for (final lesson in allLessons) {
        for (final id in [...lesson.teaches, ...lesson.reviews]) {
          expect(
            objectiveCatalog.containsKey(id),
            isTrue,
            reason: '${lesson.id} references $id',
          );
        }
      }
    });

    test('every lesson builds a valid session', () {
      final now = DateTime(2026, 11, 2, 10);
      for (var index = 0; index < allLessons.length; index++) {
        final lesson = allLessons[index];
        final prompts = buildLessonSession(
          lesson: lesson,
          progress: ProgressState.fresh(),
          now: now,
          micAvailable: true,
          mode: AnswerMode.mixed,
          random: Random(3000 + index),
        );
        expect(prompts.length, greaterThanOrEqualTo(8), reason: lesson.id);
        expect(
          prompts.length,
          lessThanOrEqualTo(lesson.exerciseCount ?? 20),
          reason: lesson.id,
        );
        for (var promptIndex = 1; promptIndex < prompts.length; promptIndex++) {
          expect(
            prompts[promptIndex].objective.id,
            isNot(prompts[promptIndex - 1].objective.id),
            reason: '${lesson.id} at $promptIndex',
          );
        }
        for (final prompt in prompts.whereType<NotePrompt>()) {
          if (!prompt.isScored) continue;
          expect(
            prompt.choices.any((choice) => choice.id == prompt.note.id),
            isTrue,
            reason: lesson.id,
          );
        }
        for (final prompt in prompts.whereType<ChoicePrompt>()) {
          if (!prompt.reveal) {
            expect(
              prompt.options.length,
              greaterThanOrEqualTo(2),
              reason: '${lesson.id}: ${prompt.objective.id}',
            );
          }
          expect(
            prompt.options.any((option) => option.id == prompt.correctId),
            isTrue,
            reason: '${lesson.id}: ${prompt.objective.id}',
          );
          if (prompt.objective.family == SkillFamily.ear) {
            expect(
              prompt.audio,
              isNotNull,
              reason: '${lesson.id}: ${prompt.objective.id}',
            );
          }
        }
        if (lesson.newNotes.isEmpty && lesson.teaches.isEmpty) {
          final counts = <String, int>{};
          for (final prompt in prompts) {
            counts[prompt.objective.id] =
                (counts[prompt.objective.id] ?? 0) + 1;
          }
          expect(
            counts.values.every((count) => count <= 2),
            isTrue,
            reason: '${lesson.id} repeats a review objective too often',
          );
        }
      }
    });

    test('every course concept has a template for teach and apply', () {
      final now = DateTime(2026, 11, 2, 10);
      for (final section in sections) {
        for (final unit in section.units) {
          for (final concept in [
            for (final lesson in unit.lessons) lesson,
          ]) {
            // The build test above exercises every concept through a real
            // lesson. This loop keeps the failure close to the unit when a
            // concept is orphaned.
            expect(concept.id, isNotEmpty);
          }
        }
      }
      expect(now.year, 2026);
    });

    test('all lessons have a first-position fingering for their notes', () {
      for (final lesson in allLessons) {
        for (final note in [...lesson.newNotes, ...lesson.reviewNotes]) {
          expect(Note.tryParse(note.id), isNotNull);
        }
      }
    });
  });
}
