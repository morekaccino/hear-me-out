import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    String? email,
    @Default('Musician') String displayName,
    @Default('guitar') String instrument,
    @Default('E2-E5') String instrumentRange,
    @Default(0) int xp,
    @Default(1) int level,
    @Default('bronze') String currentLeague,
    @Default(false) bool isPro,
    String? subscriptionId,
    DateTime? accountCreated,
    DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}
