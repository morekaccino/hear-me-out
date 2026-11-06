@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:hear_me_out/core/media/web_media_store.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  var databaseCounter = 0;

  String nextDatabaseName() =>
      'hmo_media_test_${DateTime.now().microsecondsSinceEpoch}_'
      '${databaseCounter++}';

  Future<WebMediaStore> open(String name, {DateTime Function()? now}) {
    final store = WebMediaStore.open(databaseName: name, now: now);
    addTearDown(() async {
      final resolved = await store;
      resolved.close();
      await _deleteDatabase(name);
    });
    return store;
  }

  test('put/get roundtrip persists bytes and manifest fields', () async {
    final name = nextDatabaseName();
    final createdAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
    final store = await open(name, now: () => createdAt);
    final bytes = Uint8List.fromList([1, 2, 3, 4, 250]);

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
    expect(ref.createdAt, createdAt);
    expect(ref.pieceId, 'ode-to-joy');
    expect(ref.phraseId, 'bars-1-2');
    expect(ref.durationMs, 4200);
    expect(ref.score, 0.875);
    expect(ref.analysisVersion, 3);
    expect(await store.get('take-1'), bytes);
    expect(await store.usageBytes(), 5);

    final reopened = await open(name);
    expect(await reopened.list(), [ref]);
  });

  test('list is oldest first, delete is idempotent, clear empties', () async {
    var now = DateTime.utc(2026, 1, 1, 12);
    final store = await open(nextDatabaseName(), now: () => now);

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
    expect(await store.usageBytes(), 6);

    await store.delete('first');
    await store.delete('first');
    await store.delete('missing');
    expect(await store.get('first'), isNull);
    expect(await store.usageBytes(), 4);

    await store.clear();
    expect(await store.list(), isEmpty);
    expect(await store.usageBytes(), 0);
  });

  test('replacing an id clears omitted manifest fields', () async {
    final store = await open(nextDatabaseName());
    await store.put(
      Uint8List.fromList([1]),
      mimeType: 'audio/wav',
      id: 'take-1',
      pieceId: 'piece',
      phraseId: 'phrase',
      durationMs: 100,
      score: 0.5,
      analysisVersion: 1,
    );

    final replacement = await store.put(
      Uint8List.fromList([2]),
      mimeType: 'audio/wav',
      id: 'take-1',
    );

    expect(replacement.pieceId, isNull);
    expect(replacement.phraseId, isNull);
    expect(replacement.durationMs, isNull);
    expect(replacement.score, isNull);
    expect(replacement.analysisVersion, isNull);
    expect(await store.list(), [replacement]);
  });

  test('malformed records are skipped by list and usage', () async {
    final name = nextDatabaseName();
    final store = await open(name);
    await store.put(
      Uint8List.fromList([1, 2]),
      mimeType: 'audio/wav',
      id: 'good',
    );

    final database = await _openDatabase(name);
    final transaction = database.transaction(
      WebMediaStore.objectStoreName.toJS,
      'readwrite',
    );
    final record = JSObject();
    record.setProperty('id'.toJS, 'bad'.toJS);
    record.setProperty('byteLength'.toJS, 3.toJS);
    final request = transaction
        .objectStore(WebMediaStore.objectStoreName)
        .put(record, 'bad'.toJS);
    await _requestDone(request);
    await _transactionDone(transaction);
    database.close();

    final refs = await store.list();
    expect(refs.map((ref) => ref.id).toList(), ['good']);
    expect(await store.usageBytes(), 2);
  });

  test('a closed store throws a clear StateError', () async {
    final store = await open(nextDatabaseName());
    store.close();

    await expectLater(
      store.list(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('closed'),
        ),
      ),
    );
  });
}

Future<void> _deleteDatabase(String name) async {
  final request = web.window.indexedDB.deleteDatabase(name);
  final completer = Completer<void>();
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Could not delete test database.'));
    }
  }).toJS;
  await completer.future;
}

Future<web.IDBDatabase> _openDatabase(String name) async {
  final request = web.window.indexedDB.open(
    name,
    WebMediaStore.databaseVersion,
  );
  final completer = Completer<web.IDBDatabase>();
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.complete(request.result as web.IDBDatabase);
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Could not open test database.'));
    }
  }).toJS;
  return completer.future;
}

Future<void> _requestDone(web.IDBRequest request) {
  final completer = Completer<void>();
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Request failed.'));
    }
  }).toJS;
  return completer.future;
}

Future<void> _transactionDone(web.IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  transaction.onabort = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Transaction aborted.'));
    }
  }).toJS;
  return completer.future;
}
