import 'package:freezed_annotation/freezed_annotation.dart';
part 'course.freezed.dart';
part 'course.g.dart';

@freezed
sealed class Course with _$Course {
  const factory Course({
    required String id,
    required String title,
    required String description,
    required int level,
    required bool isPro,
    @Default(0.0) double progress,
    @Default(0) int totalItems,
    @Default(0) int completedItems,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}
