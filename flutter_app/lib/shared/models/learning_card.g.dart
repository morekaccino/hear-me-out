// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LearningCard _$LearningCardFromJson(Map<String, dynamic> json) =>
    _LearningCard(
      id: json['id'] as String,
      noteValue: json['noteValue'] as String,
      isFlipped: json['isFlipped'] as bool? ?? false,
      cardType:
          $enumDecodeNullable(_$CardTypeEnumMap, json['cardType']) ??
          CardType.newCard,
      correctStreak: (json['correctStreak'] as num?)?.toInt() ?? 0,
      totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
      totalIncorrect: (json['totalIncorrect'] as num?)?.toInt() ?? 0,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      masteredAt: json['masteredAt'] == null
          ? null
          : DateTime.parse(json['masteredAt'] as String),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LearningCardToJson(_LearningCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noteValue': instance.noteValue,
      'isFlipped': instance.isFlipped,
      'cardType': _$CardTypeEnumMap[instance.cardType]!,
      'correctStreak': instance.correctStreak,
      'totalCorrect': instance.totalCorrect,
      'totalIncorrect': instance.totalIncorrect,
      'lastSeen': instance.lastSeen?.toIso8601String(),
      'masteredAt': instance.masteredAt?.toIso8601String(),
      'reviewCount': instance.reviewCount,
    };

const _$CardTypeEnumMap = {
  CardType.newCard: 'newCard',
  CardType.learning: 'learning',
  CardType.review: 'review',
};
