import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/chord.dart';
import 'package:hear_me_out/core/music/interval.dart';
import 'package:hear_me_out/core/music/key.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/progression.dart';
import 'package:hear_me_out/core/music/scale.dart';

void main() {
  group('Key signatures', () {
    test('major key accidentals', () {
      expect(KeySignature.major('C').accidentals, 0);
      expect(KeySignature.major('G').accidentals, 1);
      expect(KeySignature.major('D').accidentals, 2);
      expect(KeySignature.major('F').accidentals, -1);
      expect(KeySignature.major('Bb').accidentals, -2);
    });

    test('G major is spelled with F sharp', () {
      final notes = KeySignature.major('G').scaleNotes();
      expect(notes.map((note) => note.id).toList(), [
        'G4',
        'A4',
        'B4',
        'C5',
        'D5',
        'E5',
        'F#5',
        'G5',
      ]);
    });

    test('F major is spelled with B flat', () {
      final notes = KeySignature.major('F').scaleNotes();
      expect(notes.map((note) => note.id).toList(), [
        'F4',
        'G4',
        'A4',
        'Bb4',
        'C5',
        'D5',
        'E5',
        'F5',
      ]);
    });

    test('A natural minor is spelled correctly', () {
      final notes = KeySignature.minor('A').scaleNotes();
      expect(notes.map((note) => note.id).toList(), [
        'A4',
        'B4',
        'C5',
        'D5',
        'E5',
        'F5',
        'G5',
        'A5',
      ]);
    });

    test('relative major and minor', () {
      expect(KeySignature.minor('A').relativeMajorTonic, 'C');
      expect(KeySignature.major('C').relativeMinorTonic, 'A');
    });
  });

  group('Intervals', () {
    test('common intervals', () {
      expect(intervalBetween(Note.parse('C4'), Note.parse('E4')).abbreviation, 'M3');
      expect(intervalBetween(Note.parse('C4'), Note.parse('Eb4')).abbreviation, 'm3');
      expect(intervalBetween(Note.parse('C4'), Note.parse('G4')).abbreviation, 'P5');
      expect(intervalBetween(Note.parse('C4'), Note.parse('B4')).abbreviation, 'M7');
    });

    test('inversion', () {
      expect(Interval.minorThird.inverse.abbreviation, 'M6');
      expect(Interval.perfectFifth.inverse.abbreviation, 'P4');
    });
  });

  group('Scales', () {
    test('D major has F sharp and C sharp', () {
      final scale = Scale(root: Note.parse('D4'), mode: ScaleMode.major);
      expect(scale.notes.map((note) => note.id).toList(), [
        'D4',
        'E4',
        'F#4',
        'G4',
        'A4',
        'B4',
        'C#5',
        'D5',
      ]);
    });

    test('A minor pentatonic', () {
      final scale = Scale(
        root: Note.parse('A3'),
        mode: ScaleMode.minorPentatonic,
      );
      expect(scale.notes.map((note) => note.pitchClass).toList(), [
        'A',
        'C',
        'D',
        'E',
        'G',
        'A',
      ]);
    });

    test('blues scale has the blue note', () {
      final scale = Scale(root: Note.parse('A3'), mode: ScaleMode.blues);
      expect(scale.notes.map((note) => note.pitchClass).toList(), [
        'A',
        'C',
        'D',
        'Eb',
        'E',
        'G',
        'A',
      ]);
    });
  });

  group('Chords and progressions', () {
    test('C major diatonic triads', () {
      final triads = majorDiatonicTriads(KeySignature.major('C'));
      expect(triads.map((triad) => triad.chord.symbol).toList(), [
        'C',
        'Dm',
        'Em',
        'F',
        'G',
        'Am',
        'Bdim',
      ]);
    });

    test('G major diatonic triads', () {
      final triads = majorDiatonicTriads(KeySignature.major('G'));
      expect(triads.map((triad) => triad.chord.symbol).toList(), [
        'G',
        'Am',
        'Bm',
        'C',
        'D',
        'Em',
        'F#dim',
      ]);
    });

    test('I-IV-V-I in C', () {
      final progression = Progression.diatonic(
        KeySignature.major('C'),
        const [1, 4, 5, 1],
      );
      expect(progression.chordSymbols, 'C–F–G–C');
      expect(progression.display, 'I–IV–V–I');
      expect(cadenceFor(progression), CadenceType.authentic);
    });

    test('12-bar blues in A uses dominant sevenths', () {
      final blues = twelveBarBlues(KeySignature.major('A'));
      expect(blues.chords.first.symbol, 'A7');
      expect(blues.chords[4].symbol, 'D7');
      expect(blues.chords[8].symbol, 'E7');
      expect(blues.chords, hasLength(12));
    });
  });

  group('FSRS scheduler', () {
    const scheduler = FsrsScheduler();

    test('stability is the 90 percent retention point', () {
      expect(scheduler.retrievability(10, 10), closeTo(0.9, 0.001));
      expect(scheduler.retrievability(10, 0), 1);
    });

    test('initial stability follows the first rating', () {
      expect(scheduler.initialStability(ResponseRating.again), 0.212);
      expect(scheduler.initialStability(ResponseRating.good), 2.3065);
      expect(scheduler.initialStability(ResponseRating.easy), 8.2956);
    });

    test('a successful review increases stability', () {
      final first = scheduler.review(
        stabilityDays: 0,
        difficulty: 5,
        lastSeenAt: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 1),
        rating: ResponseRating.good,
        isFirstReview: true,
        family: SkillFamily.theory,
      );
      final second = scheduler.review(
        stabilityDays: first.stabilityDays,
        difficulty: first.difficulty,
        lastSeenAt: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 3),
        rating: ResponseRating.good,
        isFirstReview: false,
        family: SkillFamily.theory,
      );
      expect(second.stabilityDays, greaterThan(first.stabilityDays));
    });

    test('a lapse shortens stability and comes back soon', () {
      final result = scheduler.review(
        stabilityDays: 20,
        difficulty: 5,
        lastSeenAt: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 21),
        rating: ResponseRating.again,
        isFirstReview: false,
        family: SkillFamily.theory,
      );
      expect(result.stabilityDays, lessThan(20));
      expect(result.dueAt.difference(DateTime(2026, 1, 21)).inMinutes, 10);
    });

    test('performance skills are capped', () {
      final skill = SkillProgress(
        objectiveId: 'rhythm:test',
        family: SkillFamily.rhythm,
        stabilityDays: 29,
        difficulty: 3,
      );
      for (var day = 0; day < 10; day++) {
        skill.recordAnswer(
          SkillAnswer(
            objectiveId: skill.objectiveId,
            family: SkillFamily.rhythm,
            correct: true,
            now: DateTime(2026, 1, 1).add(Duration(days: day * 30)),
            responseMs: 1000,
          ),
        );
      }
      expect(skill.stabilityDays, lessThanOrEqualTo(30));
    });
  });

  group('Skill progress', () {
    test('mastery requires spaced production and transfer evidence', () {
      final skill = SkillProgress(
        objectiveId: 'theory:keysig:G',
        family: SkillFamily.theory,
      );
      for (var day = 0; day < 4; day++) {
        skill.recordAnswer(
          SkillAnswer(
            objectiveId: skill.objectiveId,
            family: SkillFamily.theory,
            correct: true,
            now: DateTime(2026, 1, 1).add(Duration(days: day * 7)),
            responseMs: 1500,
            production: true,
            transfer: true,
          ),
        );
      }
      expect(skill.mastered, isTrue);
      expect(skill.correctDays.length, greaterThanOrEqualTo(3));
    });

    test('a single day of correct answers does not master a skill', () {
      final skill = SkillProgress(
        objectiveId: 'theory:keysig:G',
        family: SkillFamily.theory,
      );
      for (var index = 0; index < 10; index++) {
        skill.recordAnswer(
          SkillAnswer(
            objectiveId: skill.objectiveId,
            family: SkillFamily.theory,
            correct: true,
            now: DateTime(2026, 1, 1, 10, index),
            responseMs: 1000,
            production: true,
            transfer: true,
          ),
        );
      }
      expect(skill.mastered, isFalse);
    });

    test('rating inference uses hints and speed', () {
      final slow = SkillAnswer(
        objectiveId: 'note:E4',
        family: SkillFamily.noteReading,
        correct: true,
        now: DateTime(2026, 1, 1),
        responseMs: 20000,
      );
      expect(slow.rating, ResponseRating.hard);

      final hinted = SkillAnswer(
        objectiveId: 'note:E4',
        family: SkillFamily.noteReading,
        correct: true,
        now: DateTime(2026, 1, 1),
        usedHint: true,
      );
      expect(hinted.rating, ResponseRating.hard);

      final fast = SkillAnswer(
        objectiveId: 'note:E4',
        family: SkillFamily.noteReading,
        correct: true,
        now: DateTime(2026, 1, 1),
        responseMs: 500,
        production: true,
      );
      expect(fast.rating, ResponseRating.easy);

      final wrong = SkillAnswer(
        objectiveId: 'note:E4',
        family: SkillFamily.noteReading,
        correct: false,
        now: DateTime(2026, 1, 1),
      );
      expect(wrong.rating, ResponseRating.again);
    });
  });
}
