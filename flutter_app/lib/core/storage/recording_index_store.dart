import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../media/recording_index.dart';
import '../media/recording_index_store.dart';

/// [RecordingIndexStore] backed by `shared_preferences`.
///
/// The index has its own key and schema version. It is not part of
/// `ProgressState` and is not included in the progress backup. A corrupt or
/// future document throws [FormatException] and is copied to [unreadableKey]
/// first; the caller must not delete media on that path.
class SharedPreferencesRecordingIndexStore implements RecordingIndexStore {
  static const String storageKey = 'hear_me_out_recordings_v1';

  /// Recovery copy for a document this build cannot decode. It is separate
  /// from [storageKey] so a recovery save cannot destroy a newer build's
  /// manifest.
  static const String unreadableKey = 'hear_me_out_recordings_unreadable';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<RecordingIndex?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Recording index must be a JSON object.');
      }
      return RecordingIndex.fromJson(decoded);
    } on FormatException {
      await _quarantine(prefs, raw);
      rethrow;
    }
  }

  Future<void> _quarantine(SharedPreferences prefs, String raw) async {
    try {
      if (prefs.getString(unreadableKey) != raw) {
        await prefs.setString(unreadableKey, raw);
      }
    } catch (_) {
      // A failed recovery copy must not hide the original decode error.
    }
  }

  @override
  Future<void> save(RecordingIndex index) async {
    final prefs = await _instance;
    await prefs.setString(storageKey, jsonEncode(index.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
    // Keep [unreadableKey]. An explicit clear must not discard the only copy
    // of a document written by a newer build.
  }
}
