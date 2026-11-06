import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning/placement.dart';

abstract class PlacementStore {
  Future<PlacementRecord?> load();

  Future<void> save(PlacementRecord record);

  Future<void> clear();
}

/// Stores the placement result under its own versioned key.
///
/// This is deliberately not part of `hear_me_out_progress_v1`. Saving or
/// clearing a placement must never touch completed lessons, note boxes, XP,
/// minutes, streak, or phrase evidence. Corrupt or future data is ignored so
/// the app can always start at the normal course path.
class SharedPreferencesPlacementStore implements PlacementStore {
  static const storageKey = 'hear_me_out_placement_v1';
  static const currentSchemaVersion = 1;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<PlacementRecord?> load() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final version = decoded['schemaVersion'];
      if (version is! num) return null;
      final value = version.toInt();
      if (value < 1 || value > currentSchemaVersion) return null;
      return PlacementRecord.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(PlacementRecord record) async {
    final prefs = await _instance;
    await prefs.setString(
      storageKey,
      jsonEncode({'schemaVersion': currentSchemaVersion, ...record.toJson()}),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
  }
}

final placementStoreProvider = Provider<PlacementStore>(
  (ref) => SharedPreferencesPlacementStore(),
);
