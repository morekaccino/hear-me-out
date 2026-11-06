import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../retention/retention_event.dart';
import '../retention/retention_log.dart';

/// The persisted retention document: opt-in flag plus a bounded log.
class RetentionStoredData {
  const RetentionStoredData({required this.optIn, required this.log});

  final bool optIn;
  final RetentionLog log;
}

abstract class RetentionStore {
  /// Loads the local document. Implementations must return an opted-out,
  /// empty document instead of throwing when data is missing or corrupt.
  Future<RetentionStoredData> load();

  Future<void> save(RetentionStoredData data);

  Future<void> clear();
}

/// Stores the opt-in retention log under its own `shared_preferences` key.
///
/// This key is deliberately separate from progress. The document carries a
/// schema version so a future build can reject unknown data instead of
/// guessing. Corrupt data and future versions are ignored and replaced only
/// by an explicit save.
class SharedPreferencesRetentionStore implements RetentionStore {
  static const storageKey = 'hear_me_out_retention_v1';
  static const currentSchemaVersion = 1;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<RetentionStoredData> load() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return _fresh();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _fresh();
      final version = decoded['schemaVersion'];
      if (version is! num) return _fresh();
      final value = version.toInt();
      if (value < 1 || value > currentSchemaVersion) return _fresh();
      final installId = decoded['installId'];
      final optIn = decoded['optIn'];
      if (installId is! String || installId.isEmpty || optIn is! bool) {
        return _fresh();
      }

      final events = <RetentionEvent>[];
      final rawEvents = decoded['events'];
      if (rawEvents is List) {
        for (final rawEvent in rawEvents) {
          final event = RetentionEvent.tryFromJson(
            rawEvent,
            expectedInstallId: installId,
          );
          if (event != null) events.add(event);
        }
      }
      final trimmed = events.length > retentionEventLimit
          ? events.sublist(events.length - retentionEventLimit)
          : events;
      return RetentionStoredData(
        optIn: optIn,
        log: RetentionLog(installId: installId, events: trimmed),
      );
    } catch (_) {
      // A malformed document must never stop the app from opening.
      return _fresh();
    }
  }

  @override
  Future<void> save(RetentionStoredData data) async {
    final prefs = await _instance;
    await prefs.setString(
      storageKey,
      jsonEncode({
        'schemaVersion': currentSchemaVersion,
        'optIn': data.optIn,
        'installId': data.log.installId,
        'events': [for (final event in data.log.events) event.toJson()],
      }),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(storageKey);
  }

  RetentionStoredData _fresh() => RetentionStoredData(
    optIn: false,
    log: RetentionLog(installId: _newInstallId()),
  );

  /// A local pseudonymous id: 16 random bytes, never derived from hardware,
  /// an account, or an advertising id.
  String _newInstallId() {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      // Random.secure is unavailable on a few restricted runtimes. The id is
      // pseudonymous either way and is never used as a security secret.
      random = Random();
    }
    final buffer = StringBuffer();
    for (var index = 0; index < 16; index++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

final retentionStoreProvider = Provider<RetentionStore>(
  (ref) => SharedPreferencesRetentionStore(),
);
