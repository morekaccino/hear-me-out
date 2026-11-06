import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/media_store.dart';

void main() {
  group('MemoryMediaStore', () {
    test('put stores bytes and returns metadata', () async {
      final now = DateTime.utc(2026, 1, 1, 12);
      final store = MemoryMediaStore(clock: () => now);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final ref = await store.put(
        bytes,
        mimeType: 'audio/wav',
        id: 'take-1',
        pieceId: 'ode-to-joy',
        phraseId: 'bars-1-2',
        durationMs: 4200,
        score: 0.875,
        analysisVersion: 3,
      );

      expect(ref.id, 'take-1');
      expect(ref.mimeType, 'audio/wav');
      expect(ref.byteLength, 4);
      expect(ref.createdAt, now);
      expect(ref.pieceId, 'ode-to-joy');
      expect(ref.phraseId, 'bars-1-2');
      expect(ref.durationMs, 4200);
      expect(ref.score, 0.875);
      expect(ref.analysisVersion, 3);
      expect(await store.get('take-1'), [1, 2, 3, 4]);
      expect(await store.usageBytes(), 4);
    });

    test('manifest fields are optional', () async {
      final store = MemoryMediaStore();
      final ref = await store.put(
        Uint8List.fromList([1]),
        mimeType: 'audio/wav',
        id: 'take-1',
      );

      expect(ref.pieceId, isNull);
      expect(ref.phraseId, isNull);
      expect(ref.durationMs, isNull);
      expect(ref.score, isNull);
      expect(ref.analysisVersion, isNull);
    });

    test('invalid manifest values are rejected with the field name', () async {
      final store = MemoryMediaStore();
      final bytes = Uint8List.fromList([1]);
      final cases = <String, Future<MediaRef> Function()>{
        'pieceId': () => store.put(bytes, mimeType: 'audio/wav', pieceId: ''),
        'phraseId': () =>
            store.put(bytes, mimeType: 'audio/wav', phraseId: '  '),
        'durationMs': () =>
            store.put(bytes, mimeType: 'audio/wav', durationMs: -1),
        'analysisVersion': () =>
            store.put(bytes, mimeType: 'audio/wav', analysisVersion: -1),
        'score': () =>
            store.put(bytes, mimeType: 'audio/wav', score: double.nan),
      };

      for (final entry in cases.entries) {
        await expectLater(
          entry.value(),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              entry.key,
            ),
          ),
          reason: entry.key,
        );
      }

      expect(await store.list(), isEmpty);
      expect(await store.usageBytes(), 0);
    });

    test('non-finite scores are rejected', () async {
      final store = MemoryMediaStore();

      for (final score in <double>[double.infinity, double.negativeInfinity]) {
        await expectLater(
          store.put(
            Uint8List.fromList([1]),
            mimeType: 'audio/wav',
            score: score,
          ),
          throwsA(
            isA<ArgumentError>().having((error) => error.name, 'name', 'score'),
          ),
        );
      }
    });

    test('put replaces an existing id atomically', () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final store = MemoryMediaStore(clock: () => now);
      await store.put(
        Uint8List.fromList([1, 2, 3]),
        mimeType: 'audio/wav',
        id: 'take-1',
      );
      now = now.add(const Duration(minutes: 5));

      final replacement = await store.put(
        Uint8List.fromList([9, 8, 7, 6, 5]),
        mimeType: 'audio/wav',
        id: 'take-1',
      );

      expect(replacement.byteLength, 5);
      expect(replacement.createdAt, now);
      expect(await store.get('take-1'), [9, 8, 7, 6, 5]);
      expect(await store.usageBytes(), 5);
      expect(await store.list(), hasLength(1));
    });

    test('a rejected put leaves the existing item intact', () async {
      final store = MemoryMediaStore();
      await store.put(
        Uint8List.fromList([1, 2]),
        mimeType: 'audio/wav',
        id: 'take-1',
      );

      await expectLater(
        store.put(Uint8List.fromList([9, 9, 9]), mimeType: '   ', id: 'take-1'),
        throwsArgumentError,
      );

      expect(await store.get('take-1'), [1, 2]);
      expect(await store.usageBytes(), 2);
    });

    test('get returns a defensive copy', () async {
      final store = MemoryMediaStore();
      final source = Uint8List.fromList([1, 2, 3]);
      await store.put(source, mimeType: 'audio/wav', id: 'take-1');

      source[0] = 99;
      final firstRead = await store.get('take-1');
      expect(firstRead, [1, 2, 3]);

      firstRead![0] = 99;
      expect(await store.get('take-1'), [1, 2, 3]);
      expect(await store.get('missing'), isNull);
    });

    test('delete removes only the requested item', () async {
      final store = MemoryMediaStore();
      await store.put(
        Uint8List.fromList([1]),
        mimeType: 'audio/wav',
        id: 'keep',
      );
      await store.put(
        Uint8List.fromList([2, 2]),
        mimeType: 'audio/wav',
        id: 'remove',
      );

      await store.delete('remove');

      expect(await store.get('remove'), isNull);
      expect(await store.get('keep'), [1]);
      expect(await store.usageBytes(), 1);
      await store.delete('missing');
    });

    test('list returns metadata oldest first, then by id', () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final store = MemoryMediaStore(clock: () => now);
      await store.put(
        Uint8List.fromList([1]),
        mimeType: 'audio/wav',
        id: 'second',
      );
      now = now.add(const Duration(minutes: 1));
      await store.put(
        Uint8List.fromList([2, 2]),
        mimeType: 'audio/wav',
        id: 'first',
      );
      now = now.add(const Duration(minutes: 1));
      await store.put(
        Uint8List.fromList([3, 3, 3]),
        mimeType: 'audio/wav',
        id: 'third',
      );

      final refs = await store.list();

      expect(refs.map((ref) => ref.id).toList(), ['second', 'first', 'third']);
      expect(refs.map((ref) => ref.byteLength).toList(), [1, 2, 3]);
    });

    test('generated ids are stable and avoid caller-supplied ids', () async {
      final store = MemoryMediaStore();
      await store.put(
        Uint8List.fromList([1]),
        mimeType: 'audio/wav',
        id: 'media-1',
      );

      final generated = await store.put(
        Uint8List.fromList([2]),
        mimeType: 'audio/wav',
      );
      final another = await store.put(
        Uint8List.fromList([3]),
        mimeType: 'audio/wav',
      );

      expect(generated.id, startsWith('media-'));
      expect(generated.id, isNot('media-1'));
      expect(another.id, isNot(generated.id));
      expect(await store.get(generated.id), [2]);
    });

    test('clear removes every item', () async {
      final store = MemoryMediaStore();
      await store.put(
        Uint8List.fromList([1, 2]),
        mimeType: 'audio/wav',
        id: 'a',
      );
      await store.put(Uint8List.fromList([3]), mimeType: 'audio/wav', id: 'b');

      await store.clear();

      expect(await store.list(), isEmpty);
      expect(await store.usageBytes(), 0);
      expect(await store.get('a'), isNull);
    });

    test('empty metadata is rejected without changing the store', () async {
      final store = MemoryMediaStore();

      await expectLater(
        store.put(Uint8List.fromList([1]), mimeType: '  '),
        throwsArgumentError,
      );
      await expectLater(
        store.put(Uint8List.fromList([1]), mimeType: 'audio/wav', id: ' '),
        throwsArgumentError,
      );

      expect(await store.usageBytes(), 0);
      expect(await store.list(), isEmpty);
    });

    test('MediaRef compares by value, including manifest fields', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      MediaRef make({double? score}) => MediaRef(
        id: 'a',
        mimeType: 'audio/wav',
        byteLength: 2,
        createdAt: createdAt,
        pieceId: 'piece',
        phraseId: 'phrase',
        durationMs: 1000,
        score: score,
        analysisVersion: 1,
      );

      final first = make(score: 0.5);
      final second = make(score: 0.5);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(make(score: 0.75)));
    });
  });

  test(
    'MediaStore is pure Dart and does not import Flutter or platform IO',
    () {
      final source = File('lib/core/media/media_store.dart').readAsStringSync();

      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains("import 'dart:io'")));
      expect(source, isNot(contains("import 'dart:html'")));
      expect(source, isNot(contains("import 'dart:ui'")));
    },
  );
}
