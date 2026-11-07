import 'package:test/test.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/take_comparison.dart';

RecordingTake _take(
  String id,
  DateTime at, {
  String? pieceId,
  String? phraseId,
}) => RecordingTake(
  id: id,
  createdAt: at,
  byteLength: 100,
  durationMs: 1000,
  pieceId: pieceId,
  phraseId: phraseId,
);

void main() {
  final day = DateTime.utc(2026, 11, 1, 12);

  test('hasComparablePiecePair needs two takes for one piece', () {
    expect(
      hasComparablePiecePair([
        _take('a', day, pieceId: 'greensleeves'),
        _take('b', day, pieceId: 'greensleeves'),
      ]),
      isTrue,
    );
    expect(
      hasComparablePiecePair([
        _take('a', day, pieceId: 'greensleeves'),
        _take('b', day, pieceId: 'ode-to-joy'),
      ]),
      isFalse,
    );
    expect(
      hasComparablePiecePair([
        _take('a', day),
        _take('b', day),
      ]),
      isFalse,
    );
  });

  test('default pair uses the oldest and newest take for a piece', () {
    final pair = defaultTakeComparisonPair([
      _take('b', day.add(const Duration(days: 4)), pieceId: 'greensleeves'),
      _take('a', day, pieceId: 'greensleeves'),
      _take('c', day.add(const Duration(days: 9)), pieceId: 'greensleeves'),
    ]);

    expect(pair, isNotNull);
    expect(pair!.left.id, 'a');
    expect(pair.right.id, 'c');
  });

  test('default pair prefers a phrase with two takes', () {
    final pair = defaultTakeComparisonPair([
      _take('a', day, pieceId: 'greensleeves', phraseId: 'p1'),
      _take('b', day.add(const Duration(days: 2)), pieceId: 'greensleeves'),
      _take('c', day.add(const Duration(days: 3)), pieceId: 'greensleeves', phraseId: 'p1'),
      _take('d', day.add(const Duration(days: 5)), pieceId: 'greensleeves'),
    ]);

    expect(pair, isNotNull);
    expect(pair!.left.id, 'a');
    expect(pair.right.id, 'c');
  });

  test('default pair falls back to the oldest and newest overall', () {
    final pair = defaultTakeComparisonPair([
      _take('a', day),
      _take('b', day.add(const Duration(days: 1))),
    ]);

    expect(pair, isNotNull);
    expect(pair!.left.id, 'a');
    expect(pair.right.id, 'b');
  });

  test('one take has no pair', () {
    expect(defaultTakeComparisonPair([_take('a', day)]), isNull);
  });
}
