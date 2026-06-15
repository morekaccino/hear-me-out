// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  email: json['email'] as String?,
  displayName: json['displayName'] as String? ?? 'Musician',
  instrument: json['instrument'] as String? ?? 'guitar',
  instrumentRange: json['instrumentRange'] as String? ?? 'E2-E5',
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  level: (json['level'] as num?)?.toInt() ?? 1,
  currentLeague: json['currentLeague'] as String? ?? 'bronze',
  isPro: json['isPro'] as bool? ?? false,
  subscriptionId: json['subscriptionId'] as String?,
  accountCreated: json['accountCreated'] == null
      ? null
      : DateTime.parse(json['accountCreated'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'displayName': instance.displayName,
  'instrument': instance.instrument,
  'instrumentRange': instance.instrumentRange,
  'xp': instance.xp,
  'level': instance.level,
  'currentLeague': instance.currentLeague,
  'isPro': instance.isPro,
  'subscriptionId': instance.subscriptionId,
  'accountCreated': instance.accountCreated?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
