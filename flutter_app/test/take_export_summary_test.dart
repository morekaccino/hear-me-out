import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/app_metadata.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/take_export_summary.dart';

RecordingTake _take({
  String id = 'take-1',
  String? pieceId = 'ode-to-joy',
  String? phraseId = 'p1',
}) => RecordingTake(
  id: id,
  createdAt: DateTime.utc(2026, 11, 6, 12, 30),
  byteLength: 196404,
  durationMs: 42000,
  pieceId: pieceId,
  phraseId: phraseId,
);

TakeExportEvidence _evidence() => TakeExportEvidence(
  attempts: 7,
  bestAccuracy: 0.92,
  bestTempoBpm: 72,
  performanceDays: 4,
  masteryDays: 1,
  performanceSpanDays: 9,
  contentVersion: 1,
  lastPerformedAt: DateTime.utc(2026, 11, 5, 18),
);

TakeExportSummary _summary({
  RecordingTake? take,
  DateTime? exportedAt,
  TakeExportPiece? piece = const TakeExportPiece(
    title: 'Ode to Joy',
    composer: 'Ludwig van Beethoven',
    stage: 2,
  ),
  TakeExportEvidence? evidence,
  bool withEvidence = true,
}) => TakeExportSummary.fromTake(
  take: take ?? _take(),
  exportedAt: exportedAt ?? DateTime.utc(2026, 11, 7, 9, 15),
  piece: piece,
  evidence: withEvidence ? (evidence ?? _evidence()) : null,
);

void main() {
  test('JSON is versioned and carries only the documented take fields', () {
    final json = _summary().toJson();

    expect(json['schemaVersion'], TakeExportSummary.schemaVersion);
    expect(json['schemaVersion'], 1);
    expect(json['appVersion'], appVersion);
    expect(json['takeId'], 'take-1');
    expect(json['createdAt'], '2026-11-06T12:30:00.000Z');
    expect(json['durationMs'], 42000);
    expect(json['capped'], isFalse);
    expect(json['pieceId'], 'ode-to-joy');
    expect(json['piece'], <String, Object?>{
      'title': 'Ode to Joy',
      'composer': 'Ludwig van Beethoven',
      'stage': 2,
    });
    expect(json['phraseId'], 'p1');
    expect(json['exportedAt'], '2026-11-07T09:15:00.000Z');

    final evidence = json['evidence']! as Map<String, Object?>;
    expect(evidence['label'], TakeExportEvidence.label);
    expect(evidence['attempts'], 7);
    expect(evidence['bestAccuracy'], 0.92);
    expect(evidence['bestTempoBpm'], 72);
    expect(evidence['performanceDays'], 4);
    expect(evidence['masteryDays'], 1);
    expect(evidence['performanceSpanDays'], 9);
    expect(evidence['contentVersion'], 1);
    expect(evidence['lastPerformedAt'], '2026-11-05T18:00:00.000Z');

    final encoded = jsonEncode(json);
    expect(encoded, isNot(contains('installId')));
    expect(encoded, isNot(contains('deviceId')));
    expect(encoded, isNot(contains('exports/')));
    expect(encoded, isNot(contains('@')));
  });

  test('the same input is deterministic apart from the export timestamp', () {
    final first = _summary();
    final second = _summary();
    expect(jsonEncode(second.toJson()), jsonEncode(first.toJson()));

    final later = _summary(exportedAt: DateTime.utc(2026, 11, 8, 10));
    final firstMap = Map<String, Object?>.from(first.toJson())
      ..remove('exportedAt');
    final laterMap = Map<String, Object?>.from(later.toJson())
      ..remove('exportedAt');
    expect(laterMap, firstMap);
    expect(later.toJson()['exportedAt'], isNot(first.toJson()['exportedAt']));
  });

  test('an unknown piece and unknown phrase fall back without inventing data', () {
    final summary = _summary(
      take: _take(pieceId: 'custom-piece', phraseId: 'unknown-phrase'),
      piece: null,
      withEvidence: false,
    );
    final json = summary.toJson();

    expect(json['pieceId'], 'custom-piece');
    expect(json['piece'], isNull);
    expect(json['phraseId'], 'unknown-phrase');
    expect(json['evidence'], isNull);
    expect(json.containsKey('score'), isFalse);
    expect(json.containsKey('grade'), isFalse);
  });

  test('a free take has no piece, phrase, or evidence block', () {
    final json = _summary(
      take: _take(pieceId: null, phraseId: null),
      piece: null,
      withEvidence: false,
    ).toJson();

    expect(json['pieceId'], isNull);
    expect(json['piece'], isNull);
    expect(json['phraseId'], isNull);
    expect(json['evidence'], isNull);
  });

  test('the PDF starts with %PDF and is non-trivial', () async {
    final bytes = await buildTakeSummaryPdf(_summary());

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('a take without evidence still produces a complete PDF', () async {
    final bytes = await buildTakeSummaryPdf(
      _summary(piece: null, withEvidence: false),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('the app version constant matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });
}
