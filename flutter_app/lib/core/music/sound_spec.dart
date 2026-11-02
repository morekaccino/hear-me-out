import 'note.dart';

/// One sounding event inside a [SoundSpec]. Times are in beats.
class SoundEvent {
  const SoundEvent({
    required this.midi,
    this.startBeat = 0,
    this.durationBeats = 1,
    this.velocity = 0.8,
  });

  final int midi;
  final double startBeat;
  final double durationBeats;
  final double velocity;
}

/// A short, self-contained audio stimulus for an ear-training question.
///
/// The synth renders this to WAV bytes. Keeping it as pure data means tests can
/// assert on the musical content without touching a platform player.
class SoundSpec {
  const SoundSpec({
    required this.events,
    this.bpm = 80,
    this.label,
  });

  final List<SoundEvent> events;
  final double bpm;
  final String? label;

  double get lengthBeats {
    if (events.isEmpty) return 1;
    return events
        .map((event) => event.startBeat + event.durationBeats)
        .reduce((a, b) => a > b ? a : b);
  }

  Duration get duration => Duration(
    milliseconds: (lengthBeats * 60000 / bpm).round(),
  );

  SoundSpec copyWith({double? bpm}) => SoundSpec(
    events: events,
    bpm: bpm ?? this.bpm,
    label: label,
  );

  factory SoundSpec.note(Note note, {double bpm = 80}) => SoundSpec(
    bpm: bpm,
    events: [SoundEvent(midi: note.midi)],
    label: 'Single note',
  );

  factory SoundSpec.interval(
    Note lower,
    Note upper, {
    bool harmonic = false,
    double bpm = 80,
  }) => SoundSpec(
    bpm: bpm,
    events: [
      SoundEvent(midi: lower.midi, durationBeats: harmonic ? 2 : 1),
      SoundEvent(
        midi: upper.midi,
        startBeat: harmonic ? 0 : 1,
        durationBeats: harmonic ? 2 : 1,
      ),
    ],
    label: harmonic ? 'Harmonic interval' : 'Melodic interval',
  );

  factory SoundSpec.chord(List<Note> notes, {double bpm = 80}) => SoundSpec(
    bpm: bpm,
    events: [
      for (final note in notes)
        SoundEvent(midi: note.midi, durationBeats: 2),
    ],
    label: 'Chord',
  );

  factory SoundSpec.sequence(
    List<Note> notes, {
    double bpm = 80,
    double durationBeats = 1,
  }) => SoundSpec(
    bpm: bpm,
    events: [
      for (var index = 0; index < notes.length; index++)
        SoundEvent(
          midi: notes[index].midi,
          startBeat: index * durationBeats,
          durationBeats: durationBeats,
        ),
    ],
    label: 'Melody',
  );

  factory SoundSpec.progression(
    List<List<Note>> chords, {
    double bpm = 80,
    double beatsPerChord = 4,
  }) => SoundSpec(
    bpm: bpm,
    events: [
      for (var chordIndex = 0; chordIndex < chords.length; chordIndex++)
        for (final note in chords[chordIndex])
          SoundEvent(
            midi: note.midi,
            startBeat: chordIndex * beatsPerChord,
            durationBeats: beatsPerChord,
          ),
    ],
    label: 'Chord progression',
  );
}
