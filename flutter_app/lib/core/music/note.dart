import 'dart:math' as math;

/// A written musical note. For guitar, written pitch is one octave above the
/// sounding pitch, so translation happens in [Guitar].
enum Accidental { natural, sharp, flat }

class Note {
  const Note(this.letter, this.octave, {this.accidental = Accidental.natural});

  final String letter;
  final int octave;
  final Accidental accidental;

  static const _letterOffsets = <String, int>{
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  static const _letterOrder = <String, int>{
    'C': 0,
    'D': 1,
    'E': 2,
    'F': 3,
    'G': 4,
    'A': 5,
    'B': 6,
  };

  static const _sharpNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const _flatNames = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  /// MIDI note number using C4 = 60.
  int get midi {
    final base = (octave + 1) * 12 + _letterOffsets[letter]!;
    return switch (accidental) {
      Accidental.natural => base,
      Accidental.sharp => base + 1,
      Accidental.flat => base - 1,
    };
  }

  /// Diatonic position on a staff, independent of accidentals. C4 = 28.
  int get diatonicIndex => octave * 7 + _letterOrder[letter]!;

  /// Stable ASCII identifier used in stored progress and map keys.
  String get id =>
      '$letter${accidental == Accidental.sharp
          ? '#'
          : accidental == Accidental.flat
          ? 'b'
          : ''}$octave';

  String get name => id;

  String get display {
    final symbol = switch (accidental) {
      Accidental.natural => '',
      Accidental.sharp => '\u266F',
      Accidental.flat => '\u266D',
    };
    return '$letter$symbol$octave';
  }

  String get pitchClass => id.replaceAll(RegExp(r'-?\d+$'), '');

  bool samePitchAs(Note other) => midi == other.midi;

  Note transposed(int semitones, {bool preferFlats = false}) =>
      Note.fromMidi(midi + semitones, preferFlats: preferFlats);

  static Note? tryParse(String value) {
    final match = RegExp(
      r'^([A-Ga-g])([#b]?)(-?\d+)$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final letter = match.group(1)!.toUpperCase();
    final accidental = switch (match.group(2)) {
      '#' => Accidental.sharp,
      'b' => Accidental.flat,
      _ => Accidental.natural,
    };
    final octave = int.tryParse(match.group(3)!);
    if (octave == null) return null;
    return Note(letter, octave, accidental: accidental);
  }

  static Note parse(String value) {
    final note = tryParse(value);
    if (note == null) {
      throw FormatException('Invalid note: $value');
    }
    return note;
  }

  static Note fromMidi(int midi, {bool preferFlats = false}) {
    final pitchClass = midi % 12;
    final octave = midi ~/ 12 - 1;
    final name = (preferFlats ? _flatNames : _sharpNames)[pitchClass];
    final letter = name[0];
    final accidental = switch (name.length > 1 ? name[1] : '') {
      '#' => Accidental.sharp,
      'b' => Accidental.flat,
      _ => Accidental.natural,
    };
    return Note(letter, octave, accidental: accidental);
  }

  double frequency({double a4 = 440}) =>
      midiToFrequency(midi.toDouble(), a4: a4);

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) => other is Note && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

double frequencyToMidi(double frequency, {double a4 = 440}) {
  if (frequency <= 0) return double.nan;
  return 69 + 12 * (math.log(frequency / a4) / math.ln2);
}

double midiToFrequency(double midi, {double a4 = 440}) =>
    a4 * math.pow(2, (midi - 69) / 12).toDouble();

double centsFromMidi(double midi) => (midi - midi.roundToDouble()) * 100;

String dayKey(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';
