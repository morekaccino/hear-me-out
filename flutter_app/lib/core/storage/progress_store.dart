import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning/progress.dart';
import 'progress_migrations.dart';

abstract class ProgressStore {
  Future<ProgressState?> load();

  Future<void> save(ProgressState progress);

  Future<void> clear();
}

class SharedPreferencesProgressStore implements ProgressStore {
  static const storageKey = 'hear_me_out_progress_v1';

  /// Recovery copy for a document this build cannot decode. It is deliberately
  /// separate from [storageKey] so a later fresh save cannot destroy a newer
  /// build's data.
  static const unreadableKey = 'hear_me_out_progress_unreadable';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<ProgressState?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    final progress = _decodeProgress(raw);
    if (progress != null) return progress;
    await _quarantine(prefs, raw);
    return null;
  }

  Future<void> _quarantine(SharedPreferences prefs, String raw) async {
    try {
      if (prefs.getString(unreadableKey) != raw) {
        await prefs.setString(unreadableKey, raw);
      }
    } catch (_) {
      // A best-effort recovery copy must not turn a failed load into a crash.
      // The original value stays at [storageKey] until an explicit save.
    }
  }

  @override
  Future<void> save(ProgressState progress) async {
    final prefs = await _instance;
    await prefs.setString(storageKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
    // Keep [unreadableKey]. An explicit reset should not discard the only copy
    // of a document written by a newer build.
  }
}

final progressStoreProvider = Provider<ProgressStore>(
  (ref) => SharedPreferencesProgressStore(),
);

String exportProgress(ProgressState progress) =>
    const JsonEncoder.withIndent('  ').convert(progress.toJson());

ProgressState? importProgress(String raw) => _decodeProgress(raw);

ProgressState? _decodeProgress(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final migration = migrateProgress(decoded);
    if (migration is MigrationFailure) return null;
    return ProgressState.fromJson((migration as MigrationSuccess).json);
  } catch (_) {
    return null;
  }
}
