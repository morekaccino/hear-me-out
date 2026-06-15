// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Course _$CourseFromJson(Map<String, dynamic> json) => _Course(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  level: (json['level'] as num).toInt(),
  isPro: json['isPro'] as bool,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
  completedItems: (json['completedItems'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CourseToJson(_Course instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'level': instance.level,
  'isPro': instance.isPro,
  'progress': instance.progress,
  'totalItems': instance.totalItems,
  'completedItems': instance.completedItems,
};
