/// The manifest contract for human reference takes of the launch pieces.
///
/// The recordings themselves are human-owned and are not part of this
/// library. The app does not load or play them yet: decision 0010 keeps the
/// phrase player out of main navigation. This file defines the versioned
/// document, strict parsing, and the model only.
library;

/// Version of the reference-take manifest document.
const int referenceTakeSchemaVersion = 1;

/// The tempo variant of a reference take.
enum ReferenceTakeVariant {
  target('target'),
  slow('slow');

  const ReferenceTakeVariant(this.wireName);

  /// Stable value used in the manifest.
  final String wireName;

  static ReferenceTakeVariant? tryParse(String value) => switch (value) {
    'target' => ReferenceTakeVariant.target,
    'slow' => ReferenceTakeVariant.slow,
    _ => null,
  };
}

/// A strict parse failure with a stable code and the offending field path.
///
/// Codes start with `referenceTake.` so the CLI and tests can assert one
/// failure without matching a human-readable message.
class ReferenceTakeFormatException extends FormatException {
  const ReferenceTakeFormatException({
    required this.code,
    required this.path,
    required String message,
  }) : super(message);

  final String code;
  final String path;

  @override
  String toString() => 'FormatException: $message at $path';
}

/// One human performance of one phrase at one tempo.
///
/// [file] is a path relative to `assets/content/reference_takes/`, for example
/// `audio/ode-to-joy-p1-target.wav`. [recordedOn] is a date-only
/// string (`yyyy-MM-dd`); [consentId] is an opaque identifier linked to a
/// signed release held outside the repository. It is never a name.
class ReferenceTake {
  const ReferenceTake({
    required this.pieceId,
    required this.phraseId,
    required this.variant,
    required this.bpm,
    required this.file,
    required this.durationMs,
    required this.guitar,
    required this.microphone,
    required this.recordedOn,
    required this.consentId,
  });

  final String pieceId;
  final String phraseId;
  final ReferenceTakeVariant variant;
  final int bpm;
  final String file;
  final int durationMs;
  final String guitar;
  final String microphone;
  final String recordedOn;
  final String consentId;

  factory ReferenceTake.fromJsonAt(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final rawVariant = _readString(json, 'variant', path);
    final variant = ReferenceTakeVariant.tryParse(rawVariant);
    if (variant == null) {
      _reject(
        'referenceTake.invalidVariant',
        '$path.variant',
        'Unknown variant "$rawVariant"; expected "target" or "slow".',
      );
    }

    final recordedOn = _readString(json, 'recordedOn', path);
    _validateDate(recordedOn, '$path.recordedOn');

    return ReferenceTake(
      pieceId: _readString(json, 'pieceId', path),
      phraseId: _readString(json, 'phraseId', path),
      variant: variant,
      bpm: _readInt(json, 'bpm', path),
      file: _readString(json, 'file', path),
      durationMs: _readInt(json, 'durationMs', path),
      guitar: _readString(json, 'guitar', path),
      microphone: _readString(json, 'microphone', path),
      recordedOn: recordedOn,
      consentId: _readString(json, 'consentId', path),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pieceId': pieceId,
    'phraseId': phraseId,
    'variant': variant.wireName,
    'bpm': bpm,
    'file': file,
    'durationMs': durationMs,
    'guitar': guitar,
    'microphone': microphone,
    'recordedOn': recordedOn,
    'consentId': consentId,
  };
}

/// The versioned `assets/content/reference_takes/manifest.json` document.
///
/// Unknown fields are ignored for forward compatibility. Unknown enum values,
/// wrong types, a malformed date, and a future [referenceTakeSchemaVersion]
/// are rejected instead of guessed.
class ReferenceTakeManifest {
  ReferenceTakeManifest({required List<ReferenceTake> takes})
    : takes = List<ReferenceTake>.unmodifiable(takes);

  final List<ReferenceTake> takes;

  factory ReferenceTakeManifest.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion == null) {
      _reject(
        'referenceTake.schemaVersion',
        'schemaVersion',
        'Missing required field schemaVersion.',
      );
    }
    if (rawVersion is! num ||
        !rawVersion.isFinite ||
        rawVersion != rawVersion.roundToDouble()) {
      _reject(
        'referenceTake.schemaVersion',
        'schemaVersion',
        'Expected an integer schemaVersion.',
      );
    }
    final version = rawVersion.toInt();
    if (version > referenceTakeSchemaVersion) {
      _reject(
        'referenceTake.futureSchema',
        'schemaVersion',
        'Unsupported future reference-take schemaVersion $version; '
            'this build supports $referenceTakeSchemaVersion.',
      );
    }
    if (version != referenceTakeSchemaVersion) {
      _reject(
        'referenceTake.unsupportedSchema',
        'schemaVersion',
        'Unsupported reference-take schemaVersion $version; '
            'this build supports $referenceTakeSchemaVersion.',
      );
    }

    final rawTakes = json['takes'];
    if (rawTakes == null) {
      _reject(
        'referenceTake.invalidTakes',
        'takes',
        'Missing required list takes.',
      );
    }
    if (rawTakes is! List) {
      _reject('referenceTake.invalidTakes', 'takes', 'Expected a list.');
    }

    final takes = <ReferenceTake>[];
    for (var index = 0; index < rawTakes.length; index++) {
      final path = 'takes[$index]';
      final value = rawTakes[index];
      if (value is! Map) {
        _reject(
          'referenceTake.invalidTake',
          path,
          'Expected an object for each take.',
        );
      }
      final takeJson = value is Map<String, dynamic>
          ? value
          : Map<String, dynamic>.from(value);
      takes.add(ReferenceTake.fromJsonAt(takeJson, path: path));
    }

    return ReferenceTakeManifest(takes: takes);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': referenceTakeSchemaVersion,
    'takes': <Map<String, dynamic>>[for (final take in takes) take.toJson()],
  };
}

Never _reject(String code, String path, String message) =>
    throw ReferenceTakeFormatException(
      code: code,
      path: path,
      message: message,
    );

String _readString(Map<String, dynamic> json, String key, String path) {
  final fieldPath = '$path.$key';
  if (!json.containsKey(key) || json[key] == null) {
    _reject('referenceTake.missingField', fieldPath, 'Missing required field.');
  }
  final value = json[key];
  if (value is! String) {
    _reject('referenceTake.invalidType', fieldPath, 'Expected a string.');
  }
  return value;
}

int _readInt(Map<String, dynamic> json, String key, String path) {
  final fieldPath = '$path.$key';
  if (!json.containsKey(key) || json[key] == null) {
    _reject('referenceTake.missingField', fieldPath, 'Missing required field.');
  }
  final value = json[key];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  _reject('referenceTake.invalidType', fieldPath, 'Expected an integer.');
}

void _validateDate(String value, String path) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    _reject(
      'referenceTake.invalidDate',
      path,
      'Expected a date in yyyy-MM-dd form.',
    );
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    _reject('referenceTake.invalidDate', path, 'Not a real calendar date.');
  }
}
