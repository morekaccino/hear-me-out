import 'package:test/test.dart';
import 'package:hear_me_out/core/media/before_after.dart';
import 'package:hear_me_out/core/media/recording_index.dart';

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
  final day = DateTime.utc(2026, 10, 1, 12);

  test('builds a card from the first and latest take of a piece', () {
    final data = buildBeforeAfterCard(
      takes: [
        _take('b', day.add(const Duration(days: 10)), pieceId: 'greensleeves'),
        _take('a', day, pieceId: 'greensleeves'),
      ],
      pieceTitles: const {'greensleeves': 'Greensleeves'},
    );

    expect(data, isNotNull);
    expect(data!.pieceTitle, 'Greensleeves');
    expect(data.phraseLabel, 'Whole piece');
    expect(data.first.id, 'a');
    expect(data.last.id, 'b');
    expect(data.daysApart, 10);
    expect(data.takeCount, 2);
    expect(data.metricLabel, '10 days apart');
  });

  test('uses a shared phrase when one has two takes', () {
    final data = buildBeforeAfterCard(
      takes: [
        _take('a', day, pieceId: 'greensleeves', phraseId: 'p1'),
        _take('b', day.add(const Duration(days: 4)), pieceId: 'greensleeves'),
        _take('c', day.add(const Duration(days: 6)), pieceId: 'greensleeves', phraseId: 'p1'),
      ],
    );

    expect(data, isNotNull);
    expect(data!.phraseLabel, 'p1');
    expect(data.first.id, 'a');
    expect(data.last.id, 'c');
    expect(data.takeCount, 2);
  });

  test('one take or free takes do not make a card', () {
    expect(
      buildBeforeAfterCard(takes: [_take('a', day, pieceId: 'greensleeves')]),
      isNull,
    );
    expect(
      buildBeforeAfterCard(takes: [
        _take('a', day),
        _take('b', day.add(const Duration(days: 1))),
      ]),
      isNull,
    );
  });

  test('same-day takes report the same day honestly', () {
    final data = buildBeforeAfterCard(
      takes: [
        _take('a', day, pieceId: 'ode-to-joy'),
        _take('b', day.add(const Duration(hours: 2)), pieceId: 'ode-to-joy'),
      ],
    );

    expect(data, isNotNull);
    expect(data!.daysApart, 0);
    expect(data.metricLabel, 'Both takes from the same day');
  });
}
