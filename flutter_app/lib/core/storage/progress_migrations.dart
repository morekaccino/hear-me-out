/// Pure, versioned migrations for the persisted progress document.
///
/// The pipeline performs no IO, reads no clock, and uses no randomness. Every
/// step takes a map and returns a new map, so [migrateProgress] never mutates
/// its input. A document that cannot be migrated returns a [MigrationFailure]
/// instead of a partially migrated map; callers must not save on failure.
library;

/// The schema version this build reads and writes.
const int latestProgressSchemaVersion = 5;

/// The oldest schema version the pipeline can migrate.
const int oldestProgressSchemaVersion = 1;

/// The result of [migrateProgress].
sealed class MigrationResult {
  const MigrationResult();
}

final class MigrationSuccess extends MigrationResult {
  const MigrationSuccess(this.json);

  /// A new, fully migrated document at [latestProgressSchemaVersion].
  final Map<String, dynamic> json;
}

final class MigrationFailure extends MigrationResult {
  const MigrationFailure(this.reason);

  /// A human-readable explanation for diagnostics and tests.
  final String reason;
}

/// The version of a decoded document, or null when `schemaVersion` is absent
/// or not an integer.
int? progressSchemaVersion(Map<String, dynamic> json) {
  final raw = json['schemaVersion'];
  if (raw is int) return raw;
  if (raw is num && raw.isFinite && raw == raw.roundToDouble()) {
    return raw.toInt();
  }
  return null;
}

/// Migrates a decoded progress document to [latestProgressSchemaVersion].
///
/// Versions below 1, above [latestProgressSchemaVersion], and documents with a
/// missing or non-integer `schemaVersion` return [MigrationFailure].
MigrationResult migrateProgress(Map<String, dynamic> json) {
  final version = progressSchemaVersion(json);
  if (version == null) {
    return const MigrationFailure('schemaVersion must be an integer');
  }
  if (version < oldestProgressSchemaVersion) {
    return MigrationFailure(
      'schemaVersion $version is older than the supported minimum '
      '($oldestProgressSchemaVersion)',
    );
  }
  if (version > latestProgressSchemaVersion) {
    return MigrationFailure(
      'schemaVersion $version is newer than supported '
      '($latestProgressSchemaVersion)',
    );
  }

  var migrated = _copyMap(json);
  try {
    // A schema-vN document contains the shape introduced by version N, so a
    // step runs when the source is below the version that step introduces.
    if (version <= 1) migrated = _v1ToV2(migrated);
    if (version <= 2) migrated = _v2ToV3(migrated);
    if (version <= 3) migrated = _v3ToV4(migrated);
    if (version <= 4) migrated = _v4ToV5(migrated);
    _validateCurrent(migrated);
  } on FormatException catch (error) {
    return MigrationFailure(error.message);
  }
  return MigrationSuccess(migrated);
}

/// v1 → v2: add the default economy.
///
/// These are historical defaults, deliberately frozen here. A future change to
/// `startingGems` or `maxHearts` must not rewrite what an old v1 document
/// receives.
Map<String, dynamic> _v1ToV2(Map<String, dynamic> json) {
  final out = _copyMap(json);
  out['gems'] = _readInt(out, 'gems', 500, path: 'progress.gems');
  out['hearts'] = _readInt(out, 'hearts', 5, path: 'progress.hearts');
  out['streakFreezes'] = _readInt(
    out,
    'streakFreezes',
    0,
    path: 'progress.streakFreezes',
  );
  _ensureList(out, 'openedChests');
  _ensureList(out, 'claimedQuests');
  if (out['daily'] == null) {
    out['daily'] = <String, dynamic>{
      'day': null,
      'lessons': 0,
      'correct': 0,
      'practice': 0,
      'bestCombo': 0,
    };
  }
  out['schemaVersion'] = 2;
  return out;
}

/// v2 → v3: add the System appearance and the remaining settings defaults.
Map<String, dynamic> _v2ToV3(Map<String, dynamic> json) {
  final out = _copyMap(json);
  _applySettingsDefaults(out);
  out['schemaVersion'] = 3;
  return out;
}

/// v3 → v4: rebuild skill cards from the legacy note boxes when no skill cards
/// exist yet. Note progress itself is kept for the note chips.
Map<String, dynamic> _v3ToV4(Map<String, dynamic> json) {
  final out = _copyMap(json);
  _migrateNoteSkills(out);
  out['schemaVersion'] = 4;
  return out;
}

/// v4 → v5: add content versioning and the phrase-progress map.
Map<String, dynamic> _v4ToV5(Map<String, dynamic> json) {
  final out = _copyMap(json);
  _applySettingsDefaults(out);
  out['contentVersion'] = _readInt(
    out,
    'contentVersion',
    1,
    path: 'progress.contentVersion',
  );
  final phraseProgress = out['phraseProgress'];
  if (phraseProgress == null) {
    out['phraseProgress'] = <String, dynamic>{};
  } else {
    out['phraseProgress'] = _readStringMap(
      phraseProgress,
      'progress.phraseProgress',
    );
  }
  // Current v4 documents normally already have skills, but a profile written
  // by an older build may not. Keep the old defensive migration so no note
  // progress is stranded.
  _migrateNoteSkills(out);
  out['schemaVersion'] = 5;
  return out;
}

void _applySettingsDefaults(Map<String, dynamic> json) {
  final settings = _readStringMap(json['settings'], 'progress.settings');
  _defaultValue(settings, 'answerMode', 'mixed');
  _defaultValue(settings, 'toleranceCents', 30);
  _defaultValue(settings, 'a4Hz', 440);
  _defaultValue(settings, 'haptics', true);
  _defaultValue(settings, 'soundEffects', true);
  _defaultValue(settings, 'dailyGoalXp', 20);
  _defaultValue(settings, 'onboardingComplete', false);
  _defaultValue(settings, 'themeMode', 'system');
  json['settings'] = settings;
}

void _migrateNoteSkills(Map<String, dynamic> json) {
  final skills = json['skills'] == null
      ? <String, dynamic>{}
      : _readStringMap(json['skills'], 'progress.skills');
  if (skills.isEmpty) {
    final notes = json['notes'] == null
        ? <String, dynamic>{}
        : _readStringMap(json['notes'], 'progress.notes');
    for (final entry in notes.entries) {
      final note = _readStringMap(entry.value, 'progress.notes.${entry.key}');
      skills['note:${entry.key}'] = _skillFromNote(entry.key, note);
    }
  }
  json['skills'] = skills;
}

Map<String, dynamic> _skillFromNote(String noteId, Map<String, dynamic> note) {
  final path = 'progress.notes.$noteId';
  final box = _readInt(note, 'box', 0, path: '$path.box');
  final correct = _readInt(note, 'correct', 0, path: '$path.correct');
  final incorrect = _readInt(note, 'incorrect', 0, path: '$path.incorrect');
  final attempts = correct + incorrect;
  final accuracy = attempts == 0 ? 0.0 : correct / attempts;
  final stability = switch (box) {
    0 => 0.5,
    1 => 1.0,
    2 => 3.0,
    3 => 7.0,
    4 => 21.0,
    5 => 45.0,
    _ => 0.5,
  };
  final difficulty = (10 - accuracy * 8).clamp(1.0, 10.0);
  return <String, dynamic>{
    'objectiveId': 'note:$noteId',
    'family': 'noteReading',
    'stabilityDays': stability,
    'difficulty': difficulty,
    'dueAt': note['dueAt'],
    'lastSeenAt': note['lastSeenAt'],
    'reps': attempts,
    'lapses': incorrect,
    'correct': correct,
    'incorrect': incorrect,
    'correctDays': _readStringList(note['correctDays'], '$path.correctDays'),
    'productionCorrect': 0,
    'transferCorrect': 0,
    'averageResponseMs': 0,
    'level': 0,
    'fragile': false,
    'masteredAt': null,
    'recentTemplateIds': <String>[],
    'centsSamples': _readInt(
      note,
      'centsSamples',
      0,
      path: '$path.centsSamples',
    ),
    'centsTotal': _readDouble(note, 'centsTotal', 0, path: '$path.centsTotal'),
    'box': box,
    'streak': _readInt(note, 'streak', 0, path: '$path.streak'),
    'bestStreak': _readInt(note, 'bestStreak', 0, path: '$path.bestStreak'),
  };
}

void _validateCurrent(Map<String, dynamic> json) {
  final version = progressSchemaVersion(json);
  if (version != latestProgressSchemaVersion) {
    throw FormatException(
      'schemaVersion must be $latestProgressSchemaVersion after migration',
    );
  }

  if (json['settings'] != null) {
    _readStringMap(json['settings'], 'progress.settings');
  }

  if (json['notes'] != null) {
    final notes = _readStringMap(json['notes'], 'progress.notes');
    for (final entry in notes.entries) {
      final note = _readStringMap(entry.value, 'progress.notes.${entry.key}');
      _readInt(note, 'box', 0, path: 'progress.notes.${entry.key}.box');
    }
  }

  if (json['skills'] != null) {
    final skills = _readStringMap(json['skills'], 'progress.skills');
    for (final entry in skills.entries) {
      _readStringMap(entry.value, 'progress.skills.${entry.key}');
    }
  }

  if (json['contentVersion'] != null) {
    final contentVersion = _readInt(
      json,
      'contentVersion',
      1,
      path: 'progress.contentVersion',
    );
    if (contentVersion < 1) {
      throw const FormatException('progress.contentVersion must be at least 1');
    }
  }

  if (json['phraseProgress'] != null) {
    _validatePhraseProgress(json['phraseProgress']);
  }
}

void _validatePhraseProgress(Object? value) {
  final phrases = _readStringMap(value, 'progress.phraseProgress');
  for (final entry in phrases.entries) {
    final path = 'progress.phraseProgress.${entry.key}';
    final phrase = _readStringMap(entry.value, path);
    final storedId = phrase['phraseId'];
    if (storedId != null && storedId is! String) {
      throw FormatException('$path.phraseId must be a string');
    }
    _readInt(phrase, 'reps', 0, path: '$path.reps');
    _readInt(phrase, 'lapses', 0, path: '$path.lapses');
    _readInt(phrase, 'correct', 0, path: '$path.correct');
    _readInt(phrase, 'incorrect', 0, path: '$path.incorrect');
    _readDouble(phrase, 'stabilityDays', 0, path: '$path.stabilityDays');
    _readDouble(phrase, 'difficulty', 0, path: '$path.difficulty');
    _readStringList(phrase['correctDays'], '$path.correctDays');
    _readStringList(phrase['performanceDays'], '$path.performanceDays');
    if (phrase['bestTempoBpm'] != null) {
      _readInt(phrase, 'bestTempoBpm', 0, path: '$path.bestTempoBpm');
    }
    if (phrase['bestAccuracy'] != null) {
      _readDouble(phrase, 'bestAccuracy', 0, path: '$path.bestAccuracy');
    }
    for (final key in <String>[
      'dueAt',
      'firstPerformanceDay',
      'lastPerformanceAt',
    ]) {
      final field = phrase[key];
      if (field != null && field is! String) {
        throw FormatException('$path.$key must be a string');
      }
    }
  }
}

Map<String, dynamic> _copyMap(Map<String, dynamic> source) => <String, dynamic>{
  for (final entry in source.entries) entry.key: _copyValue(entry.value),
};

Object? _copyValue(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _copyValue(entry.value),
    };
  }
  if (value is List) {
    return <dynamic>[for (final item in value) _copyValue(item)];
  }
  return value;
}

Map<String, dynamic> _readStringMap(Object? value, String path) {
  if (value == null) return <String, dynamic>{};
  if (value is! Map) {
    throw FormatException('$path must be an object');
  }
  final out = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path must use string keys');
    }
    out[entry.key as String] = _copyValue(entry.value);
  }
  return out;
}

int _readInt(
  Map<String, dynamic> json,
  String key,
  int fallback, {
  required String path,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('$path must be an integer');
}

double _readDouble(
  Map<String, dynamic> json,
  String key,
  double fallback, {
  required String path,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('$path must be a number');
}

List<String> _readStringList(Object? value, String path) {
  if (value == null) return <String>[];
  if (value is! List) {
    throw FormatException('$path must be a list');
  }
  final out = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw FormatException('$path must contain only strings');
    }
    out.add(item);
  }
  return out;
}

void _ensureList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    json[key] = <dynamic>[];
    return;
  }
  if (value is! List) {
    throw FormatException('progress.$key must be a list');
  }
}

void _defaultValue(Map<String, dynamic> settings, String key, Object value) {
  if (settings[key] == null) settings[key] = value;
}
