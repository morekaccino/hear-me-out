/// Validates Hear Me Out assessment-corpus label files and manifests.
///
/// This is a pure-Dart tool. It imports only `dart:convert`, `dart:io`, and
/// `dart:math`, so it runs without Flutter:
///
///     dart run tool/corpus/validate_labels.dart test/fixtures/corpus/valid_labels.json
///
/// Exit codes: 0 = valid, 1 = validation errors, 2 = usage or I/O error.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const int labelSchemaVersion = 1;
const int manifestSchemaVersion = 1;

const List<String> platforms = ['android', 'ios', 'web'];
const List<String> conditions = ['quiet', 'room-noise', 'click', 'drone'];
const List<String> guitars = ['nylon', 'steel'];
const List<String> outcomes = ['correct', 'incorrect', 'indeterminate'];
const List<String> completenessValues = ['complete', 'incomplete'];
const List<String> playerSegments = ['returner', 'near-beginner'];
const List<String> playerGuitars = ['nylon', 'steel', 'both'];
const List<String> deviceClasses = [
  'mid-range-android',
  'iphone',
  'tablet',
  'laptop-web',
];
const Map<String, List<String>> deviceClassPlatforms = {
  'mid-range-android': ['android'],
  'iphone': ['ios'],
  'tablet': ['ios', 'android'],
  'laptop-web': ['web'],
};
const List<String> takeStatuses = ['accepted', 'failed', 'excluded'];
const List<int> phraseNoteCounts = [4, 8, 16];

/// Guitar sounds one octave below written pitch.
const int writtenToSoundingSemitones = -12;

/// Sounding MIDI pitch of each open string, 1 = high E.
const Map<int, int> openStringMidi = {
  1: 64, // E4
  2: 59, // B3
  3: 55, // G3
  4: 50, // D3
  5: 45, // A2
  6: 40, // E2
};

const int maxFret = 24;

const String _root = r'$';
const double _timeEpsilon = 1e-6;

const Set<String> _labelKeys = {
  'schemaVersion',
  'takeId',
  'playerId',
  'device',
  'platform',
  'condition',
  'guitar',
  'sampleRate',
  'channels',
  'tempoBpm',
  'phraseNoteCount',
  'target',
  'expert',
  'consent',
  'notes',
};

const Set<String> _targetKeys = {
  'index',
  'writtenNote',
  'soundingMidi',
  'string',
  'fret',
  'onsetSample',
  'onsetSeconds',
  'durationSeconds',
  'confidence',
};

const Set<String> _expertKeys = {
  'outcome',
  'noteAccuracy',
  'timingOk',
  'completeness',
  'labeler',
  'reviewedBy',
};

const Set<String> _consentKeys = {
  'audioCapture',
  'keepRawAudio',
  'anonymizedMetrics',
};

const Set<String> _manifestKeys = {
  'schemaVersion',
  'corpusId',
  'players',
  'devices',
  'takes',
  'notes',
};

const Set<String> _playerKeys = {
  'playerId',
  'segment',
  'guitar',
  'playingLevel',
};

const Set<String> _deviceKeys = {'device', 'platform', 'deviceClass'};

const Set<String> _manifestTakeKeys = {
  'takeId',
  'playerId',
  'device',
  'platform',
  'condition',
  'labelFile',
  'audioFile',
  'status',
  'notes',
};

class ValidationIssue {
  const ValidationIssue({required this.path, required this.message});

  final String path;
  final String message;

  Map<String, Object?> toJson() => {'path': path, 'message': message};

  @override
  String toString() => '$path: $message';
}

class ValidationReport {
  ValidationReport({required this.source, required this.kind});

  final String source;
  final String kind;
  String? takeId;
  final List<ValidationIssue> errors = [];
  final List<ValidationIssue> warnings = [];
  final Map<String, Object?> summary = {};

  bool get isValid => errors.isEmpty;
  int get errorCount => errors.length;
  int get warningCount => warnings.length;

  void addError(String path, String message) {
    errors.add(ValidationIssue(path: path, message: message));
  }

  void addWarning(String path, String message) {
    warnings.add(ValidationIssue(path: path, message: message));
  }

  Map<String, Object?> toJson() => {
    'file': source,
    'kind': kind,
    if (takeId != null) 'takeId': takeId,
    'valid': isValid,
    'errorCount': errorCount,
    'warningCount': warningCount,
    'errors': [for (final issue in errors) issue.toJson()],
    'warnings': [for (final issue in warnings) issue.toJson()],
    if (summary.isNotEmpty) 'summary': summary,
  };
}

/// Validates a decoded label JSON value. The value is normally the result of
/// `jsonDecode`; tests may also pass a map directly, including non-finite
/// doubles that JSON cannot represent.
ValidationReport validateLabel(Object? decoded, {String source = '<memory>'}) {
  final report = ValidationReport(source: source, kind: 'label');
  final json = _objectMap(decoded);
  if (json == null) {
    report.addError(_root, 'root must be a JSON object');
    return report;
  }
  _validateLabelInto(report, json);
  return report;
}

/// Validates a decoded manifest JSON value.
ValidationReport validateManifest(
  Object? decoded, {
  String source = '<memory>',
}) {
  final report = ValidationReport(source: source, kind: 'manifest');
  final json = _objectMap(decoded);
  if (json == null) {
    report.addError(_root, 'root must be a JSON object');
    return report;
  }
  _validateManifestInto(report, json);
  return report;
}

/// Adds manifest/label consistency errors to [labelReport].
///
/// The manifest is the collection index: every accepted label must appear in
/// it, and the player, device, platform, and condition must agree.
void crossCheckLabelAndManifest(
  Map<String, Object?> label,
  Map<String, Object?> manifest,
  ValidationReport labelReport,
) {
  final takes = manifest['takes'];
  if (takes is! List) return;
  final takeId = label['takeId'];
  if (takeId is! String) return;

  Map<String, Object?>? entry;
  for (final item in takes) {
    final map = _objectMap(item);
    if (map != null && map['takeId'] == takeId) {
      entry = map;
      break;
    }
  }
  if (entry == null) {
    labelReport.addError(
      r'$.takeId',
      'is not listed in the manifest; add the take before labelling',
    );
    return;
  }

  for (final field in const ['playerId', 'device', 'platform', 'condition']) {
    final labelValue = label[field];
    final manifestValue = entry[field];
    if (labelValue is String &&
        manifestValue is String &&
        labelValue != manifestValue) {
      labelReport.addError(
        '\$.$field',
        'label says "$labelValue" but the manifest says "$manifestValue"',
      );
    }
  }

  final players = manifest['players'];
  final playerId = entry['playerId'];
  if (players is List && playerId is String) {
    Map<String, Object?>? playerEntry;
    for (final item in players) {
      final map = _objectMap(item);
      if (map != null && map['playerId'] == playerId) {
        playerEntry = map;
        break;
      }
    }
    final registeredGuitar = playerEntry?['guitar'];
    final labelGuitar = label['guitar'];
    if (registeredGuitar is String &&
        labelGuitar is String &&
        registeredGuitar != 'both' &&
        registeredGuitar != labelGuitar) {
      labelReport.addError(
        r'$.guitar',
        'label says "$labelGuitar" but player $playerId is registered as '
            '"$registeredGuitar"',
      );
    }
  }

  final status = entry['status'];
  if (status is String && status != 'accepted') {
    labelReport.addWarning(
      r'$.takeId',
      'manifest status is "$status"; this take is not part of the scored corpus',
    );
  }
  if (status == 'failed') {
    final expert = _objectMap(label['expert']);
    if (expert != null) {
      if (expert['outcome'] != null && expert['outcome'] != 'indeterminate') {
        labelReport.addError(
          r'$.expert.outcome',
          'manifest status is "failed"; failed takes must be indeterminate',
        );
      }
      if (expert['completeness'] != null &&
          expert['completeness'] != 'incomplete') {
        labelReport.addError(
          r'$.expert.completeness',
          'manifest status is "failed"; failed takes must be incomplete',
        );
      }
    }
  }
}

void _validateLabelInto(ValidationReport report, Map<String, Object?> json) {
  _checkKeys(report, json, _labelKeys, _root);

  final version = _readInt(
    report,
    json,
    'schemaVersion',
    _root,
    min: 1,
    max: labelSchemaVersion,
  );
  if (version != null && version != labelSchemaVersion) {
    report.addError(
      '\$.schemaVersion',
      'unsupported label schema version $version; expected $labelSchemaVersion',
    );
  }

  final takeId = _readString(report, json, 'takeId', _root);
  report.takeId = takeId;
  if (takeId != null && !_takeIdPattern.hasMatch(takeId)) {
    report.addError(
      r'$.takeId',
      'must be a lowercase slug ending in a three-digit sequence, for example '
          'p01-pixel-6a-quiet-001',
    );
  }

  final playerId = _readString(report, json, 'playerId', _root);
  if (playerId != null && !_playerIdPattern.hasMatch(playerId)) {
    report.addError(
      r'$.playerId',
      'must use the recruited player id form p01 through p99',
    );
  }

  final device = _readString(report, json, 'device', _root);
  if (device != null && !_slugPattern.hasMatch(device)) {
    report.addError(
      r'$.device',
      'must be a lowercase slug such as pixel-6a or iphone-13',
    );
  }

  _readEnum(report, json, 'platform', _root, platforms);
  final condition = _readEnum(report, json, 'condition', _root, conditions);
  _readEnum(report, json, 'guitar', _root, guitars);

  final sampleRate = _readInt(
    report,
    json,
    'sampleRate',
    _root,
    min: 8000,
    max: 192000,
  );
  final channels = _readInt(report, json, 'channels', _root, min: 1, max: 2);
  if (channels != null && channels != 1 && channels != 2) {
    report.addError(r'$.channels', 'must be 1 (mono) or 2 (stereo)');
  }

  final tempoBpm = _readInt(report, json, 'tempoBpm', _root, min: 60, max: 90);
  if (tempoBpm != null && (tempoBpm < 60 || tempoBpm > 90)) {
    report.addError(
      r'$.tempoBpm',
      'must be between 60 and 90 BPM for this corpus; got $tempoBpm',
    );
  }

  final phraseNoteCount = _readInt(
    report,
    json,
    'phraseNoteCount',
    _root,
    min: 1,
  );
  if (phraseNoteCount != null && !phraseNoteCounts.contains(phraseNoteCount)) {
    report.addError(
      r'$.phraseNoteCount',
      'must be 4, 8, or 16 for this corpus; got $phraseNoteCount',
    );
  }

  if (takeId != null &&
      playerId != null &&
      device != null &&
      condition != null) {
    final expectedPrefix = '$playerId-$device-$condition-';
    if (!takeId.startsWith(expectedPrefix)) {
      report.addError(
        r'$.takeId',
        'must start with "$expectedPrefix"; take ids are '
            '<playerId>-<device>-<condition>-<NNN>',
      );
    }
  }

  final hasIndeterminateNote = _validateTarget(
    report,
    json,
    sampleRate,
    phraseNoteCount,
  );
  _validateExpert(report, json, hasIndeterminateNote: hasIndeterminateNote);
  _validateConsent(report, json);

  final notes = json['notes'];
  if (notes != null && notes is! String) {
    report.addError(r'$.notes', 'must be a string when present');
  }
}

bool _validateTarget(
  ValidationReport report,
  Map<String, Object?> json,
  int? sampleRate,
  int? phraseNoteCount,
) {
  final targetValue = _required(report, json, 'target', _root);
  if (targetValue == null) return false;
  if (targetValue is! List) {
    report.addError(r'$.target', 'must be a list of note events');
    return false;
  }
  if (targetValue.isEmpty) {
    report.addError(r'$.target', 'must contain at least one note event');
    return false;
  }

  var hasIndeterminateNote = false;
  var lowConfidenceCount = 0;
  final timedEvents = <_TimedEvent>[];
  for (var i = 0; i < targetValue.length; i++) {
    final path = '\$.target[$i]';
    final event = _objectMap(targetValue[i]);
    if (event == null) {
      report.addError(path, 'must be an object');
      continue;
    }
    _checkKeys(report, event, _targetKeys, path);

    final index = _readInt(report, event, 'index', path, min: 0);
    if (index != null && index != i) {
      report.addError(
        '$path.index',
        'must equal the list position $i; note events must be in performance '
            'order',
      );
    }

    final writtenValue = _readString(report, event, 'writtenNote', path);
    _WrittenNote? written;
    if (writtenValue != null) {
      written = _parseWrittenNote(writtenValue);
      if (written == null) {
        report.addError(
          '$path.writtenNote',
          'must be written pitch such as E4, F#4, or Bb3 (uppercase letter, '
              'optional # or b, octave)',
        );
      } else if (written.midi < 0 || written.midi > 127) {
        report.addError(
          '$path.writtenNote',
          'resolves to MIDI ${written.midi}, outside the MIDI range 0..127',
        );
      }
    }

    final soundingMidi = _readInt(
      report,
      event,
      'soundingMidi',
      path,
      min: 0,
      max: 127,
    );
    final string = _readInt(report, event, 'string', path, min: 1, max: 6);
    final fret = _readInt(report, event, 'fret', path, min: 0, max: maxFret);
    final onsetSample = _readInt(report, event, 'onsetSample', path, min: 0);
    final onsetSeconds = _readNumber(
      report,
      event,
      'onsetSeconds',
      path,
      min: 0,
    );
    final durationSeconds = _readNumber(
      report,
      event,
      'durationSeconds',
      path,
      min: 0,
      exclusiveMin: true,
    );
    final confidence = _readNumber(
      report,
      event,
      'confidence',
      path,
      min: 0,
      max: 1,
    );
    if (confidence != null && confidence < 0.6) {
      hasIndeterminateNote = true;
      lowConfidenceCount++;
      report.addWarning(
        '$path.confidence',
        'below 0.6; this note is indeterminate, so the take cannot pass',
      );
    }

    if (written != null &&
        written.midi >= 0 &&
        written.midi <= 127 &&
        soundingMidi != null) {
      final expected = written.midi + writtenToSoundingSemitones;
      if (soundingMidi != expected) {
        report.addError(
          '$path.soundingMidi',
          'does not match written ${written.text}: guitar sounds one octave '
              'below written pitch, so expected $expected but got $soundingMidi',
        );
      }
    }

    final openMidi = string == null ? null : openStringMidi[string];
    if (openMidi != null && fret != null && soundingMidi != null) {
      final expected = openMidi + fret;
      if (expected != soundingMidi) {
        report.addError(
          '$path.soundingMidi',
          'string $string fret $fret sounds MIDI $expected, but the label says '
              '$soundingMidi',
        );
      }
    }
    if (written != null && openMidi != null && fret != null) {
      final expectedWritten = openMidi + fret + 12;
      if (written.midi != expectedWritten) {
        report.addError(
          '$path.writtenNote',
          'string $string fret $fret is written MIDI $expectedWritten, but the '
              'label says ${written.text} (MIDI ${written.midi})',
        );
      }
    }

    if (sampleRate != null && onsetSample != null && onsetSeconds != null) {
      final expected = onsetSample / sampleRate;
      final tolerance = math.max(0.0015, 1 / sampleRate);
      if ((expected - onsetSeconds).abs() > tolerance) {
        report.addError(
          '$path.onsetSeconds',
          'does not match onsetSample $onsetSample at $sampleRate Hz; expected '
              '${expected.toStringAsFixed(6)} s but got $onsetSeconds s',
        );
      }
    }

    if (onsetSeconds != null && durationSeconds != null) {
      timedEvents.add(
        _TimedEvent(
          index: i,
          onset: onsetSeconds,
          end: onsetSeconds + durationSeconds,
        ),
      );
    }
  }

  for (var i = 1; i < timedEvents.length; i++) {
    final previous = timedEvents[i - 1];
    final current = timedEvents[i];
    final path = '\$.target[${current.index}].onsetSeconds';
    if (current.onset < previous.onset) {
      report.addError(
        path,
        'target events must be ordered by onset; previous onset is '
        '${previous.onset} s',
      );
    }
    if (current.onset + _timeEpsilon < previous.end) {
      report.addError(
        path,
        'overlaps target[${previous.index}]: onset ${current.onset} s is before '
        'the previous event ends at ${previous.end} s',
      );
    }
  }

  if (phraseNoteCount != null && phraseNoteCount != targetValue.length) {
    report.addError(
      r'$.phraseNoteCount',
      'is $phraseNoteCount but target has ${targetValue.length} events',
    );
  }
  if (lowConfidenceCount > targetValue.length * 0.2) {
    report.addWarning(
      r'$.target',
      'more than 20% of target notes are below 0.6 confidence; the take is '
          'unusable and must be retried',
    );
  }
  return hasIndeterminateNote;
}

void _validateExpert(
  ValidationReport report,
  Map<String, Object?> json, {
  required bool hasIndeterminateNote,
}) {
  final expertValue = _required(report, json, 'expert', _root);
  if (expertValue == null) return;
  final expert = _objectMap(expertValue);
  if (expert == null) {
    report.addError(r'$.expert', 'must be an object');
    return;
  }
  _checkKeys(report, expert, _expertKeys, r'$.expert');

  final outcome = _readEnum(report, expert, 'outcome', r'$.expert', outcomes);
  final noteAccuracy = _readNumber(
    report,
    expert,
    'noteAccuracy',
    r'$.expert',
    min: 0,
    max: 1,
  );
  final timingOk = _readBool(report, expert, 'timingOk', r'$.expert');
  final completeness = _readEnum(
    report,
    expert,
    'completeness',
    r'$.expert',
    completenessValues,
  );
  final labeler = _readString(report, expert, 'labeler', r'$.expert');
  final reviewedBy = _readString(report, expert, 'reviewedBy', r'$.expert');

  if (labeler != null && reviewedBy != null && labeler == reviewedBy) {
    report.addError(
      r'$.expert.reviewedBy',
      'must differ from labeler; every take needs an independent review',
    );
  }

  if (hasIndeterminateNote) {
    if (completeness != null && completeness != 'incomplete') {
      report.addError(
        r'$.expert.completeness',
        'must be incomplete because at least one target note has confidence '
            'below 0.6',
      );
    }
    if (outcome != null && outcome != 'indeterminate') {
      report.addError(
        r'$.expert.outcome',
        'must be indeterminate because at least one target note has confidence '
            'below 0.6',
      );
    }
  }

  if (outcome == 'correct') {
    if (completeness != null && completeness != 'complete') {
      report.addError(
        r'$.expert.completeness',
        'cannot be incomplete when outcome is correct',
      );
    }
    if (timingOk == false) {
      report.addError(
        r'$.expert.timingOk',
        'must be true when outcome is correct',
      );
    }
    if (noteAccuracy != null && noteAccuracy < 0.85 - 1e-9) {
      report.addError(
        r'$.expert.noteAccuracy',
        'must be at least 0.85 for a correct outcome (practice-pass rule); got '
            '$noteAccuracy',
      );
    }
  }

  if (outcome == 'incorrect' && completeness == 'incomplete') {
    report.addError(
      r'$.expert.outcome',
      'incomplete takes are indeterminate, not incorrect; use indeterminate '
          'so the app can offer a retry',
    );
  }
}

void _validateConsent(ValidationReport report, Map<String, Object?> json) {
  final consentValue = _required(report, json, 'consent', _root);
  if (consentValue == null) return;
  final consent = _objectMap(consentValue);
  if (consent == null) {
    report.addError(r'$.consent', 'must be an object');
    return;
  }
  _checkKeys(report, consent, _consentKeys, r'$.consent');

  final audioCapture = _readBool(report, consent, 'audioCapture', r'$.consent');
  final keepRawAudio = _readBool(report, consent, 'keepRawAudio', r'$.consent');
  final anonymizedMetrics = _readBool(
    report,
    consent,
    'anonymizedMetrics',
    r'$.consent',
  );

  if (keepRawAudio == true && audioCapture == false) {
    report.addError(
      r'$.consent.keepRawAudio',
      'cannot be true when audioCapture is false',
    );
  }
  if (audioCapture == false) {
    report.addWarning(
      r'$.consent.audioCapture',
      'audio capture is not consented; this take must not contain audio',
    );
  }
  if (anonymizedMetrics == false) {
    report.addWarning(
      r'$.consent.anonymizedMetrics',
      'anonymized metrics are not consented; exclude this take from aggregate '
          'reports',
    );
  }
}

void _validateManifestInto(ValidationReport report, Map<String, Object?> json) {
  _checkKeys(report, json, _manifestKeys, _root);

  final version = _readInt(
    report,
    json,
    'schemaVersion',
    _root,
    min: 1,
    max: manifestSchemaVersion,
  );
  if (version != null && version != manifestSchemaVersion) {
    report.addError(
      r'$.schemaVersion',
      'unsupported manifest schema version $version; expected '
          '$manifestSchemaVersion',
    );
  }

  final corpusId = _readString(report, json, 'corpusId', _root);
  if (corpusId != null && !_slugPattern.hasMatch(corpusId)) {
    report.addError(
      r'$.corpusId',
      'must be a lowercase slug such as spike-2026-11',
    );
  }

  final players = _validatePlayers(report, json);
  final devices = _validateDevices(report, json);
  final takes = _validateManifestTakes(report, json, players, devices);

  final playerLevels = <int>{};
  final playerGuitars = <String>{};
  var returnerCount = 0;
  var nearBeginnerCount = 0;
  for (final player in players.values) {
    final level = player['playingLevel'];
    if (level is int) {
      playerLevels.add(level);
    } else if (level is double &&
        level.isFinite &&
        level == level.roundToDouble()) {
      playerLevels.add(level.toInt());
    }
    final guitar = player['guitar'];
    if (guitar == 'nylon' || guitar == 'steel') {
      playerGuitars.add(guitar as String);
    } else if (guitar == 'both') {
      playerGuitars.addAll(const ['nylon', 'steel']);
    }
    switch (player['segment']) {
      case 'returner':
        returnerCount++;
      case 'near-beginner':
        nearBeginnerCount++;
    }
  }

  final deviceClassSet = <String>{};
  for (final device in devices.values) {
    final deviceClass = device['deviceClass'];
    if (deviceClass is String) deviceClassSet.add(deviceClass);
  }

  final acceptedTakes = takes
      .where((take) => take['status'] == 'accepted')
      .toList(growable: false);
  final cells = <String, int>{};
  for (final deviceClass in deviceClasses) {
    for (final bucket in const ['quiet', 'room-noise', 'click-drone']) {
      cells['$deviceClass/$bucket'] = 0;
    }
  }
  for (final take in acceptedTakes) {
    final device = devices[take['device']];
    final deviceClass = device?['deviceClass'];
    final condition = take['condition'];
    if (deviceClass is String && condition is String) {
      final key = '$deviceClass/${_conditionBucket(condition)}';
      cells[key] = (cells[key] ?? 0) + 1;
    }
  }

  report.summary.addAll({
    'playerCount': players.length,
    'deviceCount': devices.length,
    'takeCount': takes.length,
    'acceptedTakeCount': acceptedTakes.length,
    'cells': {
      for (final entry
          in cells.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        entry.key: entry.value,
    },
  });

  if (players.length < 6 || players.length > 10) {
    report.addWarning(
      r'$.players',
      'the spike needs 6 to 10 players; this manifest has ${players.length}',
    );
  }
  if (returnerCount < 3) {
    report.addWarning(
      r'$.players',
      'the spike needs at least 3 returners; this manifest has $returnerCount',
    );
  }
  if (nearBeginnerCount < 3) {
    report.addWarning(
      r'$.players',
      'the spike needs at least 3 near-beginners; this manifest has '
          '$nearBeginnerCount',
    );
  }
  if (playerGuitars.length < 2) {
    report.addWarning(
      r'$.players',
      'the spike needs nylon and steel guitars; this manifest has '
          '${playerGuitars.isEmpty ? 'none' : playerGuitars.join(', ')}',
    );
  }
  if (playerLevels.length < 3) {
    report.addWarning(
      r'$.players',
      'the spike needs at least 3 playing levels; this manifest has '
          '${playerLevels.length}',
    );
  }
  if (deviceClassSet.length < deviceClasses.length) {
    final missing = deviceClasses
        .where((deviceClass) => !deviceClassSet.contains(deviceClass))
        .join(', ');
    report.addWarning(
      r'$.devices',
      'the spike needs all four device classes; missing: $missing',
    );
  }
  for (final entry in cells.entries) {
    if (entry.value < 20) {
      report.addWarning(
        r'$.takes',
        'cell ${entry.key} has ${entry.value} accepted takes; the protocol '
            'needs at least 20',
      );
    }
  }

  final notes = json['notes'];
  if (notes != null && notes is! String) {
    report.addError(r'$.notes', 'must be a string when present');
  }
}

Map<String, Map<String, Object?>> _validatePlayers(
  ValidationReport report,
  Map<String, Object?> json,
) {
  final result = <String, Map<String, Object?>>{};
  final value = _required(report, json, 'players', _root);
  if (value == null) return result;
  if (value is! List) {
    report.addError(r'$.players', 'must be a list');
    return result;
  }

  final seen = <String>{};
  for (var i = 0; i < value.length; i++) {
    final path = '\$.players[$i]';
    final player = _objectMap(value[i]);
    if (player == null) {
      report.addError(path, 'must be an object');
      continue;
    }
    _checkKeys(report, player, _playerKeys, path);

    final playerId = _readString(report, player, 'playerId', path);
    if (playerId != null) {
      if (!_playerIdPattern.hasMatch(playerId)) {
        report.addError(
          '$path.playerId',
          'must use the recruited player id form p01 through p99',
        );
      } else if (!seen.add(playerId)) {
        report.addError('$path.playerId', 'duplicate player id "$playerId"');
      } else {
        result[playerId] = player;
      }
    }

    _readEnum(report, player, 'segment', path, playerSegments);
    _readEnum(report, player, 'guitar', path, playerGuitars);
    _readInt(report, player, 'playingLevel', path, min: 1, max: 5);
  }
  return result;
}

Map<String, Map<String, Object?>> _validateDevices(
  ValidationReport report,
  Map<String, Object?> json,
) {
  final result = <String, Map<String, Object?>>{};
  final value = _required(report, json, 'devices', _root);
  if (value == null) return result;
  if (value is! List) {
    report.addError(r'$.devices', 'must be a list');
    return result;
  }

  final seen = <String>{};
  for (var i = 0; i < value.length; i++) {
    final path = '\$.devices[$i]';
    final device = _objectMap(value[i]);
    if (device == null) {
      report.addError(path, 'must be an object');
      continue;
    }
    _checkKeys(report, device, _deviceKeys, path);

    final deviceId = _readString(report, device, 'device', path);
    if (deviceId != null) {
      if (!_slugPattern.hasMatch(deviceId)) {
        report.addError(
          '$path.device',
          'must be a lowercase slug such as pixel-6a or iphone-13',
        );
      } else if (!seen.add(deviceId)) {
        report.addError('$path.device', 'duplicate device "$deviceId"');
      } else {
        result[deviceId] = device;
      }
    }

    final platform = _readEnum(report, device, 'platform', path, platforms);
    final deviceClass = _readEnum(
      report,
      device,
      'deviceClass',
      path,
      deviceClasses,
    );
    final allowedPlatforms = deviceClass == null
        ? null
        : deviceClassPlatforms[deviceClass];
    if (platform != null &&
        allowedPlatforms != null &&
        !allowedPlatforms.contains(platform)) {
      report.addError(
        '$path.platform',
        'deviceClass "$deviceClass" requires platform '
            '${allowedPlatforms.join(' or ')}; got "$platform"',
      );
    }
  }
  return result;
}

List<Map<String, Object?>> _validateManifestTakes(
  ValidationReport report,
  Map<String, Object?> json,
  Map<String, Map<String, Object?>> players,
  Map<String, Map<String, Object?>> devices,
) {
  final result = <Map<String, Object?>>[];
  final value = _required(report, json, 'takes', _root);
  if (value == null) return result;
  if (value is! List) {
    report.addError(r'$.takes', 'must be a list');
    return result;
  }

  final seen = <String>{};
  for (var i = 0; i < value.length; i++) {
    final path = '\$.takes[$i]';
    final take = _objectMap(value[i]);
    if (take == null) {
      report.addError(path, 'must be an object');
      continue;
    }
    _checkKeys(report, take, _manifestTakeKeys, path);

    final takeId = _readString(report, take, 'takeId', path);
    if (takeId != null) {
      if (!_takeIdPattern.hasMatch(takeId)) {
        report.addError(
          '$path.takeId',
          'must be a lowercase slug ending in a three-digit sequence',
        );
      } else if (!seen.add(takeId)) {
        report.addError('$path.takeId', 'duplicate take id "$takeId"');
      }
    }

    final playerId = _readString(report, take, 'playerId', path);
    if (playerId != null && !players.containsKey(playerId)) {
      report.addError(
        '$path.playerId',
        'references unknown player "$playerId"',
      );
    }

    final device = _readString(report, take, 'device', path);
    if (device != null && !devices.containsKey(device)) {
      report.addError('$path.device', 'references unknown device "$device"');
    }

    final platform = _readEnum(report, take, 'platform', path, platforms);
    final manifestPlatform = devices[device]?['platform'];
    if (platform != null &&
        manifestPlatform is String &&
        platform != manifestPlatform) {
      report.addError(
        '$path.platform',
        'does not match device "$device" platform "$manifestPlatform"',
      );
    }

    final condition = _readEnum(report, take, 'condition', path, conditions);
    final labelFile = _readString(report, take, 'labelFile', path);
    if (labelFile != null) {
      _validateRelativeFile(
        report,
        '$path.labelFile',
        labelFile,
        extension: '.json',
      );
    }
    final audioFile = _readString(report, take, 'audioFile', path);
    if (audioFile != null) {
      _validateRelativeFile(
        report,
        '$path.audioFile',
        audioFile,
        extension: '.wav',
      );
    }
    _readEnum(report, take, 'status', path, takeStatuses);

    final notes = take['notes'];
    if (notes != null && notes is! String) {
      report.addError('$path.notes', 'must be a string when present');
    }

    if (takeId != null &&
        playerId != null &&
        device != null &&
        condition != null) {
      final expectedPrefix = '$playerId-$device-$condition-';
      if (!takeId.startsWith(expectedPrefix)) {
        report.addError(
          '$path.takeId',
          'must start with "$expectedPrefix"; take ids are '
              '<playerId>-<device>-<condition>-<NNN>',
        );
      }
      final expectedLabel = '$playerId/$device/$condition/$takeId.json';
      if (labelFile != null && labelFile != expectedLabel) {
        report.addError(
          '$path.labelFile',
          'does not match the folder layout; expected "$expectedLabel"',
        );
      }
      final expectedAudio = '$playerId/$device/$condition/$takeId.wav';
      if (audioFile != null && audioFile != expectedAudio) {
        report.addError(
          '$path.audioFile',
          'does not match the folder layout; expected "$expectedAudio"',
        );
      }
    }

    result.add(take);
  }
  return result;
}

void _validateRelativeFile(
  ValidationReport report,
  String path,
  String value, {
  required String extension,
}) {
  if (value.contains('\\')) {
    report.addError(path, 'must use forward slashes, not backslashes');
  }
  if (value.startsWith('/') ||
      value.startsWith('\\') ||
      RegExp(r'^[A-Za-z]:').hasMatch(value)) {
    report.addError(path, 'must be a path relative to the corpus root');
  }
  final parts = value.split('/');
  if (parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
    report.addError(path, 'must not contain empty, "." or ".." segments');
  }
  if (!value.endsWith(extension)) {
    report.addError(path, 'must end with $extension');
  }
}

String _conditionBucket(String condition) =>
    condition == 'click' || condition == 'drone' ? 'click-drone' : condition;

class _TimedEvent {
  const _TimedEvent({
    required this.index,
    required this.onset,
    required this.end,
  });

  final int index;
  final double onset;
  final double end;
}

class _WrittenNote {
  const _WrittenNote(this.text, this.midi);

  final String text;
  final int midi;
}

final RegExp _playerIdPattern = RegExp(r'^p\d{2}$');
final RegExp _slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
final RegExp _takeIdPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*-\d{3}$');
final RegExp _writtenNotePattern = RegExp(r'^([A-G])([#b]?)(-?\d+)$');

_WrittenNote? _parseWrittenNote(String text) {
  final match = _writtenNotePattern.firstMatch(text);
  if (match == null) return null;
  const offsets = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final letter = match.group(1)!;
  final accidental = match.group(2)!;
  final octave = int.tryParse(match.group(3)!);
  if (octave == null) return null;
  final accidentalOffset = accidental == '#'
      ? 1
      : accidental == 'b'
      ? -1
      : 0;
  final midi = (octave + 1) * 12 + offsets[letter]! + accidentalOffset;
  return _WrittenNote(text, midi);
}

void _checkKeys(
  ValidationReport report,
  Map<String, Object?> map,
  Set<String> allowed,
  String path,
) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) {
      report.addError(
        _fieldPath(path, key),
        'unknown field; schema v1 has no extension fields',
      );
    }
  }
}

Object? _required(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path,
) {
  final field = _fieldPath(path, key);
  if (!map.containsKey(key)) {
    report.addError(field, 'missing required field');
    return null;
  }
  final value = map[key];
  if (value == null) {
    report.addError(field, 'must not be null');
    return null;
  }
  return value;
}

String? _readString(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path, {
  bool allowEmpty = false,
}) {
  final value = _required(report, map, key, path);
  if (value == null) return null;
  if (value is! String) {
    report.addError(_fieldPath(path, key), 'must be a string');
    return null;
  }
  if (!allowEmpty && value.trim().isEmpty) {
    report.addError(_fieldPath(path, key), 'must not be empty');
    return null;
  }
  return value;
}

int? _readInt(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path, {
  int? min,
  int? max,
}) {
  final value = _required(report, map, key, path);
  if (value == null) return null;
  if (value is! num) {
    report.addError(_fieldPath(path, key), 'must be an integer');
    return null;
  }
  if (value is double && !value.isFinite) {
    report.addError(_fieldPath(path, key), 'must be a finite integer');
    return null;
  }
  if (value.toDouble() != value.toInt().toDouble()) {
    report.addError(_fieldPath(path, key), 'must be an integer');
    return null;
  }
  final result = value.toInt();
  if (min != null && result < min) {
    report.addError(
      _fieldPath(path, key),
      'must be at least $min; got $result',
    );
  }
  if (max != null && result > max) {
    report.addError(_fieldPath(path, key), 'must be at most $max; got $result');
  }
  return result;
}

double? _readNumber(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path, {
  double? min,
  double? max,
  bool exclusiveMin = false,
}) {
  final value = _required(report, map, key, path);
  if (value == null) return null;
  if (value is! num) {
    report.addError(_fieldPath(path, key), 'must be a number');
    return null;
  }
  final result = value.toDouble();
  if (!result.isFinite) {
    report.addError(_fieldPath(path, key), 'must be a finite number');
    return null;
  }
  if (min != null && (exclusiveMin ? result <= min : result < min)) {
    report.addError(
      _fieldPath(path, key),
      'must be ${exclusiveMin ? 'greater than' : 'at least'} $min; got $result',
    );
  }
  if (max != null && result > max) {
    report.addError(_fieldPath(path, key), 'must be at most $max; got $result');
  }
  return result;
}

bool? _readBool(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path,
) {
  final value = _required(report, map, key, path);
  if (value == null) return null;
  if (value is! bool) {
    report.addError(_fieldPath(path, key), 'must be true or false');
    return null;
  }
  return value;
}

String? _readEnum(
  ValidationReport report,
  Map<String, Object?> map,
  String key,
  String path,
  List<String> allowed,
) {
  final value = _readString(report, map, key, path);
  if (value == null) return null;
  if (!allowed.contains(value)) {
    report.addError(
      _fieldPath(path, key),
      'must be one of: ${allowed.join(', ')}; got "$value"',
    );
  }
  return value;
}

String _fieldPath(String parent, String key) =>
    parent == _root ? '\$.$key' : '$parent.$key';

Map<String, Object?>? _objectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) return null;
      result[key] = entry.value;
    }
    return result;
  }
  return null;
}

class _Options {
  String? labelPath;
  String? manifestPath;
  bool json = false;
  bool help = false;
  String? error;
}

_Options _parseArguments(List<String> arguments) {
  final options = _Options();
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument == '--help' || argument == '-h') {
      options.help = true;
    } else if (argument == '--json') {
      options.json = true;
    } else if (argument == '--manifest') {
      if (i + 1 >= arguments.length) {
        options.error = '--manifest requires a path';
        break;
      }
      options.manifestPath = arguments[++i];
    } else if (argument.startsWith('--manifest=')) {
      final value = argument.substring('--manifest='.length);
      if (value.isEmpty) {
        options.error = '--manifest requires a path';
        break;
      }
      options.manifestPath = value;
    } else if (argument.startsWith('-')) {
      options.error = 'unknown option: $argument';
      break;
    } else if (options.labelPath != null) {
      options.error = 'only one label file may be validated per run';
      break;
    } else {
      options.labelPath = argument;
    }
  }
  if (!options.help &&
      options.error == null &&
      options.labelPath == null &&
      options.manifestPath == null) {
    options.error = 'provide a label file, or --manifest <path>';
  }
  return options;
}

class _LoadResult {
  const _LoadResult(this.report, this.json, {this.ioFailure = false});

  final ValidationReport report;
  final Map<String, Object?>? json;
  final bool ioFailure;
}

_LoadResult _loadLabel(String path) {
  final report = ValidationReport(source: path, kind: 'label');
  try {
    final decoded = jsonDecode(File(path).readAsStringSync());
    final json = _objectMap(decoded);
    if (json == null) {
      report.addError(_root, 'root must be a JSON object');
      return _LoadResult(report, null);
    }
    final validated = validateLabel(decoded, source: path);
    return _LoadResult(validated, json);
  } on FileSystemException catch (error) {
    report.addError(_root, 'cannot read file: ${error.message}');
    return _LoadResult(report, null, ioFailure: true);
  } on FormatException catch (error) {
    report.addError(_root, 'invalid JSON: ${error.message}');
    return _LoadResult(report, null);
  }
}

_LoadResult _loadManifest(String path) {
  final report = ValidationReport(source: path, kind: 'manifest');
  try {
    final decoded = jsonDecode(File(path).readAsStringSync());
    final json = _objectMap(decoded);
    if (json == null) {
      report.addError(_root, 'root must be a JSON object');
      return _LoadResult(report, null);
    }
    final validated = validateManifest(decoded, source: path);
    return _LoadResult(validated, json);
  } on FileSystemException catch (error) {
    report.addError(_root, 'cannot read file: ${error.message}');
    return _LoadResult(report, null, ioFailure: true);
  } on FormatException catch (error) {
    report.addError(_root, 'invalid JSON: ${error.message}');
    return _LoadResult(report, null);
  }
}

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  if (options.help) {
    stdout.write(_usage);
    return;
  }
  if (options.error != null) {
    stderr.writeln(options.error);
    stderr.write(_usage);
    exitCode = 2;
    return;
  }

  final reports = <ValidationReport>[];
  var ioFailure = false;
  Map<String, Object?>? labelJson;
  Map<String, Object?>? manifestJson;
  ValidationReport? labelReport;

  if (options.labelPath != null) {
    final result = _loadLabel(options.labelPath!);
    reports.add(result.report);
    labelJson = result.json;
    labelReport = result.report;
    ioFailure = ioFailure || result.ioFailure;
  }
  if (options.manifestPath != null) {
    final result = _loadManifest(options.manifestPath!);
    reports.add(result.report);
    manifestJson = result.json;
    ioFailure = ioFailure || result.ioFailure;
  }

  if (labelJson != null && manifestJson != null && labelReport != null) {
    crossCheckLabelAndManifest(labelJson, manifestJson, labelReport);
  }

  final errorCount = reports.fold<int>(
    0,
    (total, report) => total + report.errorCount,
  );
  final warningCount = reports.fold<int>(
    0,
    (total, report) => total + report.warningCount,
  );

  if (options.json) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'valid': errorCount == 0,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'files': [for (final report in reports) report.toJson()],
      }),
    );
  } else {
    _printHuman(reports, errorCount, warningCount);
  }

  if (ioFailure) {
    exitCode = 2;
  } else if (errorCount > 0) {
    exitCode = 1;
  }
}

void _printHuman(
  List<ValidationReport> reports,
  int errorCount,
  int warningCount,
) {
  for (final report in reports) {
    final label = report.kind == 'label' ? 'Label' : 'Manifest';
    stdout.writeln('$label: ${report.source}');
    if (report.takeId != null) {
      stdout.writeln('  takeId: ${report.takeId}');
    }
    for (final warning in report.warnings) {
      stdout.writeln('  WARN  ${warning.path}: ${warning.message}');
    }
    for (final error in report.errors) {
      stdout.writeln('  ERROR ${error.path}: ${error.message}');
    }
    if (report.summary.isNotEmpty) {
      final summary = report.summary;
      stdout.writeln(
        '  Summary: ${summary['acceptedTakeCount']} accepted of '
        '${summary['takeCount']} takes, ${summary['playerCount']} players, '
        '${summary['deviceCount']} devices',
      );
      final cells = summary['cells'];
      if (cells is Map) {
        for (final entry in cells.entries) {
          stdout.writeln('    ${entry.key}: ${entry.value}');
        }
      }
    }
    stdout.writeln(
      report.isValid
          ? '  OK: ${report.kind} is valid'
          : '  FAIL: ${report.errorCount} error(s), '
                '${report.warningCount} warning(s)',
    );
  }
  stdout.writeln(
    errorCount == 0
        ? 'All files valid${warningCount == 0 ? '.' : ' with $warningCount warning(s).'}'
        : '$errorCount error(s) across ${reports.length} file(s).',
  );
}

const String _usage = '''
Usage: dart run tool/corpus/validate_labels.dart [label.json] [options]

Validates a corpus label JSON file and, optionally, a corpus manifest.
Provide a label file, --manifest, or both.

Options:
  --manifest <path>   Also validate a manifest (and cross-check the label).
  --json              Print one machine-readable JSON object to stdout.
  -h, --help          Show this help.

Exit codes:
  0  valid
  1  validation errors
  2  usage or I/O error

Schema and rules: docs/CORPUS_LABELING.md
Corpus protocol:  docs/CORPUS_PROTOCOL.md
''';
