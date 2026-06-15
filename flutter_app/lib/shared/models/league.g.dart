// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_League _$LeagueFromJson(Map<String, dynamic> json) => _League(
  name: json['name'] as String,
  totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 30,
  entries: (json['entries'] as List<dynamic>)
      .map((e) => LeagueEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  endsAt: DateTime.parse(json['endsAt'] as String),
);

Map<String, dynamic> _$LeagueToJson(_League instance) => <String, dynamic>{
  'name': instance.name,
  'totalUsers': instance.totalUsers,
  'entries': instance.entries,
  'endsAt': instance.endsAt.toIso8601String(),
};

_LeagueEntry _$LeagueEntryFromJson(Map<String, dynamic> json) => _LeagueEntry(
  rank: (json['rank'] as num).toInt(),
  displayName: json['displayName'] as String,
  instrument: json['instrument'] as String,
  xp: (json['xp'] as num).toInt(),
  isCurrentUser: json['isCurrentUser'] as bool,
);

Map<String, dynamic> _$LeagueEntryToJson(_LeagueEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'displayName': instance.displayName,
      'instrument': instance.instrument,
      'xp': instance.xp,
      'isCurrentUser': instance.isCurrentUser,
    };
