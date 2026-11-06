import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'media_store.dart';

/// [MediaStore] backed by files in [directory].
///
/// Layout:
///
/// ```
/// <directory>/
///   index.json          metadata for every stored item
///   objects/<id>.bin    raw bytes
/// ```
///
/// A write is staged in a temporary file and renamed into place, so a failed
/// write cannot truncate the previous recording. The index is the source of
/// truth for metadata. An object file without an index entry is an orphan,
/// reported by [listOrphans] and removable with [removeOrphans].
///
/// The caller supplies [directory] (the app uses `path_provider`), so this file
/// does not depend on Flutter or platform plugins beyond `dart:io`.
class FileMediaStore implements MediaStore {
  FileMediaStore({required String directory, DateTime Function()? now})
    : _root = Directory(directory),
      _now = now ?? DateTime.now;

  /// Name of the metadata document inside [directory].
  static const String indexFileName = 'index.json';

  /// Name of the directory that holds object bytes.
  static const String objectDirectoryName = 'objects';

  /// Extension used for object byte files.
  static const String objectFileExtension = 'bin';

  /// Version of the metadata document written by this store.
  static const int indexSchemaVersion = 1;

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  // Device names that stay reserved on Windows even with an extension, plus
  // this store's own layout names.
  static const Set<String> _reservedIds = <String>{
    'aux',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'con',
    'index',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
    'nul',
    'objects',
    'prn',
  };

  final Directory _root;
  final DateTime Function() _now;
  final Map<String, MediaRef> _entries = <String, MediaRef>{};
  Future<void>? _loading;
  Future<void> _tail = Future<void>.value();
  bool _loaded = false;
  int _nextId = 1;

  /// Root directory supplied to the constructor.
  Directory get directory => _root;

  /// Whether [id] is a valid media id for this store.
  static bool isValidId(String id) {
    if (!_idPattern.hasMatch(id)) return false;
    return !_reservedIds.contains(id.toLowerCase());
  }

  @override
  Future<MediaRef> put(
    Uint8List bytes, {
    required String mimeType,
    String? id,
    String? pieceId,
    String? phraseId,
    int? durationMs,
    double? score,
    int? analysisVersion,
  }) {
    return _synchronized(() async {
      if (mimeType.trim().isEmpty) {
        throw ArgumentError.value(mimeType, 'mimeType', 'must not be empty');
      }
      if (id != null) _validateId(id);
      await _ensureLoaded();
      await _objects.create(recursive: true);

      final createdAt = _now().toUtc();
      final resolvedId = id ?? await _generateId(createdAt);
      final ref = MediaRef(
        id: resolvedId,
        mimeType: mimeType,
        byteLength: bytes.length,
        createdAt: createdAt,
        pieceId: pieceId,
        phraseId: phraseId,
        durationMs: durationMs,
        score: score,
        analysisVersion: analysisVersion,
      );
      final objectFile = _objectFile(resolvedId);
      final tempFile = File('${objectFile.path}.tmp');
      File? stagedIndex;

      try {
        await tempFile.writeAsBytes(bytes, flush: true);
        final nextEntries = Map<String, MediaRef>.of(_entries)
          ..[resolvedId] = ref;
        stagedIndex = await _stageIndex(nextEntries);
        await tempFile.rename(objectFile.path);
        await stagedIndex.rename(_indexFile.path);
        _entries[resolvedId] = ref;
      } catch (_) {
        await _deleteQuietly(tempFile);
        if (stagedIndex != null) await _deleteQuietly(stagedIndex);
        rethrow;
      }

      return ref;
    });
  }

  @override
  Future<Uint8List?> get(String id) {
    return _synchronized(() async {
      _validateId(id);
      await _ensureLoaded();
      if (!_entries.containsKey(id)) return null;

      final file = _objectFile(id);
      if (!await file.exists()) {
        _entries.remove(id);
        await _writeIndex(_entries);
        return null;
      }

      return file.readAsBytes();
    });
  }

  @override
  Future<void> delete(String id) {
    return _synchronized(() async {
      _validateId(id);
      await _ensureLoaded();

      final nextEntries = Map<String, MediaRef>.of(_entries)..remove(id);
      File? stagedIndex;
      if (nextEntries.length != _entries.length) {
        stagedIndex = await _stageIndex(nextEntries);
      }

      await _deleteQuietly(_objectFile(id));

      if (stagedIndex != null) {
        await stagedIndex.rename(_indexFile.path);
        _entries.remove(id);
      }
    });
  }

  @override
  Future<List<MediaRef>> list() {
    return _synchronized(() async {
      await _ensureLoaded();
      final refs = _entries.values.toList()
        ..sort((a, b) {
          final byTime = a.createdAt.compareTo(b.createdAt);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        });
      return List<MediaRef>.unmodifiable(refs);
    });
  }

  @override
  Future<int> usageBytes() {
    return _synchronized(() async {
      await _ensureLoaded();
      var total = 0;
      for (final ref in _entries.values) {
        total += ref.byteLength;
      }
      return total;
    });
  }

  @override
  Future<void> clear() {
    return _synchronized(() async {
      await _ensureLoaded();
      await _deleteQuietly(_indexFile);
      await _deleteQuietly(File('${_indexFile.path}.tmp'));

      if (await _objects.exists()) {
        await for (final entity in _objects.list(followLinks: false)) {
          await _deleteEntityQuietly(entity);
        }
      }

      _entries.clear();
    });
  }

  /// Returns ids for object files that have no index entry.
  ///
  /// Temporary and unknown files are not reported here; [removeOrphans]
  /// removes them too.
  Future<List<String>> listOrphans() {
    return _synchronized(() async {
      await _ensureLoaded();
      if (!await _objects.exists()) {
        return const <String>[];
      }

      final suffix = '.$objectFileExtension';
      final orphans = <String>[];
      await for (final entity in _objects.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = _fileName(entity);
        if (!name.endsWith(suffix)) continue;
        final id = name.substring(0, name.length - suffix.length);
        if (!_entries.containsKey(id)) orphans.add(id);
      }
      orphans.sort();
      return List<String>.unmodifiable(orphans);
    });
  }

  /// Deletes every object file that has no index entry, plus stale temporary
  /// and unknown files. Returns the number of removed files.
  Future<int> removeOrphans() {
    return _synchronized(() async {
      await _ensureLoaded();
      if (!await _objects.exists()) return 0;

      final suffix = '.$objectFileExtension';
      var removed = 0;
      await for (final entity in _objects.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = _fileName(entity);
        final isKnownObject =
            name.endsWith(suffix) &&
            _entries.containsKey(
              name.substring(0, name.length - suffix.length),
            );
        if (!isKnownObject) {
          await _deleteEntityQuietly(entity);
          removed++;
        }
      }
      return removed;
    });
  }

  Directory get _objects =>
      Directory('${_root.path}${Platform.pathSeparator}$objectDirectoryName');

  File get _indexFile =>
      File('${_root.path}${Platform.pathSeparator}$indexFileName');

  File _objectFile(String id) =>
      File('${_objects.path}${Platform.pathSeparator}$id.$objectFileExtension');

  String _fileName(File file) => file.path.split(Platform.pathSeparator).last;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      await (_loading ??= _load());
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  Future<void> _load() async {
    await _root.create(recursive: true);
    await _objects.create(recursive: true);
    _entries.clear();

    final indexFile = _indexFile;
    if (!await indexFile.exists()) {
      _loaded = true;
      return;
    }

    final source = await indexFile.readAsString();
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException(
        'Media index ${indexFile.path} is not valid JSON: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Media index ${indexFile.path} must be a JSON object',
      );
    }
    final version = decoded['schemaVersion'];
    if (version != indexSchemaVersion) {
      throw FormatException(
        'Unsupported media index schemaVersion $version; '
        'expected $indexSchemaVersion',
      );
    }
    final items = decoded['items'];
    if (items is! Map<String, dynamic>) {
      throw FormatException(
        'Media index ${indexFile.path} must have an items object',
      );
    }

    var changed = false;
    for (final entry in items.entries) {
      final id = entry.key;
      final value = entry.value;
      if (!isValidId(id) || value is! Map<String, dynamic>) {
        changed = true;
        continue;
      }

      final mimeType = value['mimeType'];
      final byteLength = value['byteLength'];
      final createdAt = value['createdAt'];
      if (mimeType is! String ||
          mimeType.trim().isEmpty ||
          byteLength is! int ||
          byteLength < 0 ||
          createdAt is! String) {
        changed = true;
        continue;
      }

      final DateTime parsedAt;
      try {
        parsedAt = DateTime.parse(createdAt).toUtc();
      } on FormatException {
        changed = true;
        continue;
      }

      String? pieceId;
      String? phraseId;
      int? durationMs;
      double? score;
      int? analysisVersion;
      try {
        pieceId = _optionalString(value, 'pieceId');
        phraseId = _optionalString(value, 'phraseId');
        durationMs = _optionalInt(value, 'durationMs');
        score = _optionalScore(value, 'score');
        analysisVersion = _optionalInt(value, 'analysisVersion');
      } on FormatException {
        changed = true;
        continue;
      }

      final file = _objectFile(id);
      if (!await file.exists()) {
        changed = true;
        continue;
      }

      final actualLength = await file.length();
      if (actualLength != byteLength) changed = true;
      _entries[id] = MediaRef(
        id: id,
        mimeType: mimeType,
        byteLength: actualLength,
        createdAt: parsedAt,
        pieceId: pieceId,
        phraseId: phraseId,
        durationMs: durationMs,
        score: score,
        analysisVersion: analysisVersion,
      );
    }

    if (changed) await _writeIndex(_entries);
    _loaded = true;
  }

  Future<String> _generateId(DateTime createdAt) async {
    while (true) {
      final candidate =
          'media-${createdAt.microsecondsSinceEpoch}-${_nextId++}';
      if (!_entries.containsKey(candidate) &&
          !await _objectFile(candidate).exists()) {
        return candidate;
      }
    }
  }

  String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw FormatException('$key must be a non-negative integer');
    }
    return value;
  }

  double? _optionalScore(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num || value.isNaN || value.isInfinite) {
      throw FormatException('$key must be a finite number');
    }
    return value.toDouble();
  }

  Future<File> _stageIndex(Map<String, MediaRef> entries) async {
    final ids = entries.keys.toList()..sort();
    final items = <String, Object?>{};
    for (final id in ids) {
      final ref = entries[id]!;
      items[id] = <String, Object?>{
        'mimeType': ref.mimeType,
        'byteLength': ref.byteLength,
        'createdAt': ref.createdAt.toUtc().toIso8601String(),
        if (ref.pieceId != null) 'pieceId': ref.pieceId,
        if (ref.phraseId != null) 'phraseId': ref.phraseId,
        if (ref.durationMs != null) 'durationMs': ref.durationMs,
        if (ref.score != null) 'score': ref.score,
        if (ref.analysisVersion != null) 'analysisVersion': ref.analysisVersion,
      };
    }

    final temp = File('${_indexFile.path}.tmp');
    await temp.parent.create(recursive: true);
    await temp.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': indexSchemaVersion,
        'items': items,
      }),
      flush: true,
    );
    return temp;
  }

  Future<void> _writeIndex(Map<String, MediaRef> entries) async {
    final temp = await _stageIndex(entries);
    try {
      await temp.rename(_indexFile.path);
    } catch (_) {
      await _deleteQuietly(temp);
      rethrow;
    }
  }

  void _validateId(String id) {
    if (!isValidId(id)) {
      throw ArgumentError.value(
        id,
        'id',
        'must match [A-Za-z0-9_-]{1,64}, not be a reserved name, '
            'and must not contain path separators',
      );
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A failed cleanup must not hide the original error.
    }
  }

  Future<void> _deleteEntityQuietly(FileSystemEntity entity) async {
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // Best-effort cleanup; orphans will be reported again on the next call.
    }
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
