import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'media_store.dart';

/// [MediaStore] backed by IndexedDB.
///
/// Browsers have no writable application filesystem, so recordings live in one
/// IndexedDB object store. Each record is keyed by media id and holds the
/// metadata plus the bytes as a `Uint8Array`.
///
/// [open] throws [StateError] when IndexedDB is unavailable or blocked. There
/// is deliberately no silent in-memory fallback for real recordings; a caller
/// that wants one must choose [MemoryMediaStore] explicitly.
class WebMediaStore implements MediaStore {
  WebMediaStore._(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Default IndexedDB database name.
  static const String databaseName = 'hear_me_out_media';

  /// Object store that holds recordings and other media.
  static const String objectStoreName = 'media';

  /// IndexedDB schema version for this store.
  static const int databaseVersion = 1;

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  final web.IDBDatabase _database;
  final DateTime Function() _now;
  Future<void> _tail = Future<void>.value();
  int _nextId = 1;

  /// Opens (and creates if needed) the media database.
  ///
  /// Throws [StateError] if IndexedDB is missing, blocked by another tab, or
  /// fails to open.
  static Future<WebMediaStore> open({
    String databaseName = WebMediaStore.databaseName,
    DateTime Function()? now,
  }) async {
    final web.IDBFactory factory;
    try {
      factory = web.window.indexedDB;
    } catch (error) {
      throw StateError(
        'IndexedDB is unavailable. Hear Me Out needs local browser storage '
        'to keep recordings: $error',
      );
    }

    final request = factory.open(databaseName, databaseVersion);
    final completer = Completer<web.IDBDatabase>();

    request.onupgradeneeded = ((web.Event _) {
      final database = request.result as web.IDBDatabase;
      if (!database.objectStoreNames.contains(objectStoreName)) {
        database.createObjectStore(objectStoreName);
      }
    }).toJS;
    request.onblocked = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError(
            'IndexedDB is blocked by another tab. Close other copies of '
            'Hear Me Out and try again.',
          ),
        );
      }
    }).toJS;
    request.onsuccess = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.complete(request.result as web.IDBDatabase);
      }
    }).toJS;
    request.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(_indexedDbError('open', request.error));
      }
    }).toJS;

    final database = await completer.future;
    // Let another tab upgrade the schema instead of blocking it indefinitely.
    database.onversionchange = ((web.Event _) {
      database.close();
    }).toJS;
    return WebMediaStore._(database, now: now);
  }

  /// Whether [id] is a valid media id for this store.
  static bool isValidId(String id) => _idPattern.hasMatch(id);

  @override
  Future<MediaRef> put(
    Uint8List bytes, {
    required String mimeType,
    String? id,
  }) {
    return _synchronized(() async {
      if (mimeType.trim().isEmpty) {
        throw ArgumentError.value(mimeType, 'mimeType', 'must not be empty');
      }
      if (id != null) _validateId(id);

      final createdAt = _now().toUtc();
      final resolvedId = id ?? _generateId(createdAt);
      final ref = MediaRef(
        id: resolvedId,
        mimeType: mimeType,
        byteLength: bytes.length,
        createdAt: createdAt,
      );

      final record = JSObject();
      record.setProperty('id'.toJS, resolvedId.toJS);
      record.setProperty('mimeType'.toJS, mimeType.toJS);
      record.setProperty('byteLength'.toJS, bytes.length.toJS);
      record.setProperty('createdAt'.toJS, createdAt.toIso8601String().toJS);
      record.setProperty('bytes'.toJS, bytes.toJS);

      final transaction = _database.transaction(
        objectStoreName.toJS,
        'readwrite',
      );
      final request = transaction
          .objectStore(objectStoreName)
          .put(record, resolvedId.toJS);
      await _run(transaction, request);
      return ref;
    });
  }

  @override
  Future<Uint8List?> get(String id) {
    return _synchronized(() async {
      _validateId(id);
      final transaction = _database.transaction(
        objectStoreName.toJS,
        'readonly',
      );
      final request = transaction.objectStore(objectStoreName).get(id.toJS);
      final result = await _run(transaction, request);
      if (result == null || !result.isA<JSObject>()) return null;

      final record = result as JSObject;
      final rawBytes = record.getProperty('bytes'.toJS);
      if (!rawBytes.isA<JSUint8Array>()) {
        throw StateError('Stored media record $id has no bytes.');
      }
      return Uint8List.fromList((rawBytes as JSUint8Array).toDart);
    });
  }

  @override
  Future<void> delete(String id) {
    return _synchronized(() async {
      _validateId(id);
      final transaction = _database.transaction(
        objectStoreName.toJS,
        'readwrite',
      );
      final request = transaction.objectStore(objectStoreName).delete(id.toJS);
      await _run(transaction, request);
    });
  }

  @override
  Future<List<MediaRef>> list() {
    return _synchronized(() async {
      final transaction = _database.transaction(
        objectStoreName.toJS,
        'readonly',
      );
      final request = transaction.objectStore(objectStoreName).getAll();
      final result = await _run(transaction, request);
      if (!result.isA<JSArray<JSAny?>>()) {
        throw StateError('IndexedDB returned an unexpected media list.');
      }

      final records = result as JSArray<JSAny?>;
      final refs = <MediaRef>[];
      for (final item in records.toDart) {
        if (!item.isA<JSObject>()) continue;
        refs.add(_refFromRecord(item as JSObject));
      }
      refs.sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
      return List<MediaRef>.unmodifiable(refs);
    });
  }

  @override
  Future<int> usageBytes() async {
    var total = 0;
    for (final ref in await list()) {
      total += ref.byteLength;
    }
    return total;
  }

  @override
  Future<void> clear() {
    return _synchronized(() async {
      final transaction = _database.transaction(
        objectStoreName.toJS,
        'readwrite',
      );
      final request = transaction.objectStore(objectStoreName).clear();
      await _run(transaction, request);
    });
  }

  /// Closes the IndexedDB connection. The store is unusable afterwards.
  void close() => _database.close();

  String _generateId(DateTime createdAt) =>
      'media-${createdAt.microsecondsSinceEpoch}-${_nextId++}';

  MediaRef _refFromRecord(JSObject record) {
    final id = _stringField(record, 'id');
    final mimeType = _stringField(record, 'mimeType');
    final createdAt = _stringField(record, 'createdAt');
    final byteLength = record.getProperty('byteLength'.toJS);
    if (!byteLength.isA<JSNumber>()) {
      throw StateError('Stored media record $id has no byteLength.');
    }

    return MediaRef(
      id: id,
      mimeType: mimeType,
      byteLength: (byteLength as JSNumber).toDartInt,
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
  }

  String _stringField(JSObject record, String name) {
    final value = record.getProperty(name.toJS);
    if (!value.isA<JSString>()) {
      throw StateError('Stored media record has no $name.');
    }
    return (value as JSString).toDart;
  }

  void _validateId(String id) {
    if (!isValidId(id)) {
      throw ArgumentError.value(
        id,
        'id',
        'must match [A-Za-z0-9_-]{1,64} and must not contain '
            'path separators',
      );
    }
  }

  Future<Object?> _run(
    web.IDBTransaction transaction,
    web.IDBRequest request,
  ) async {
    final transactionDone = _transactionDone(transaction);
    final requestDone = _requestResult(request);
    // Wait for both futures and attach listeners to both immediately, so a
    // failure in one does not become an unhandled asynchronous error.
    final values = await Future.wait<Object?>([
      requestDone.then<Object?>((value) => value),
      transactionDone.then<Object?>((_) => null),
    ]);
    return values.first;
  }

  Future<JSAny?> _requestResult(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.onsuccess = ((web.Event _) {
      if (!completer.isCompleted) completer.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(_indexedDbError('request', request.error));
      }
    }).toJS;
    return completer.future;
  }

  Future<void> _transactionDone(web.IDBTransaction transaction) {
    final completer = Completer<void>();
    transaction.oncomplete = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    transaction.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          _indexedDbError('transaction', transaction.error),
        );
      }
    }).toJS;
    transaction.onabort = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          _indexedDbError('transaction aborted', transaction.error),
        );
      }
    }).toJS;
    return completer.future;
  }

  static StateError _indexedDbError(String action, web.DOMException? error) {
    final message = error?.message;
    return StateError(
      message == null || message.isEmpty
          ? 'IndexedDB $action failed.'
          : 'IndexedDB $action failed: $message',
    );
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = Completer<T>();
    final release = Completer<void>();
    final previous = _tail;
    _tail = release.future;

    unawaited(
      previous.then((_) async {
        try {
          result.complete(await action());
        } catch (error, stackTrace) {
          result.completeError(error, stackTrace);
        } finally {
          release.complete();
        }
      }),
    );

    return result.future;
  }
}
