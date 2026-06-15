import 'package:freezed_annotation/freezed_annotation.dart';
part 'learning_card.freezed.dart';
part 'learning_card.g.dart';

enum CardType { newCard, learning, review }

@freezed
sealed class LearningCard with _$LearningCard {
  const factory LearningCard({
    required String id,
    required String noteValue,
    @Default(false) bool isFlipped,
    @Default(CardType.newCard) CardType cardType,
    @Default(0) int correctStreak,
    @Default(0) int totalCorrect,
    @Default(0) int totalIncorrect,
    DateTime? lastSeen,
    DateTime? masteredAt,
    @Default(0) int reviewCount,
  }) = _LearningCard;

  factory LearningCard.fromJson(Map<String, dynamic> json) => _$LearningCardFromJson(json);
}
