// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionStats {

 int get totalCorrect; int get totalIncorrect; double get accuracy; int get total; int get learning; int get mastered; int get notStarted; double get progressPercentage;
/// Create a copy of SessionStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStatsCopyWith<SessionStats> get copyWith => _$SessionStatsCopyWithImpl<SessionStats>(this as SessionStats, _$identity);

  /// Serializes this SessionStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStats&&(identical(other.totalCorrect, totalCorrect) || other.totalCorrect == totalCorrect)&&(identical(other.totalIncorrect, totalIncorrect) || other.totalIncorrect == totalIncorrect)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.total, total) || other.total == total)&&(identical(other.learning, learning) || other.learning == learning)&&(identical(other.mastered, mastered) || other.mastered == mastered)&&(identical(other.notStarted, notStarted) || other.notStarted == notStarted)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalCorrect,totalIncorrect,accuracy,total,learning,mastered,notStarted,progressPercentage);

@override
String toString() {
  return 'SessionStats(totalCorrect: $totalCorrect, totalIncorrect: $totalIncorrect, accuracy: $accuracy, total: $total, learning: $learning, mastered: $mastered, notStarted: $notStarted, progressPercentage: $progressPercentage)';
}


}

/// @nodoc
abstract mixin class $SessionStatsCopyWith<$Res>  {
  factory $SessionStatsCopyWith(SessionStats value, $Res Function(SessionStats) _then) = _$SessionStatsCopyWithImpl;
@useResult
$Res call({
 int totalCorrect, int totalIncorrect, double accuracy, int total, int learning, int mastered, int notStarted, double progressPercentage
});




}
/// @nodoc
class _$SessionStatsCopyWithImpl<$Res>
    implements $SessionStatsCopyWith<$Res> {
  _$SessionStatsCopyWithImpl(this._self, this._then);

  final SessionStats _self;
  final $Res Function(SessionStats) _then;

/// Create a copy of SessionStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCorrect = null,Object? totalIncorrect = null,Object? accuracy = null,Object? total = null,Object? learning = null,Object? mastered = null,Object? notStarted = null,Object? progressPercentage = null,}) {
  return _then(_self.copyWith(
totalCorrect: null == totalCorrect ? _self.totalCorrect : totalCorrect // ignore: cast_nullable_to_non_nullable
as int,totalIncorrect: null == totalIncorrect ? _self.totalIncorrect : totalIncorrect // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,learning: null == learning ? _self.learning : learning // ignore: cast_nullable_to_non_nullable
as int,mastered: null == mastered ? _self.mastered : mastered // ignore: cast_nullable_to_non_nullable
as int,notStarted: null == notStarted ? _self.notStarted : notStarted // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionStats].
extension SessionStatsPatterns on SessionStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionStats value)  $default,){
final _that = this;
switch (_that) {
case _SessionStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionStats value)?  $default,){
final _that = this;
switch (_that) {
case _SessionStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalCorrect,  int totalIncorrect,  double accuracy,  int total,  int learning,  int mastered,  int notStarted,  double progressPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionStats() when $default != null:
return $default(_that.totalCorrect,_that.totalIncorrect,_that.accuracy,_that.total,_that.learning,_that.mastered,_that.notStarted,_that.progressPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalCorrect,  int totalIncorrect,  double accuracy,  int total,  int learning,  int mastered,  int notStarted,  double progressPercentage)  $default,) {final _that = this;
switch (_that) {
case _SessionStats():
return $default(_that.totalCorrect,_that.totalIncorrect,_that.accuracy,_that.total,_that.learning,_that.mastered,_that.notStarted,_that.progressPercentage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalCorrect,  int totalIncorrect,  double accuracy,  int total,  int learning,  int mastered,  int notStarted,  double progressPercentage)?  $default,) {final _that = this;
switch (_that) {
case _SessionStats() when $default != null:
return $default(_that.totalCorrect,_that.totalIncorrect,_that.accuracy,_that.total,_that.learning,_that.mastered,_that.notStarted,_that.progressPercentage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionStats implements SessionStats {
  const _SessionStats({this.totalCorrect = 0, this.totalIncorrect = 0, this.accuracy = 0.0, this.total = 0, this.learning = 0, this.mastered = 0, this.notStarted = 0, this.progressPercentage = 0.0});
  factory _SessionStats.fromJson(Map<String, dynamic> json) => _$SessionStatsFromJson(json);

@override@JsonKey() final  int totalCorrect;
@override@JsonKey() final  int totalIncorrect;
@override@JsonKey() final  double accuracy;
@override@JsonKey() final  int total;
@override@JsonKey() final  int learning;
@override@JsonKey() final  int mastered;
@override@JsonKey() final  int notStarted;
@override@JsonKey() final  double progressPercentage;

/// Create a copy of SessionStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStatsCopyWith<_SessionStats> get copyWith => __$SessionStatsCopyWithImpl<_SessionStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionStats&&(identical(other.totalCorrect, totalCorrect) || other.totalCorrect == totalCorrect)&&(identical(other.totalIncorrect, totalIncorrect) || other.totalIncorrect == totalIncorrect)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy)&&(identical(other.total, total) || other.total == total)&&(identical(other.learning, learning) || other.learning == learning)&&(identical(other.mastered, mastered) || other.mastered == mastered)&&(identical(other.notStarted, notStarted) || other.notStarted == notStarted)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalCorrect,totalIncorrect,accuracy,total,learning,mastered,notStarted,progressPercentage);

@override
String toString() {
  return 'SessionStats(totalCorrect: $totalCorrect, totalIncorrect: $totalIncorrect, accuracy: $accuracy, total: $total, learning: $learning, mastered: $mastered, notStarted: $notStarted, progressPercentage: $progressPercentage)';
}


}

/// @nodoc
abstract mixin class _$SessionStatsCopyWith<$Res> implements $SessionStatsCopyWith<$Res> {
  factory _$SessionStatsCopyWith(_SessionStats value, $Res Function(_SessionStats) _then) = __$SessionStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalCorrect, int totalIncorrect, double accuracy, int total, int learning, int mastered, int notStarted, double progressPercentage
});




}
/// @nodoc
class __$SessionStatsCopyWithImpl<$Res>
    implements _$SessionStatsCopyWith<$Res> {
  __$SessionStatsCopyWithImpl(this._self, this._then);

  final _SessionStats _self;
  final $Res Function(_SessionStats) _then;

/// Create a copy of SessionStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCorrect = null,Object? totalIncorrect = null,Object? accuracy = null,Object? total = null,Object? learning = null,Object? mastered = null,Object? notStarted = null,Object? progressPercentage = null,}) {
  return _then(_SessionStats(
totalCorrect: null == totalCorrect ? _self.totalCorrect : totalCorrect // ignore: cast_nullable_to_non_nullable
as int,totalIncorrect: null == totalIncorrect ? _self.totalIncorrect : totalIncorrect // ignore: cast_nullable_to_non_nullable
as int,accuracy: null == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,learning: null == learning ? _self.learning : learning // ignore: cast_nullable_to_non_nullable
as int,mastered: null == mastered ? _self.mastered : mastered // ignore: cast_nullable_to_non_nullable
as int,notStarted: null == notStarted ? _self.notStarted : notStarted // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
