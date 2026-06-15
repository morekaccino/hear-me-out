import 'package:freezed_annotation/freezed_annotation.dart';
part 'league.freezed.dart';
part 'league.g.dart';

@freezed
sealed class League with _$League {
  const factory League({
    required String name,
    @Default(30) int totalUsers,
    required List<LeagueEntry> entries,
    required DateTime endsAt,
  }) = _League;

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);
}

@freezed
sealed class LeagueEntry with _$LeagueEntry {
  const factory LeagueEntry({
    required int rank,
    required String displayName,
    required String instrument,
    required int xp,
    required bool isCurrentUser,
  }) = _LeagueEntry;

  factory LeagueEntry.fromJson(Map<String, dynamic> json) => _$LeagueEntryFromJson(json);
}
