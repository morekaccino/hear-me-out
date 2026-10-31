import 'dart:math' as math;
import 'dart:ui';

import '../music/note.dart';

/// Pure staff math, independent of Flutter painting.
class StaffGeometry {
  StaffGeometry({required this.size})
    : lineGap = math.min(size.height / 10.0, 18.0),
      staffTop = size.height / 2 - math.min(size.height / 10.0, 18.0) * 2;

  final Size size;
  final double lineGap;
  final double staffTop;

  static final int _bottomLineIndex = Note('E', 4).diatonicIndex;
  static final int _topLineIndex = Note('F', 5).diatonicIndex;

  double get staffBottom => staffTop + lineGap * 4;

  double get middleLine => staffTop + lineGap * 2;

  /// The G line, where the treble clef curl belongs.
  double get gLine => staffBottom - lineGap;

  double get noteX => size.width * 0.55;

  double yFor(Note note) =>
      staffBottom - (note.diatonicIndex - _bottomLineIndex) * (lineGap / 2);

  bool isOnStaff(Note note) =>
      note.diatonicIndex >= _bottomLineIndex &&
      note.diatonicIndex <= _topLineIndex;

  bool needsLedger(Note note) => !isOnStaff(note);

  /// Vertical positions of every ledger line needed for [note].
  List<double> ledgerLineYs(Note note) {
    final result = <double>[];
    final index = note.diatonicIndex;
    if (index > _topLineIndex) {
      for (var step = _topLineIndex + 2; step <= index; step += 2) {
        result.add(staffBottom - (step - _bottomLineIndex) * (lineGap / 2));
      }
    } else if (index < _bottomLineIndex) {
      for (var step = _bottomLineIndex - 2; step >= index; step -= 2) {
        result.add(staffBottom - (step - _bottomLineIndex) * (lineGap / 2));
      }
    }
    return result;
  }
}
