import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning/progress.dart';

abstract class ProgressStore {
  Future<ProgressState?> load();

  Future<void> save(ProgressState progress);

  Future<void> clear();
}

class SharedPreferencesProgressStore implements ProgressStore {
  static const storageKey = 'hear_me_out_progress_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<ProgressState?> load() async {
    final prefs = await _instance;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ProgressState.fromJson(decoded);
    } catch (_) {
      return null;
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
  }
}

final progressStoreProvider = Provider<ProgressStore>(
  (ref) => SharedPreferencesProgressStore(),
);

String exportProgress(ProgressState progress) =>
    const JsonEncoder.withIndent('  ').convert(progress.toJson());

ProgressState? importProgress(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return ProgressState.fromJson(decoded);
  } catch (_) {
    return null;
  }
}
