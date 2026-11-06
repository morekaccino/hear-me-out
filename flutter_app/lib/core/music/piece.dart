import 'guitar.dart';
import 'json_read.dart';

/// The licensing basis for a piece.
///
/// V1 only ships public-domain or original material. The enum records the
/// status; it is not a legal opinion. T6.3 owns the legal review.
enum LicenseStatus {
  publicDomain('public-domain'),
  original('original'),
  licensed('licensed');

  const LicenseStatus(this.wireName);

  /// Stable value used in score JSON.
  final String wireName;

  bool get isV1Compatible =>
      this == LicenseStatus.publicDomain || this == LicenseStatus.original;

  static LicenseStatus? tryParse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
    return switch (normalized) {
      'publicdomain' => LicenseStatus.publicDomain,
      'original' => LicenseStatus.original,
      'licensed' => LicenseStatus.licensed,
      _ => null,
    };
  }
}

/// A metrical signature such as 4/4 or 6/8.
class TimeSignature {
  const TimeSignature(this.numerator, this.denominator);

  final int numerator;
  final int denominator;

  /// Length of one bar in quarter-note beats.
  double get beatsPerBar => numerator * 4 / denominator;

  bool get isValid {
    const allowedDenominators = <int>{1, 2, 4, 8, 16, 32};
    return numerator >= 1 &&
        numerator <= 32 &&
        allowedDenominators.contains(denominator);
  }

  Map<String, dynamic> toJson() => {
    'numerator': numerator,
    'denominator': denominator,
  };

  factory TimeSignature.fromJsonAt(
    Map<String, dynamic> json, {
    required String path,
  }) {
    return TimeSignature(
      readJsonInt(json, 'numerator', path),
      readJsonInt(json, 'denominator', path),
    );
  }

  factory TimeSignature.fromJson(Map<String, dynamic> json) =>
      TimeSignature.fromJsonAt(json, path: 'timeSignature');

  @override
  String toString() => '$numerator/$denominator';

  @override
  bool operator ==(Object other) =>
      other is TimeSignature &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

/// A guitar tuning expressed as sounding MIDI numbers, low to high.
class Tuning {
  const Tuning({required this.name, required this.openStrings});

  final String name;

  /// Sounding MIDI numbers from the lowest string to the highest string.
  /// Standard tuning is E2 A2 D3 G3 B3 E4.
  final List<int> openStrings;

  /// Standard tuning, derived from the shared guitar table so the two models
  /// cannot drift apart.
  static final Tuning standard = Tuning(
    name: 'Standard',
    openStrings: <int>[for (final string in standardTuning) string.open.midi],
  );

  bool get isStandard {
    if (openStrings.length != standard.openStrings.length) return false;
    for (var index = 0; index < openStrings.length; index++) {
      if (openStrings[index] != standard.openStrings[index]) return false;
    }
    return true;
  }

  /// Sounding MIDI at [stringNumber] (1 = high E) and [fret].
  ///
  /// Returns null when the string number is outside 1..6, the fret is
  /// negative, or the tuning does not have six strings.
  int? soundingMidiAt(int stringNumber, int fret) {
    if (openStrings.length != 6) return null;
    if (stringNumber < 1 || stringNumber > 6 || fret < 0) return null;
    return openStrings[6 - stringNumber] + fret;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'openStrings': List<int>.unmodifiable(openStrings),
  };

  factory Tuning.fromJsonAt(Map<String, dynamic> json, {required String path}) {
    final openStrings = readJsonList(json, 'openStrings', path);
    final values = <int>[];
    for (var index = 0; index < openStrings.length; index++) {
      final value = openStrings[index];
      if (value is int) {
        values.add(value);
      } else if (value is num &&
          value.isFinite &&
          value == value.roundToDouble()) {
        values.add(value.toInt());
      } else {
        jsonReadError('$path.openStrings[$index]', 'Expected an integer');
      }
    }
    return Tuning(
      name: readJsonString(json, 'name', path),
      openStrings: List<int>.unmodifiable(values),
    );
  }

  factory Tuning.fromJson(Map<String, dynamic> json) =>
      Tuning.fromJsonAt(json, path: 'tuning');
}

/// A piece of music. Phrases hold the timed events; the piece holds the
/// metadata shared by every phrase.
class Piece {
  const Piece({
    required this.id,
    required this.title,
    required this.composer,
    required this.license,
    required this.tuning,
    required this.timeSignature,
    required this.key,
    this.capo = 0,
    this.sections = const <String>[],
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String composer;

  /// Free-text license description. Canonical V1 values are `public-domain`,
  /// `original`, and `licensed`; see [licenseStatus].
  final String license;

  final Tuning tuning;
  final TimeSignature timeSignature;

  /// Key name with mode, for example `G major` or `A minor`.
  final String key;

  /// Capo fret. V1 supports capo 0 only; nonzero capos are rejected until
  /// capo-aware pitch semantics exist.
  final int capo;

  /// Optional section labels such as `A` or `Verse`.
  final List<String> sections;

  /// Optional source for public-domain or licensed material.
  final String? sourceUrl;

  LicenseStatus? get licenseStatus => LicenseStatus.tryParse(license);

  /// V1 requires capo 0 and public-domain or original material. Non-standard
  /// tuning is reported as a warning so future content can opt in explicitly.
  bool get isV1Compatible =>
      capo == 0 && (licenseStatus?.isV1Compatible ?? false);

  Piece copyWith({
    String? id,
    String? title,
    String? composer,
    String? license,
    Tuning? tuning,
    TimeSignature? timeSignature,
    String? key,
    int? capo,
    List<String>? sections,
    String? sourceUrl,
  }) {
    return Piece(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      license: license ?? this.license,
      tuning: tuning ?? this.tuning,
      timeSignature: timeSignature ?? this.timeSignature,
      key: key ?? this.key,
      capo: capo ?? this.capo,
      sections: sections ?? this.sections,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'composer': composer,
      'license': license,
      'tuning': tuning.toJson(),
      'capo': capo,
      'timeSignature': timeSignature.toJson(),
      'key': key,
      'sections': List<String>.unmodifiable(sections),
    };
    if (sourceUrl != null) json['sourceUrl'] = sourceUrl;
    return json;
  }

  factory Piece.fromJson(Map<String, dynamic> json) =>
      Piece.fromJsonAt(json, path: 'piece');

  factory Piece.fromJsonAt(Map<String, dynamic> json, {required String path}) {
    return Piece(
      id: readJsonString(json, 'id', path),
      title: readJsonString(json, 'title', path),
      composer: readJsonString(json, 'composer', path),
      license: readJsonString(json, 'license', path),
      tuning: Tuning.fromJsonAt(
        readJsonObject(json, 'tuning', path),
        path: '$path.tuning',
      ),
      timeSignature: TimeSignature.fromJsonAt(
        readJsonObject(json, 'timeSignature', path),
        path: '$path.timeSignature',
      ),
      key: readJsonString(json, 'key', path),
      capo: readOptionalJsonInt(json, 'capo', path) ?? 0,
      sections: readOptionalJsonStringList(json, 'sections', path),
      sourceUrl: readOptionalJsonString(json, 'sourceUrl', path),
    );
  }
}
