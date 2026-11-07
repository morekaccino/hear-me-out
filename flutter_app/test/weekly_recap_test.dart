import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/notifications/weekly_recap.dart';

RecordingTake _take({
  required String id,
  required DateTime createdAt,
  String? pieceId,
}) {
  return RecordingTake(
    id: id,
    createdAt: createdAt.toUtc(),
    byteLength: 100,
    durationMs: 1000,
    pieceId: pieceId,
  );
}

void main() {
  final now = DateTime(2026, 11, 7, 12);

  test('the recap reads real minutes, phrases, recordings, and one pair', () {
    final progress = ProgressState.fresh();
    progress.recordPracticeSeconds(300, now);
    progress.quests.phrasesPracticed = 3;

    final takes = <RecordingTake>[
      _take(id: 'a1', createdAt: DateTime(2026, 11, 5, 9), pieceId: 'twinkle'),
      _take(id: 'a2', createdAt: DateTime(2026, 11, 6, 9), pieceId: 'twinkle'),
      _take(id: 'b1', createdAt: DateTime(2026, 11, 4, 9), pieceId: 'ode'),
      _take(id: 'old', createdAt: DateTime(2026, 10, 31, 9), pieceId: 'ode'),
      _take(id: 'free', createdAt: DateTime(2026, 11, 7, 9)),
    ];

    final recap = buildWeeklyRecap(
      progress: progress,
      takes: takes,
      now: now,
      pieceTitles: const <String, String>{'twinkle': 'Twinkle, Twinkle'},
    );

    expect(recap.minutes, 5);
    expect(recap.phrases, 3);
    expect(recap.recordings, 4);
    expect(recap.beforeAfter, isNotNull);
    final pair = recap.beforeAfter!;
    expect(pair.pieceId, 'twinkle');
    expect(pair.pieceTitle, 'Twinkle, Twinkle');
    expect(pair.takeCount, 2);
    expect(pair.before.id, 'a1');
    expect(pair.after.id, 'a2');
  });

  test('one take per piece has no before/after', () {
    final recap = buildWeeklyRecap(
      progress: ProgressState.fresh(),
      takes: <RecordingTake>[
        _take(id: 'a1', createdAt: now, pieceId: 'twinkle'),
        _take(id: 'b1', createdAt: now, pieceId: 'ode'),
      ],
      now: now,
    );
    expect(recap.hasBeforeAfter, isFalse);
    expect(recap.recordings, 2);
  });

  test('the empty state keeps every number at zero', () {
    final recap = buildWeeklyRecap(
      progress: ProgressState.fresh(),
      takes: const <RecordingTake>[],
      now: now,
    );
    expect(recap.minutes, 0);
    expect(recap.phrases, 0);
    expect(recap.recordings, 0);
    expect(recap.beforeAfter, isNull);
  });

  test('only the rolling seven local days count as recordings', () {
    final recap = buildWeeklyRecap(
      progress: ProgressState.fresh(),
      takes: <RecordingTake>[
        _take(id: 'first', createdAt: DateTime(2026, 11, 1, 0, 1)),
        _take(id: 'last', createdAt: DateTime(2026, 11, 7, 23, 59)),
        _take(id: 'before', createdAt: DateTime(2026, 10, 31, 23, 59)),
      ],
      now: now,
    );
    expect(recap.recordings, 2);
  });

  test('a missing piece title falls back to the real id', () {
    final recap = buildWeeklyRecap(
      progress: ProgressState.fresh(),
      takes: <RecordingTake>[
        _take(id: 'a1', createdAt: now, pieceId: 'unknown-piece'),
        _take(id: 'a2', createdAt: now, pieceId: 'unknown-piece'),
      ],
      now: now,
    );
    expect(recap.beforeAfter!.pieceTitle, 'unknown-piece');
  });
}
