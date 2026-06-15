// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get uid; String? get email; String get displayName; String get instrument; String get instrumentRange; int get xp; int get level; String get currentLeague; bool get isPro; String? get subscriptionId; DateTime? get accountCreated; DateTime? get updatedAt;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.instrumentRange, instrumentRange) || other.instrumentRange == instrumentRange)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentLeague, currentLeague) || other.currentLeague == currentLeague)&&(identical(other.isPro, isPro) || other.isPro == isPro)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.accountCreated, accountCreated) || other.accountCreated == accountCreated)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,displayName,instrument,instrumentRange,xp,level,currentLeague,isPro,subscriptionId,accountCreated,updatedAt);

@override
String toString() {
  return 'AppUser(uid: $uid, email: $email, displayName: $displayName, instrument: $instrument, instrumentRange: $instrumentRange, xp: $xp, level: $level, currentLeague: $currentLeague, isPro: $isPro, subscriptionId: $subscriptionId, accountCreated: $accountCreated, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid, String? email, String displayName, String instrument, String instrumentRange, int xp, int level, String currentLeague, bool isPro, String? subscriptionId, DateTime? accountCreated, DateTime? updatedAt
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = freezed,Object? displayName = null,Object? instrument = null,Object? instrumentRange = null,Object? xp = null,Object? level = null,Object? currentLeague = null,Object? isPro = null,Object? subscriptionId = freezed,Object? accountCreated = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as String,instrumentRange: null == instrumentRange ? _self.instrumentRange : instrumentRange // ignore: cast_nullable_to_non_nullable
as String,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentLeague: null == currentLeague ? _self.currentLeague : currentLeague // ignore: cast_nullable_to_non_nullable
as String,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,accountCreated: freezed == accountCreated ? _self.accountCreated : accountCreated // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String? email,  String displayName,  String instrument,  String instrumentRange,  int xp,  int level,  String currentLeague,  bool isPro,  String? subscriptionId,  DateTime? accountCreated,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.instrument,_that.instrumentRange,_that.xp,_that.level,_that.currentLeague,_that.isPro,_that.subscriptionId,_that.accountCreated,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String? email,  String displayName,  String instrument,  String instrumentRange,  int xp,  int level,  String currentLeague,  bool isPro,  String? subscriptionId,  DateTime? accountCreated,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.email,_that.displayName,_that.instrument,_that.instrumentRange,_that.xp,_that.level,_that.currentLeague,_that.isPro,_that.subscriptionId,_that.accountCreated,_that.updatedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String? email,  String displayName,  String instrument,  String instrumentRange,  int xp,  int level,  String currentLeague,  bool isPro,  String? subscriptionId,  DateTime? accountCreated,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.displayName,_that.instrument,_that.instrumentRange,_that.xp,_that.level,_that.currentLeague,_that.isPro,_that.subscriptionId,_that.accountCreated,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser implements AppUser {
  const _AppUser({required this.uid, this.email, this.displayName = 'Musician', this.instrument = 'guitar', this.instrumentRange = 'E2-E5', this.xp = 0, this.level = 1, this.currentLeague = 'bronze', this.isPro = false, this.subscriptionId, this.accountCreated, this.updatedAt});
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  String uid;
@override final  String? email;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String instrument;
@override@JsonKey() final  String instrumentRange;
@override@JsonKey() final  int xp;
@override@JsonKey() final  int level;
@override@JsonKey() final  String currentLeague;
@override@JsonKey() final  bool isPro;
@override final  String? subscriptionId;
@override final  DateTime? accountCreated;
@override final  DateTime? updatedAt;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.instrumentRange, instrumentRange) || other.instrumentRange == instrumentRange)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentLeague, currentLeague) || other.currentLeague == currentLeague)&&(identical(other.isPro, isPro) || other.isPro == isPro)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.accountCreated, accountCreated) || other.accountCreated == accountCreated)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,displayName,instrument,instrumentRange,xp,level,currentLeague,isPro,subscriptionId,accountCreated,updatedAt);

@override
String toString() {
  return 'AppUser(uid: $uid, email: $email, displayName: $displayName, instrument: $instrument, instrumentRange: $instrumentRange, xp: $xp, level: $level, currentLeague: $currentLeague, isPro: $isPro, subscriptionId: $subscriptionId, accountCreated: $accountCreated, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String? email, String displayName, String instrument, String instrumentRange, int xp, int level, String currentLeague, bool isPro, String? subscriptionId, DateTime? accountCreated, DateTime? updatedAt
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = freezed,Object? displayName = null,Object? instrument = null,Object? instrumentRange = null,Object? xp = null,Object? level = null,Object? currentLeague = null,Object? isPro = null,Object? subscriptionId = freezed,Object? accountCreated = freezed,Object? updatedAt = freezed,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as String,instrumentRange: null == instrumentRange ? _self.instrumentRange : instrumentRange // ignore: cast_nullable_to_non_nullable
as String,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentLeague: null == currentLeague ? _self.currentLeague : currentLeague // ignore: cast_nullable_to_non_nullable
as String,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,accountCreated: freezed == accountCreated ? _self.accountCreated : accountCreated // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
