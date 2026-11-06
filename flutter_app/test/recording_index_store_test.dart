import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/storage/recording_index_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  RecordingIndex sampleIndex() => RecordingIndex(<RecordingTake>[
    RecordingTake(
      id: 'take-1',
      createdAt: DateTime.utc(2026, 11, 6, 12),
      byteLength: 1200,
      durationMs: 5000,
      pieceId: 'ode-to-joy',
      phraseId: 'p1',
      capped: true,
    ),
    RecordingTake(
      id: 'take-2',
      createdAt: DateTime.utc(2026, 11, 6, 13),
      byteLength: 800,
      durationMs: 3000,
    ),
  ]);

  test('round trips the versioned index and its take manifest', () async {
    final store = SharedPreferencesRecordingIndexStore();
    await store.save(sampleIndex());

    final reopened = SharedPreferencesRecordingIndexStore();
    final loaded = await reopened.load();

    expect(loaded, isNotNull);
    expect(loaded!.length, 2);
    expect(loaded.takeFor('take-1')!.pieceId, 'ode-to-joy');
    expect(loaded.takeFor('take-1')!.phraseId, 'p1');
    expect(loaded.takeFor('take-1')!.durationMs, 5000);
    expect(loaded.takeFor('take-1')!.capped, isTrue);
    expect(loaded.takeFor('take-2')!.pieceId, isNull);
    expect(loaded.takeFor('take-2')!.capped, isFalse);
  });

  test('a missing document returns null', () async {
    expect(await SharedPreferencesRecordingIndexStore().load(), isNull);
  });

  test('a future schema version is rejected, not guessed', () async {
    final raw = jsonEncode(<String, Object?>{
      'schemaVersion': 2,
      'takes': <Object?>[],
    });
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesRecordingIndexStore.storageKey: raw,
    });

    await expectLater(
      SharedPreferencesRecordingIndexStore().load(),
      throwsA(isA<FormatException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(SharedPreferencesRecordingIndexStore.unreadableKey),
      raw,
    );
  });

  test('malformed entries are skipped without hiding the rest', () {
    final index = RecordingIndex.fromJson(<String, dynamic>{
      'schemaVersion': RecordingIndex.schemaVersion,
      'takes': <Object?>[
        <String, Object?>{
          'id': 'good',
          'createdAt': '2026-11-06T12:00:00.000Z',
          'byteLength': 100,
          'durationMs': 1000,
        },
        <String, Object?>{'id': 'bad', 'byteLength': -1},
      ],
    });

    expect(index.takes.single.id, 'good');
    expect(index.skippedEntries, 1);
  });

  test('clear removes the document', () async {
    final store = SharedPreferencesRecordingIndexStore();
    await store.save(sampleIndex());
    await store.clear();

    expect(await store.load(), isNull);
  });
}
