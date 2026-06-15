// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionStats _$SessionStatsFromJson(Map<String, dynamic> json) =>
    _SessionStats(
      totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
      totalIncorrect: (json['totalIncorrect'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      learning: (json['learning'] as num?)?.toInt() ?? 0,
      mastered: (json['mastered'] as num?)?.toInt() ?? 0,
      notStarted: (json['notStarted'] as num?)?.toInt() ?? 0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$SessionStatsToJson(_SessionStats instance) =>
    <String, dynamic>{
      'totalCorrect': instance.totalCorrect,
      'totalIncorrect': instance.totalIncorrect,
      'accuracy': instance.accuracy,
      'total': instance.total,
      'learning': instance.learning,
      'mastered': instance.mastered,
      'notStarted': instance.notStarted,
      'progressPercentage': instance.progressPercentage,
    };
