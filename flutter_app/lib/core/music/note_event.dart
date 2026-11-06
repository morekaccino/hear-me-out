import 'guitar.dart';
import 'json_read.dart';
import 'note.dart';

/// V1 scores are strictly monophonic. A [NoteEvent] is either one sounding
/// note or one rest; chords and double stops are represented as overlapping
/// note events, which [Score.validate] rejects.
enum NoteEventKind { note, rest }

/// One timed event in a phrase.
///
/// Guitar notation is written one octave above sounding pitch. [writtenNote]
/// is the note on the staff; [soundingMidi] is what the microphone hears.
/// [Score.validate] checks that the pair agrees with
/// [Guitar.soundingMidiForWritten]; callers must not assume that a supplied
/// [soundingMidi] is correct.
class NoteEvent {
  const NoteEvent({
    required this.startBeat,
    required this.durationBeats,
    required this.kind,
    this.writtenNote,
    this.soundingMidi,
    this.string,
    this.fret,
    this.tieToNext = false,
    this.velocity = 1.0,
  });

  /// Beat offset from the start of the phrase.
  final double startBeat;

  /// Length in beats. Always greater than zero for a valid event.
  final double durationBeats;

  final NoteEventKind kind;

  /// The written pitch on the staff. Null for a rest.
  final Note? writtenNote;

  /// The sounding MIDI number after guitar transposition. Null for a rest.
  final int? soundingMidi;

  /// 1 = high E, 6 = low E. Null when the phrase does not specify a position.
  final int? string;

  /// 0 = open string. Null when the phrase does not specify a position.
  final int? fret;

  /// A tied note is sustained into the next event instead of being plucked
  /// again. The next event must start exactly at [endBeat] with the same
  /// sounding pitch; [Score.validate] enforces this.
  final bool tieToNext;

  /// Normalized note velocity in the range 0..1.
  final double velocity;

  double get endBeat => startBeat + durationBeats;

  bool get isNote => kind == NoteEventKind.note;

  bool get isRest => kind == NoteEventKind.rest;

  /// The sounding MIDI implied by [writtenNote], or null for a rest.
  int? get expectedSoundingMidi =>
      writtenNote == null ? null : Guitar.soundingMidiForWritten(writtenNote!);

  NoteEvent copyWith({
    double? startBeat,
    double? durationBeats,
    NoteEventKind? kind,
    Note? writtenNote,
    int? soundingMidi,
    int? string,
    int? fret,
    bool? tieToNext,
    double? velocity,
  }) {
    return NoteEvent(
      startBeat: startBeat ?? this.startBeat,
      durationBeats: durationBeats ?? this.durationBeats,
      kind: kind ?? this.kind,
      writtenNote: writtenNote ?? this.writtenNote,
      soundingMidi: soundingMidi ?? this.soundingMidi,
      string: string ?? this.string,
      fret: fret ?? this.fret,
      tieToNext: tieToNext ?? this.tieToNext,
      velocity: velocity ?? this.velocity,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'startBeat': startBeat,
      'durationBeats': durationBeats,
      'kind': kind.name,
    };
    if (isNote) {
      json['writtenNote'] = writtenNote?.id;
      json['soundingMidi'] = soundingMidi;
      if (string != null) json['string'] = string;
      if (fret != null) json['fret'] = fret;
      json['tieToNext'] = tieToNext;
    }
    json['velocity'] = velocity;
    return json;
  }

  factory NoteEvent.fromJson(Map<String, dynamic> json) =>
      NoteEvent.fromJsonAt(json, path: 'event');

  factory NoteEvent.fromJsonAt(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final kindName = readJsonString(json, 'kind', path);
    final kind = switch (kindName) {
      'note' => NoteEventKind.note,
      'rest' => NoteEventKind.rest,
      _ => jsonReadError(
        '$path.kind',
        'Unknown note event kind "$kindName" (expected "note" or "rest")',
      ),
    };
    final writtenName = readOptionalJsonString(json, 'writtenNote', path);
    final writtenNote = writtenName == null ? null : Note.tryParse(writtenName);
    if (writtenName != null && writtenNote == null) {
      jsonReadError('$path.writtenNote', 'Invalid note name "$writtenName"');
    }
    return NoteEvent(
      startBeat: readJsonDouble(json, 'startBeat', path),
      durationBeats: readJsonDouble(json, 'durationBeats', path),
      kind: kind,
      writtenNote: writtenNote,
      soundingMidi: readOptionalJsonInt(json, 'soundingMidi', path),
      string: readOptionalJsonInt(json, 'string', path),
      fret: readOptionalJsonInt(json, 'fret', path),
      tieToNext: readOptionalJsonBool(json, 'tieToNext', path, fallback: false),
      velocity: readOptionalJsonDouble(json, 'velocity', path) ?? 1.0,
    );
  }
}
