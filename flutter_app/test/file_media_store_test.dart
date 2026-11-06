import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/media/file_media_store.dart';

void main() {
  late Directory tempDir;
  late FileMediaStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hmo_media_');
    store = FileMediaStore(directory: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Directory objectsDir(FileMediaStore store) => Directory(
    '${store.directory.path}${Platform.pathSeparator}'
    '${FileMediaStore.objectDirectoryName}',
  );

  File objectFile(FileMediaStore store, String id) => File(
    '${objectsDir(store).path}${Platform.pathSeparator}'
    '$id.${FileMediaStore.objectFileExtension}',
  );

  test('put and get roundtrip bytes and metadata', () async {
    final createdAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
    final timedStore = FileMediaStore(
      directory: tempDir.path,
      now: () => createdAt,
    );
    final bytes = Uint8List.fromList([1, 2, 3, 4, 250]);

    final ref = await timedStore.put(
      bytes,
      mimeType: 'audio/wav',
      id: 'take-1',
    );

    expect(ref.id, 'take-1');
    expect(ref.mimeType, 'audio/wav');
    expect(ref.byteLength, 5);
    expect(ref.createdAt, createdAt);
    expect(await timedStore.get('take-1'), bytes);
    expect(await timedStore.usageBytes(), 5);

    // A new store instance reads the same metadata from the index.
    final reopened = FileMediaStore(directory: tempDir.path);
    final refs = await reopened.list();
    expect(refs, [ref]);
    expect(await reopened.get('take-1'), bytes);
  });

  test('put replaces an existing id and updates its metadata', () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final timedStore = FileMediaStore(directory: tempDir.path, now: () => now);
    await timedStore.put(
      Uint8List.fromList([1, 2, 3]),
      mimeType: 'audio/wav',
      id: 'take-1',
    );
    now = now.add(const Duration(minutes: 5));

    final replacement = await timedStore.put(
      Uint8List.fromList([9, 8, 7, 6, 5]),
      mimeType: 'audio/mpeg',
      id: 'take-1',
    );

    expect(replacement.mimeType, 'audio/mpeg');
    expect(replacement.byteLength, 5);
    expect(replacement.createdAt, now);
    expect(await timedStore.get('take-1'), [9, 8, 7, 6, 5]);
    expect(await timedStore.list(), [replacement]);
    expect(await timedStore.usageBytes(), 5);
  });

  test('a failed write leaves the old bytes intact', () async {
    await store.put(
      Uint8List.fromList([1, 2, 3]),
      mimeType: 'audio/wav',
      id: 'take-1',
    );
    final blocker = Directory('${objectFile(store, 'take-1').path}.tmp');
    await blocker.create(recursive: true);

    await expectLater(
      store.put(
        Uint8List.fromList([9, 9]),
        mimeType: 'audio/wav',
        id: 'take-1',
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(await store.get('take-1'), [1, 2, 3]);
    expect((await store.list()).single.byteLength, 3);
    expect(await store.usageBytes(), 3);

    await blocker.delete(recursive: true);
  });

  test('invalid ids are rejected before touching the store', () async {
    final bytes = Uint8List.fromList([1]);
    final invalidIds = <String>[
      '',
      '.',
      '..',
      '../escape',
      'a/b',
      r'a\b',
      'bad id',
      'bad\nid',
      'bad\u0000id',
      'x' * 65,
      'CON',
      'index',
    ];

    for (final id in invalidIds) {
      await expectLater(
        store.put(bytes, mimeType: 'audio/wav', id: id),
        throwsArgumentError,
        reason: 'put($id)',
      );
      await expectLater(store.get(id), throwsArgumentError, reason: 'get($id)');
      await expectLater(
        store.delete(id),
        throwsArgumentError,
        reason: 'delete($id)',
      );
    }

    expect(await store.list(), isEmpty);
    expect(await store.usageBytes(), 0);
  });

  test('mime type must not be blank', () async {
    await expectLater(
      store.put(Uint8List.fromList([1]), mimeType: '  '),
      throwsArgumentError,
    );
    expect(await store.list(), isEmpty);
  });

  test('delete is idempotent and removes only the requested item', () async {
    await store.put(Uint8List.fromList([1]), mimeType: 'audio/wav', id: 'keep');
    await store.put(
      Uint8List.fromList([2, 2]),
      mimeType: 'audio/wav',
      id: 'remove',
    );

    await store.delete('remove');
    await store.delete('remove');
    await store.delete('never-existed');

    expect(await store.get('remove'), isNull);
    expect(await store.get('keep'), [1]);
    expect(await store.usageBytes(), 1);
  });

  test(
    'list is oldest first, usage sums bytes, clear empties everything',
    () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final timedStore = FileMediaStore(
        directory: tempDir.path,
        now: () => now,
      );
      await timedStore.put(
        Uint8List.fromList([1]),
        mimeType: 'audio/wav',
        id: 'second',
      );
      now = now.add(const Duration(minutes: 1));
      await timedStore.put(
        Uint8List.fromList([2, 2]),
        mimeType: 'audio/wav',
        id: 'first',
      );
      now = now.add(const Duration(minutes: 1));
      await timedStore.put(
        Uint8List.fromList([3, 3, 3]),
        mimeType: 'audio/wav',
        id: 'third',
      );
      await objectFile(timedStore, 'stray').writeAsBytes([4, 4, 4, 4]);

      final refs = await timedStore.list();
      expect(refs.map((ref) => ref.id).toList(), ['second', 'first', 'third']);
      expect(await timedStore.usageBytes(), 6);

      await timedStore.clear();

      expect(await timedStore.list(), isEmpty);
      expect(await timedStore.usageBytes(), 0);
      expect(await timedStore.get('first'), isNull);
      expect(await timedStore.listOrphans(), isEmpty);
      expect(await objectsDir(timedStore).list().toList(), isEmpty);
    },
  );

  test('orphan files are reported and removed', () async {
    await store.put(Uint8List.fromList([1]), mimeType: 'audio/wav', id: 'kept');
    final orphan = objectFile(store, 'stray');
    await orphan.writeAsBytes([7, 7]);
    final staleTemp = File('${orphan.path}.tmp');
    await staleTemp.writeAsBytes([8]);

    expect(await store.listOrphans(), ['stray']);
    expect(await store.removeOrphans(), 2);
    expect(await store.listOrphans(), isEmpty);
    expect(await orphan.exists(), isFalse);
    expect(await staleTemp.exists(), isFalse);
    expect(await store.get('kept'), [1]);
  });

  test('an index entry whose file is gone is pruned on load', () async {
    await store.put(
      Uint8List.fromList([1, 2]),
      mimeType: 'audio/wav',
      id: 'gone',
    );
    await objectFile(store, 'gone').delete();

    final reopened = FileMediaStore(directory: tempDir.path);

    expect(await reopened.list(), isEmpty);
    expect(await reopened.get('gone'), isNull);
    expect(await reopened.usageBytes(), 0);
    expect(await reopened.listOrphans(), isEmpty);
  });

  test(
    'an index entry with a stale byte length is reconciled from disk',
    () async {
      await store.put(
        Uint8List.fromList([1, 2, 3]),
        mimeType: 'audio/wav',
        id: 'take-1',
      );
      await objectFile(store, 'take-1').writeAsBytes([1, 2, 3, 4, 5]);

      final reopened = FileMediaStore(directory: tempDir.path);

      expect((await reopened.list()).single.byteLength, 5);
      expect(await reopened.usageBytes(), 5);
    },
  );

  test('timestamp injection is deterministic and stored in UTC', () async {
    final localTime = DateTime(2026, 3, 4, 5, 6, 7);
    final timedStore = FileMediaStore(
      directory: tempDir.path,
      now: () => localTime,
    );

    final first = await timedStore.put(
      Uint8List.fromList([1]),
      mimeType: 'audio/wav',
      id: 'a',
    );
    final second = await timedStore.put(
      Uint8List.fromList([2]),
      mimeType: 'audio/wav',
      id: 'b',
    );

    expect(first.createdAt, localTime.toUtc());
    expect(second.createdAt, localTime.toUtc());
    expect(first.createdAt.isUtc, isTrue);
    expect((await timedStore.list()).map((ref) => ref.id).toList(), ['a', 'b']);
  });

  test('generated ids are valid and unique', () async {
    final generated = await store.put(
      Uint8List.fromList([1]),
      mimeType: 'audio/wav',
    );
    final another = await store.put(
      Uint8List.fromList([2]),
      mimeType: 'audio/wav',
    );

    expect(FileMediaStore.isValidId(generated.id), isTrue);
    expect(FileMediaStore.isValidId(another.id), isTrue);
    expect(generated.id, isNot(another.id));
    expect(await store.get(generated.id), [1]);
    expect(await store.get(another.id), [2]);
  });

  test(
    'corrupt index JSON is rejected instead of silently discarded',
    () async {
      await File(
        '${tempDir.path}${Platform.pathSeparator}'
        '${FileMediaStore.indexFileName}',
      ).writeAsString('{not json');

      await expectLater(store.list(), throwsFormatException);
    },
  );

  test(
    'file store does not depend on Flutter, path_provider, or dart:html',
    () {
      final source = File('lib/core/media/file_media_store.dart')
          .readAsStringSync();

      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains("import 'package:path_provider")));
      expect(source, isNot(contains('dart:html')));
    },
  );

  test('web store uses package:web rather than dart:io or dart:html', () {
    final source = File('lib/core/media/web_media_store.dart')
        .readAsStringSync();

    expect(source, isNot(contains("import 'dart:io'")));
    expect(source, isNot(contains('dart:html')));
    expect(source, contains("import 'package:web/web.dart'"));
  });
}
