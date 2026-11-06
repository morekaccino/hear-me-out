/// How confident the learner is with reading notation.
enum ReadingLevel { noteNames, slowReader, comfortable }

ReadingLevel? readingLevelFromName(String? value) {
  return switch (value) {
    'noteNames' => ReadingLevel.noteNames,
    'slowReader' => ReadingLevel.slowReader,
    'comfortable' => ReadingLevel.comfortable,
    _ => null,
  };
}

/// The answers collected by the three onboarding screens.
///
/// This stays separate from the progress schema so the placement diagnostic
/// (T2.8) and the piece launch list (T3.1) can evolve without a storage
/// migration.
class OnboardingChoices {
  const OnboardingChoices({
    this.hasGuitar,
    this.readingLevel,
    this.firstPieceId,
    this.completedAt,
  });

  final bool? hasGuitar;
  final ReadingLevel? readingLevel;
  final String? firstPieceId;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
    'hasGuitar': hasGuitar,
    'readingLevel': readingLevel?.name,
    'firstPieceId': firstPieceId,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory OnboardingChoices.fromJson(Map<String, dynamic> json) {
    final guitarValue = json['hasGuitar'];
    if (guitarValue != null && guitarValue is! bool) {
      throw const FormatException('hasGuitar must be a boolean');
    }

    final readingValue = json['readingLevel'];
    ReadingLevel? level;
    if (readingValue != null) {
      if (readingValue is! String) {
        throw const FormatException('readingLevel must be a string');
      }
      level = readingLevelFromName(readingValue);
      if (level == null) {
        throw const FormatException('Unknown readingLevel');
      }
    }

    final pieceValue = json['firstPieceId'];
    if (pieceValue != null && pieceValue is! String) {
      throw const FormatException('firstPieceId must be a string');
    }

    final completedValue = json['completedAt'];
    DateTime? completedAt;
    if (completedValue != null) {
      if (completedValue is! String) {
        throw const FormatException('completedAt must be an ISO date string');
      }
      completedAt = DateTime.tryParse(completedValue);
      if (completedAt == null) {
        throw const FormatException('completedAt must be an ISO date string');
      }
    }

    return OnboardingChoices(
      hasGuitar: guitarValue as bool?,
      readingLevel: level,
      firstPieceId: pieceValue as String?,
      completedAt: completedAt,
    );
  }
}
