import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/media/recording_encoder.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_manifest_export.dart';

RecordingTake _take({
  required String id,
  required DateTime at,
  String? pieceId,
  String? phraseId,
  int durationMs = 1000,
}) => RecordingTake(
  id: id,
  createdAt: at,
  byteLength: 987654,
  durationMs: durationMs,
  pieceId: pieceId,
  phraseId: phraseId,
  capped: true,
);

RecordingManifestExport _export(
  Iterable<RecordingTake> takes, {
  DateTime? generatedAt,
}) => RecordingManifestExport.fromIndex(
  RecordingIndex(takes),
  generatedAt: generatedAt ?? DateTime.utc(2026, 11, 7, 9, 15),
  capture: RecordingManifestCapture.analysis,
);

void main() {
  test('has the exact versioned shape and per-take field list', () {
    final export = _export(<RecordingTake>[
      _take(
        id: 'take-secret-1',
        at: DateTime.utc(2026, 11, 1, 10),
        pieceId: 'ode-to-joy',
        phraseId: 'ode-to-joy-1',
        durationMs: 1234,
      ),
    ]);

    final json = jsonDecode(export.encodeJson()) as Map<String, dynamic>;
    expect(json.keys.toSet(), <String>{
      'schemaVersion',
      'generatedAt',
      'capture',
      'takes',
    });
    expect(json['schemaVersion'], 1);
    expect(json['generatedAt'], '2026-11-07T09:15:00.000Z');

    final capture = json['capture'] as Map<String, dynamic>;
    expect(capture.keys.toSet(), <String>{
      'assumed',
      'sampleRate',
      'format',
    });
    expect(capture['assumed'], isTrue);
    expect(capture['sampleRate'], 22050);
    expect(capture['format'], 'wav');

    final takes = json['takes'] as List<dynamic>;
    expect(takes, hasLength(1));
    final take = takes.single as Map<String, dynamic>;
    expect(take.keys.toSet(), <String>{
      'pieceId',
      'phraseId',
      'createdAt',
      'durationSeconds',
      'firstTake',
      'lastTake',
    });
    expect(take['pieceId'], 'ode-to-joy');
    expect(take['phraseId'], 'ode-to-joy-1');
    expect(take['createdAt'], '2026-11-01T10:00:00.000Z');
    expect(take['durationSeconds'], 1.234);
    expect(take['firstTake'], isTrue);
    expect(take['lastTake'], isTrue);
  });

  test('the capture assumption matches the recorder and encoder', () {
    expect(
      RecordingManifestCapture.analysis.sampleRate,
      PhraseRecorder.analysisSampleRate,
    );
    expect(
      RecordingManifestCapture.analysis.format,
      const WavRecordingEncoder().fileExtension,
    );
    expect(RecordingManifestCapture.analysis.assumed, isTrue);
  });

  test('empty index produces an empty takes list, not an error', () {
    final json = jsonDecode(
      _export(const <RecordingTake>[]).encodeJson(),
    ) as Map<String, dynamic>;
    expect(json['schemaVersion'], 1);
    expect(json['capture'], isA<Map<String, dynamic>>());
    expect(json['takes'], isEmpty);
  });

  test('does not leak media ids, paths, byte counts, or install fields', () {
    final export = _export(<RecordingTake>[
      _take(
        id: 'take-secret-1',
        at: DateTime.utc(2026, 11, 1, 10),
        pieceId: 'ode-to-joy',
        phraseId: 'ode-to-joy-1',
      ),
    ]);
    final encoded = export.encodeJson();

    expect(encoded, isNot(contains('take-secret-1')));
    expect(encoded, isNot(contains('987654')));
    expect(encoded, isNot(contains('byteLength')));
    expect(encoded, isNot(contains('capped')));
    expect(encoded, isNot(contains('installId')));
    expect(encoded, isNot(contains('device')));
    expect(encoded, isNot(contains('participant')));
    expect(encoded, isNot(contains('/exports')));
    expect(encoded, isNot(contains('audio')));
  });

  test('first and last flags cover two or more takes of one piece', () {
    final export = _export(<RecordingTake>[
      _take(
        id: 'a1',
        at: DateTime.utc(2026, 11, 1, 10),
        pieceId: 'piece-a',
        phraseId: 'a-1',
      ),
      _take(
        id: 'a2',
        at: DateTime.utc(2026, 11, 1, 11),
        pieceId: 'piece-a',
        phraseId: 'a-2',
      ),
      _take(
        id: 'a3',
        at: DateTime.utc(2026, 11, 1, 12),
        pieceId: 'piece-a',
        phraseId: 'a-3',
      ),
    ]);

    expect(export.takes, hasLength(3));
    expect(export.takes[0].phraseId, 'a-1');
    expect(export.takes[0].firstTake, isTrue);
    expect(export.takes[0].lastTake, isFalse);
    expect(export.takes[1].phraseId, 'a-2');
    expect(export.takes[1].firstTake, isFalse);
    expect(export.takes[1].lastTake, isFalse);
    expect(export.takes[2].phraseId, 'a-3');
    expect(export.takes[2].firstTake, isFalse);
    expect(export.takes[2].lastTake, isTrue);
  });

  test('a single take is both first and last; a free take is neither', () {
    final export = _export(<RecordingTake>[
      _take(id: 'only', at: DateTime.utc(2026, 11, 1, 10), pieceId: 'piece-a'),
      _take(id: 'free', at: DateTime.utc(2026, 11, 1, 11)),
    ]);

    expect(export.takes[0].firstTake, isTrue);
    expect(export.takes[0].lastTake, isTrue);
    expect(export.takes[1].pieceId, isNull);
    expect(export.takes[1].phraseId, isNull);
    expect(export.takes[1].firstTake, isFalse);
    expect(export.takes[1].lastTake, isFalse);
  });

  test('generated and take times are normalized to UTC', () {
    final export = _export(<RecordingTake>[
      _take(
        id: 'a1',
        at: DateTime.parse('2026-11-01T12:00:00+02:00'),
        pieceId: 'piece-a',
      ),
    ], generatedAt: DateTime.parse('2026-11-07T11:15:00+02:00'));

    expect(export.generatedAt.isUtc, isTrue);
    expect(export.takes.single.createdAt.isUtc, isTrue);

    final json = jsonDecode(export.encodeJson()) as Map<String, dynamic>;
    expect(json['generatedAt'], '2026-11-07T09:15:00.000Z');
    final take =
        (json['takes'] as List<dynamic>).single as Map<String, dynamic>;
    expect(take['createdAt'], '2026-11-01T10:00:00.000Z');
  });
}
