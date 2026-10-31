import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/notation/staff_geometry.dart';

void main() {
  final geometry = StaffGeometry(size: const Size(390, 230));

  test('staff layout uses 18 px spaces on a 230 px canvas', () {
    expect(geometry.lineGap, 18);
    expect(geometry.staffTop, 79);
    expect(geometry.staffBottom, 151);
  });

  test('notes on the five lines land on the staff', () {
    expect(geometry.yFor(Note.parse('E4')), closeTo(151, 0.001));
    expect(geometry.yFor(Note.parse('G4')), closeTo(133, 0.001));
    expect(geometry.yFor(Note.parse('B4')), closeTo(115, 0.001));
    expect(geometry.yFor(Note.parse('D5')), closeTo(97, 0.001));
    expect(geometry.yFor(Note.parse('F5')), closeTo(79, 0.001));
  });

  test('spaces sit halfway between lines', () {
    expect(geometry.yFor(Note.parse('F4')), closeTo(142, 0.001));
    expect(geometry.yFor(Note.parse('A4')), closeTo(124, 0.001));
    expect(geometry.yFor(Note.parse('C5')), closeTo(106, 0.001));
    expect(geometry.yFor(Note.parse('E5')), closeTo(88, 0.001));
  });

  test('notes below the staff get the right ledger lines', () {
    expect(geometry.yFor(Note.parse('D4')), closeTo(160, 0.001));
    expect(geometry.yFor(Note.parse('C4')), closeTo(169, 0.001));
    expect(geometry.yFor(Note.parse('B3')), closeTo(178, 0.001));
    expect(geometry.yFor(Note.parse('A3')), closeTo(187, 0.001));
    expect(geometry.yFor(Note.parse('G3')), closeTo(196, 0.001));
    expect(geometry.yFor(Note.parse('F3')), closeTo(205, 0.001));
    expect(geometry.yFor(Note.parse('E3')), closeTo(214, 0.001));
  });

  test('ledger lines are only drawn outside the staff', () {
    expect(geometry.ledgerLineYs(Note.parse('E4')), isEmpty);
    expect(geometry.ledgerLineYs(Note.parse('F5')), isEmpty);
    expect(geometry.ledgerLineYs(Note.parse('C4')), [169]);
    expect(geometry.ledgerLineYs(Note.parse('A3')), [169, 187]);
    expect(geometry.ledgerLineYs(Note.parse('F3')), [169, 187, 205]);
    expect(geometry.ledgerLineYs(Note.parse('E3')), [169, 187, 205]);
    expect(geometry.ledgerLineYs(Note.parse('A5')), [61]);
  });

  test('staff membership is correct', () {
    expect(geometry.isOnStaff(Note.parse('E4')), isTrue);
    expect(geometry.isOnStaff(Note.parse('F5')), isTrue);
    expect(geometry.isOnStaff(Note.parse('D4')), isFalse);
    expect(geometry.isOnStaff(Note.parse('G5')), isFalse);
  });

  test('accidentals keep the same vertical position', () {
    expect(
      geometry.yFor(Note.parse('F#4')),
      closeTo(geometry.yFor(Note.parse('F4')), 0.001),
    );
    expect(
      geometry.yFor(Note.parse('Bb4')),
      closeTo(geometry.yFor(Note.parse('B4')), 0.001),
    );
  });

  test('every curriculum note fits on the canvas', () {
    for (final name in [
      'E3',
      'F3',
      'G3',
      'A3',
      'B3',
      'C4',
      'D4',
      'E4',
      'F4',
      'G4',
      'A4',
      'B4',
      'C5',
      'D5',
      'E5',
      'F5',
      'F#4',
      'C#5',
      'Bb4',
    ]) {
      final y = geometry.yFor(Note.parse(name));
      expect(y, greaterThan(0), reason: name);
      expect(y, lessThan(230), reason: name);
    }
  });
}
