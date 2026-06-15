// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'league.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$League {

 String get name; int get totalUsers; List<LeagueEntry> get entries; DateTime get endsAt;
/// Create a copy of League
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeagueCopyWith<League> get copyWith => _$LeagueCopyWithImpl<League>(this as League, _$identity);

  /// Serializes this League to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is League&&(identical(other.name, name) || other.name == name)&&(identical(other.totalUsers, totalUsers) || other.totalUsers == totalUsers)&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,totalUsers,const DeepCollectionEquality().hash(entries),endsAt);

@override
String toString() {
  return 'League(name: $name, totalUsers: $totalUsers, entries: $entries, endsAt: $endsAt)';
}


}

/// @nodoc
abstract mixin class $LeagueCopyWith<$Res>  {
  factory $LeagueCopyWith(League value, $Res Function(League) _then) = _$LeagueCopyWithImpl;
@useResult
$Res call({
 String name, int totalUsers, List<LeagueEntry> entries, DateTime endsAt
});




}
/// @nodoc
class _$LeagueCopyWithImpl<$Res>
    implements $LeagueCopyWith<$Res> {
  _$LeagueCopyWithImpl(this._self, this._then);

  final League _self;
  final $Res Function(League) _then;

/// Create a copy of League
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? totalUsers = null,Object? entries = null,Object? endsAt = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,totalUsers: null == totalUsers ? _self.totalUsers : totalUsers // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<LeagueEntry>,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [League].
extension LeaguePatterns on League {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _League value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _League() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _League value)  $default,){
final _that = this;
switch (_that) {
case _League():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _League value)?  $default,){
final _that = this;
switch (_that) {
case _League() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int totalUsers,  List<LeagueEntry> entries,  DateTime endsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _League() when $default != null:
return $default(_that.name,_that.totalUsers,_that.entries,_that.endsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int totalUsers,  List<LeagueEntry> entries,  DateTime endsAt)  $default,) {final _that = this;
switch (_that) {
case _League():
return $default(_that.name,_that.totalUsers,_that.entries,_that.endsAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int totalUsers,  List<LeagueEntry> entries,  DateTime endsAt)?  $default,) {final _that = this;
switch (_that) {
case _League() when $default != null:
return $default(_that.name,_that.totalUsers,_that.entries,_that.endsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _League implements League {
  const _League({required this.name, this.totalUsers = 30, required final  List<LeagueEntry> entries, required this.endsAt}): _entries = entries;
  factory _League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);

@override final  String name;
@override@JsonKey() final  int totalUsers;
 final  List<LeagueEntry> _entries;
@override List<LeagueEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override final  DateTime endsAt;

/// Create a copy of League
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeagueCopyWith<_League> get copyWith => __$LeagueCopyWithImpl<_League>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeagueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _League&&(identical(other.name, name) || other.name == name)&&(identical(other.totalUsers, totalUsers) || other.totalUsers == totalUsers)&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,totalUsers,const DeepCollectionEquality().hash(_entries),endsAt);

@override
String toString() {
  return 'League(name: $name, totalUsers: $totalUsers, entries: $entries, endsAt: $endsAt)';
}


}

/// @nodoc
abstract mixin class _$LeagueCopyWith<$Res> implements $LeagueCopyWith<$Res> {
  factory _$LeagueCopyWith(_League value, $Res Function(_League) _then) = __$LeagueCopyWithImpl;
@override @useResult
$Res call({
 String name, int totalUsers, List<LeagueEntry> entries, DateTime endsAt
});




}
/// @nodoc
class __$LeagueCopyWithImpl<$Res>
    implements _$LeagueCopyWith<$Res> {
  __$LeagueCopyWithImpl(this._self, this._then);

  final _League _self;
  final $Res Function(_League) _then;

/// Create a copy of League
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? totalUsers = null,Object? entries = null,Object? endsAt = null,}) {
  return _then(_League(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,totalUsers: null == totalUsers ? _self.totalUsers : totalUsers // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<LeagueEntry>,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$LeagueEntry {

 int get rank; String get displayName; String get instrument; int get xp; bool get isCurrentUser;
/// Create a copy of LeagueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeagueEntryCopyWith<LeagueEntry> get copyWith => _$LeagueEntryCopyWithImpl<LeagueEntry>(this as LeagueEntry, _$identity);

  /// Serializes this LeagueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeagueEntry&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,displayName,instrument,xp,isCurrentUser);

@override
String toString() {
  return 'LeagueEntry(rank: $rank, displayName: $displayName, instrument: $instrument, xp: $xp, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class $LeagueEntryCopyWith<$Res>  {
  factory $LeagueEntryCopyWith(LeagueEntry value, $Res Function(LeagueEntry) _then) = _$LeagueEntryCopyWithImpl;
@useResult
$Res call({
 int rank, String displayName, String instrument, int xp, bool isCurrentUser
});




}
/// @nodoc
class _$LeagueEntryCopyWithImpl<$Res>
    implements $LeagueEntryCopyWith<$Res> {
  _$LeagueEntryCopyWithImpl(this._self, this._then);

  final LeagueEntry _self;
  final $Res Function(LeagueEntry) _then;

/// Create a copy of LeagueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? displayName = null,Object? instrument = null,Object? xp = null,Object? isCurrentUser = null,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as String,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LeagueEntry].
extension LeagueEntryPatterns on LeagueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeagueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeagueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeagueEntry value)  $default,){
final _that = this;
switch (_that) {
case _LeagueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeagueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LeagueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String displayName,  String instrument,  int xp,  bool isCurrentUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeagueEntry() when $default != null:
return $default(_that.rank,_that.displayName,_that.instrument,_that.xp,_that.isCurrentUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String displayName,  String instrument,  int xp,  bool isCurrentUser)  $default,) {final _that = this;
switch (_that) {
case _LeagueEntry():
return $default(_that.rank,_that.displayName,_that.instrument,_that.xp,_that.isCurrentUser);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String displayName,  String instrument,  int xp,  bool isCurrentUser)?  $default,) {final _that = this;
switch (_that) {
case _LeagueEntry() when $default != null:
return $default(_that.rank,_that.displayName,_that.instrument,_that.xp,_that.isCurrentUser);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeagueEntry implements LeagueEntry {
  const _LeagueEntry({required this.rank, required this.displayName, required this.instrument, required this.xp, required this.isCurrentUser});
  factory _LeagueEntry.fromJson(Map<String, dynamic> json) => _$LeagueEntryFromJson(json);

@override final  int rank;
@override final  String displayName;
@override final  String instrument;
@override final  int xp;
@override final  bool isCurrentUser;

/// Create a copy of LeagueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeagueEntryCopyWith<_LeagueEntry> get copyWith => __$LeagueEntryCopyWithImpl<_LeagueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeagueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeagueEntry&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.instrument, instrument) || other.instrument == instrument)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,displayName,instrument,xp,isCurrentUser);

@override
String toString() {
  return 'LeagueEntry(rank: $rank, displayName: $displayName, instrument: $instrument, xp: $xp, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class _$LeagueEntryCopyWith<$Res> implements $LeagueEntryCopyWith<$Res> {
  factory _$LeagueEntryCopyWith(_LeagueEntry value, $Res Function(_LeagueEntry) _then) = __$LeagueEntryCopyWithImpl;
@override @useResult
$Res call({
 int rank, String displayName, String instrument, int xp, bool isCurrentUser
});




}
/// @nodoc
class __$LeagueEntryCopyWithImpl<$Res>
    implements _$LeagueEntryCopyWith<$Res> {
  __$LeagueEntryCopyWithImpl(this._self, this._then);

  final _LeagueEntry _self;
  final $Res Function(_LeagueEntry) _then;

/// Create a copy of LeagueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? displayName = null,Object? instrument = null,Object? xp = null,Object? isCurrentUser = null,}) {
  return _then(_LeagueEntry(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,instrument: null == instrument ? _self.instrument : instrument // ignore: cast_nullable_to_non_nullable
as String,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
