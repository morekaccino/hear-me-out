import 'package:freezed_annotation/freezed_annotation.dart';
part 'session_stats.freezed.dart';
part 'session_stats.g.dart';

@freezed
sealed class SessionStats with _$SessionStats {
  const factory SessionStats({
    @Default(0) int totalCorrect,
    @Default(0) int totalIncorrect,
    @Default(0.0) double accuracy,
    @Default(0) int total,
    @Default(0) int learning,
    @Default(0) int mastered,
    @Default(0) int notStarted,
    @Default(0.0) double progressPercentage,
  }) = _SessionStats;

  factory SessionStats.fromJson(Map<String, dynamic> json) => _$SessionStatsFromJson(json);
}
