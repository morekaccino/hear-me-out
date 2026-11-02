/// A Western interval, expressed as a distance in semitones plus a diatonic
/// number and quality.
///
/// The app uses intervals for staff reading, ear training, chord spelling, and
/// scale construction. Keep this pure: no UI, no audio.
enum IntervalQuality { perfect, major, minor, augmented, diminished }

class Interval {
  const Interval({
    required this.semitones,
    required this.number,
    required this.quality,
  });

  /// Distance in semitones. Compound intervals can exceed 12.
  final int semitones;

  /// Diatonic size: 1 = unison, 2 = second, ... 8 = octave, 9 = ninth.
  final int number;

  final IntervalQuality quality;

  static const unison = Interval(
    semitones: 0,
    number: 1,
    quality: IntervalQuality.perfect,
  );
  static const minorSecond = Interval(
    semitones: 1,
    number: 2,
    quality: IntervalQuality.minor,
  );
  static const majorSecond = Interval(
    semitones: 2,
    number: 2,
    quality: IntervalQuality.major,
  );
  static const minorThird = Interval(
    semitones: 3,
    number: 3,
    quality: IntervalQuality.minor,
  );
  static const majorThird = Interval(
    semitones: 4,
    number: 3,
    quality: IntervalQuality.major,
  );
  static const perfectFourth = Interval(
    semitones: 5,
    number: 4,
    quality: IntervalQuality.perfect,
  );
  static const tritone = Interval(
    semitones: 6,
    number: 4,
    quality: IntervalQuality.augmented,
  );
  static const perfectFifth = Interval(
    semitones: 7,
    number: 5,
    quality: IntervalQuality.perfect,
  );
  static const minorSixth = Interval(
    semitones: 8,
    number: 6,
    quality: IntervalQuality.minor,
  );
  static const majorSixth = Interval(
    semitones: 9,
    number: 6,
    quality: IntervalQuality.major,
  );
  static const minorSeventh = Interval(
    semitones: 10,
    number: 7,
    quality: IntervalQuality.minor,
  );
  static const majorSeventh = Interval(
    semitones: 11,
    number: 7,
    quality: IntervalQuality.major,
  );
  static const octave = Interval(
    semitones: 12,
    number: 8,
    quality: IntervalQuality.perfect,
  );

  static const List<Interval> simple = [
    unison,
    minorSecond,
    majorSecond,
    minorThird,
    majorThird,
    perfectFourth,
    tritone,
    perfectFifth,
    minorSixth,
    majorSixth,
    minorSeventh,
    majorSeventh,
    octave,
  ];

  /// The conventional abbreviation, such as `m3`, `P5`, or `M7`.
  String get abbreviation {
    final prefix = switch (quality) {
      IntervalQuality.perfect => 'P',
      IntervalQuality.major => 'M',
      IntervalQuality.minor => 'm',
      IntervalQuality.augmented => 'A',
      IntervalQuality.diminished => 'd',
    };
    return '$prefix$number';
  }

  /// A learner-facing name, such as `minor third`.
  String get name {
    final qualityName = switch (quality) {
      IntervalQuality.perfect => 'perfect',
      IntervalQuality.major => 'major',
      IntervalQuality.minor => 'minor',
      IntervalQuality.augmented => 'augmented',
      IntervalQuality.diminished => 'diminished',
    };
    const numbers = <int, String>{
      1: 'unison',
      2: 'second',
      3: 'third',
      4: 'fourth',
      5: 'fifth',
      6: 'sixth',
      7: 'seventh',
      8: 'octave',
      9: 'ninth',
      10: 'tenth',
      11: 'eleventh',
      12: 'twelfth',
      13: 'thirteenth',
    };
    final numberName = numbers[number] ?? '$number-th';
    return '$qualityName $numberName';
  }

  /// The inversion within an octave: m3 → M6, P5 → P4, and so on.
  Interval get inverse {
    if (number == 1) return octave;
    if (number == 8) return unison;
    final invertedNumber = 9 - (number > 8 ? number - 7 : number);
    final invertedQuality = switch (quality) {
      IntervalQuality.perfect => IntervalQuality.perfect,
      IntervalQuality.major => IntervalQuality.minor,
      IntervalQuality.minor => IntervalQuality.major,
      IntervalQuality.augmented => IntervalQuality.diminished,
      IntervalQuality.diminished => IntervalQuality.augmented,
    };
    return Interval(
      semitones: 12 - semitones,
      number: invertedNumber,
      quality: invertedQuality,
    );
  }

  /// Maps a semitone distance to the simplest common interval.
  static Interval fromSemitones(int semitones) {
    final normalized = semitones % 12;
    return simple.firstWhere(
      (interval) => interval.semitones == normalized,
      orElse: () => Interval(
        semitones: normalized,
        number: 1,
        quality: IntervalQuality.perfect,
      ),
    );
  }

  /// The semitone size of a diatonic number in the major scale.
  static int majorSemitonesForNumber(int number) {
    const major = [0, 2, 4, 5, 7, 9, 11, 12];
    if (number >= 1 && number <= 8) return major[number - 1];
    final octaves = (number - 1) ~/ 7;
    return octaves * 12 + major[(number - 1) % 7];
  }

  @override
  String toString() => abbreviation;

  @override
  bool operator ==(Object other) =>
      other is Interval &&
      other.semitones == semitones &&
      other.number == number &&
      other.quality == quality;

  @override
  int get hashCode => Object.hash(semitones, number, quality);
}

/// Whether [semitones] fits the given diatonic [number] as a perfect interval.
bool isPerfectIntervalNumber(int number) {
  final simple = ((number - 1) % 7) + 1;
  return simple == 1 || simple == 4 || simple == 5 || simple == 8;
}
