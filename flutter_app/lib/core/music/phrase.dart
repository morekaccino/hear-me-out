import 'json_read.dart';
import 'note_event.dart';
import 'piece.dart';

/// A short, playable unit of a piece.
///
/// A phrase is measured in quarter-note beats from its own start. If
/// [pickupBeats] is greater than zero, the first bar is an anacrusis of that
/// length and the remaining bars are complete. [bars] counts the pickup bar,
/// so [expectedTotalBeats] is `(bars - 1) * beatsPerBar + pickupBeats` when a
/// pickup is present. The validator compares this explicit value with
/// [totalBeats]; it never rounds a short phrase into a full one.
class Phrase {
  const Phrase({
    required this.id,
    required this.bars,
    required this.timeSignature,
    required this.events,
    required this.targetTempoBpm,
    this.title,
    this.skills = const <String>[],
    this.difficulty = 1,
    this.startBar = 1,
    this.pickupBeats = 0,
  });

  final String id;

  /// Number of bars, including a pickup bar when [pickupBeats] is non-zero.
  final int bars;

  final TimeSignature timeSignature;
  final List<NoteEvent> events;
  final int targetTempoBpm;
  final String? title;

  /// Stable skill ids such as `note-reading.open-strings`, not display text.
  final List<String> skills;

  /// 1 (easiest) through 5 (hardest).
  final int difficulty;

  /// Bar number in the piece where this phrase starts.
  final int startBar;

  /// Length of the incomplete first bar, in beats. Zero means no pickup.
  final double pickupBeats;

  List<NoteEvent> get notes => <NoteEvent>[
    for (final event in events)
      if (event.isNote) event,
  ];

  List<NoteEvent> get rests => <NoteEvent>[
    for (final event in events)
      if (event.isRest) event,
  ];

  /// The end of the last event, in beats from the start of the phrase.
  double get totalBeats {
    var total = 0.0;
    for (final event in events) {
      if (event.endBeat > total) total = event.endBeat;
    }
    return total;
  }

  /// The duration implied by [bars], [timeSignature], and [pickupBeats].
  double get expectedTotalBeats {
    final beatsPerBar = timeSignature.beatsPerBar;
    if (pickupBeats > 0) {
      return (bars - 1) * beatsPerBar + pickupBeats;
    }
    return bars * beatsPerBar;
  }

  Phrase copyWith({
    String? id,
    int? bars,
    TimeSignature? timeSignature,
    List<NoteEvent>? events,
    int? targetTempoBpm,
    String? title,
    List<String>? skills,
    int? difficulty,
    int? startBar,
    double? pickupBeats,
  }) {
    return Phrase(
      id: id ?? this.id,
      bars: bars ?? this.bars,
      timeSignature: timeSignature ?? this.timeSignature,
      events: events ?? this.events,
      targetTempoBpm: targetTempoBpm ?? this.targetTempoBpm,
      title: title ?? this.title,
      skills: skills ?? this.skills,
      difficulty: difficulty ?? this.difficulty,
      startBar: startBar ?? this.startBar,
      pickupBeats: pickupBeats ?? this.pickupBeats,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'bars': bars,
      'timeSignature': timeSignature.toJson(),
      'events': <Map<String, dynamic>>[
        for (final event in events) event.toJson(),
      ],
      'targetTempoBpm': targetTempoBpm,
      'skills': List<String>.unmodifiable(skills),
      'difficulty': difficulty,
      'startBar': startBar,
      'pickupBeats': pickupBeats,
    };
    if (title != null) json['title'] = title;
    return json;
  }

  factory Phrase.fromJson(Map<String, dynamic> json) =>
      Phrase.fromJsonAt(json, path: 'phrase');

  factory Phrase.fromJsonAt(Map<String, dynamic> json, {required String path}) {
    final eventList = readJsonList(json, 'events', path);
    final parsedEvents = <NoteEvent>[];
    for (var index = 0; index < eventList.length; index++) {
      final eventPath = '$path.events[$index]';
      final value = eventList[index];
      if (value is! Map) {
        jsonReadError(eventPath, 'Expected an object');
      }
      final eventJson = value is Map<String, dynamic>
          ? value
          : Map<String, dynamic>.from(value);
      parsedEvents.add(NoteEvent.fromJsonAt(eventJson, path: eventPath));
    }

    return Phrase(
      id: readJsonString(json, 'id', path),
      bars: readJsonInt(json, 'bars', path),
      timeSignature: TimeSignature.fromJsonAt(
        readJsonObject(json, 'timeSignature', path),
        path: '$path.timeSignature',
      ),
      events: List<NoteEvent>.unmodifiable(parsedEvents),
      targetTempoBpm: readJsonInt(json, 'targetTempoBpm', path),
      title: readOptionalJsonString(json, 'title', path),
      skills: readOptionalJsonStringList(json, 'skills', path),
      difficulty: readOptionalJsonInt(json, 'difficulty', path) ?? 1,
      startBar: readOptionalJsonInt(json, 'startBar', path) ?? 1,
      pickupBeats: readOptionalJsonDouble(json, 'pickupBeats', path) ?? 0,
    );
  }
}
