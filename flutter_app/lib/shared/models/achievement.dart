import 'package:freezed_annotation/freezed_annotation.dart';
part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
sealed class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String title,
    required String subtitle,
    required String icon,
    @Default(false) bool unlocked,
    DateTime? unlockedAt,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}
