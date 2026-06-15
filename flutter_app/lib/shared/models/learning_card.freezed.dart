// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learning_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LearningCard {

 String get id; String get noteValue; bool get isFlipped; CardType get cardType; int get correctStreak; int get totalCorrect; int get totalIncorrect; DateTime? get lastSeen; DateTime? get masteredAt; int get reviewCount;
/// Create a copy of LearningCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearningCardCopyWith<LearningCard> get copyWith => _$LearningCardCopyWithImpl<LearningCard>(this as LearningCard, _$identity);

  /// Serializes this LearningCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearningCard&&(identical(other.id, id) || other.id == id)&&(identical(other.noteValue, noteValue) || other.noteValue == noteValue)&&(identical(other.isFlipped, isFlipped) || other.isFlipped == isFlipped)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.correctStreak, correctStreak) || other.correctStreak == correctStreak)&&(identical(other.totalCorrect, totalCorrect) || other.totalCorrect == totalCorrect)&&(identical(other.totalIncorrect, totalIncorrect) || other.totalIncorrect == totalIncorrect)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.masteredAt, masteredAt) || other.masteredAt == masteredAt)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteValue,isFlipped,cardType,correctStreak,totalCorrect,totalIncorrect,lastSeen,masteredAt,reviewCount);

@override
String toString() {
  return 'LearningCard(id: $id, noteValue: $noteValue, isFlipped: $isFlipped, cardType: $cardType, correctStreak: $correctStreak, totalCorrect: $totalCorrect, totalIncorrect: $totalIncorrect, lastSeen: $lastSeen, masteredAt: $masteredAt, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class $LearningCardCopyWith<$Res>  {
  factory $LearningCardCopyWith(LearningCard value, $Res Function(LearningCard) _then) = _$LearningCardCopyWithImpl;
@useResult
$Res call({
 String id, String noteValue, bool isFlipped, CardType cardType, int correctStreak, int totalCorrect, int totalIncorrect, DateTime? lastSeen, DateTime? masteredAt, int reviewCount
});




}
/// @nodoc
class _$LearningCardCopyWithImpl<$Res>
    implements $LearningCardCopyWith<$Res> {
  _$LearningCardCopyWithImpl(this._self, this._then);

  final LearningCard _self;
  final $Res Function(LearningCard) _then;

/// Create a copy of LearningCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? noteValue = null,Object? isFlipped = null,Object? cardType = null,Object? correctStreak = null,Object? totalCorrect = null,Object? totalIncorrect = null,Object? lastSeen = freezed,Object? masteredAt = freezed,Object? reviewCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteValue: null == noteValue ? _self.noteValue : noteValue // ignore: cast_nullable_to_non_nullable
as String,isFlipped: null == isFlipped ? _self.isFlipped : isFlipped // ignore: cast_nullable_to_non_nullable
as bool,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as CardType,correctStreak: null == correctStreak ? _self.correctStreak : correctStreak // ignore: cast_nullable_to_non_nullable
as int,totalCorrect: null == totalCorrect ? _self.totalCorrect : totalCorrect // ignore: cast_nullable_to_non_nullable
as int,totalIncorrect: null == totalIncorrect ? _self.totalIncorrect : totalIncorrect // ignore: cast_nullable_to_non_nullable
as int,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,masteredAt: freezed == masteredAt ? _self.masteredAt : masteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LearningCard].
extension LearningCardPatterns on LearningCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearningCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearningCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearningCard value)  $default,){
final _that = this;
switch (_that) {
case _LearningCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearningCard value)?  $default,){
final _that = this;
switch (_that) {
case _LearningCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String noteValue,  bool isFlipped,  CardType cardType,  int correctStreak,  int totalCorrect,  int totalIncorrect,  DateTime? lastSeen,  DateTime? masteredAt,  int reviewCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearningCard() when $default != null:
return $default(_that.id,_that.noteValue,_that.isFlipped,_that.cardType,_that.correctStreak,_that.totalCorrect,_that.totalIncorrect,_that.lastSeen,_that.masteredAt,_that.reviewCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String noteValue,  bool isFlipped,  CardType cardType,  int correctStreak,  int totalCorrect,  int totalIncorrect,  DateTime? lastSeen,  DateTime? masteredAt,  int reviewCount)  $default,) {final _that = this;
switch (_that) {
case _LearningCard():
return $default(_that.id,_that.noteValue,_that.isFlipped,_that.cardType,_that.correctStreak,_that.totalCorrect,_that.totalIncorrect,_that.lastSeen,_that.masteredAt,_that.reviewCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String noteValue,  bool isFlipped,  CardType cardType,  int correctStreak,  int totalCorrect,  int totalIncorrect,  DateTime? lastSeen,  DateTime? masteredAt,  int reviewCount)?  $default,) {final _that = this;
switch (_that) {
case _LearningCard() when $default != null:
return $default(_that.id,_that.noteValue,_that.isFlipped,_that.cardType,_that.correctStreak,_that.totalCorrect,_that.totalIncorrect,_that.lastSeen,_that.masteredAt,_that.reviewCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearningCard implements LearningCard {
  const _LearningCard({required this.id, required this.noteValue, this.isFlipped = false, this.cardType = CardType.newCard, this.correctStreak = 0, this.totalCorrect = 0, this.totalIncorrect = 0, this.lastSeen, this.masteredAt, this.reviewCount = 0});
  factory _LearningCard.fromJson(Map<String, dynamic> json) => _$LearningCardFromJson(json);

@override final  String id;
@override final  String noteValue;
@override@JsonKey() final  bool isFlipped;
@override@JsonKey() final  CardType cardType;
@override@JsonKey() final  int correctStreak;
@override@JsonKey() final  int totalCorrect;
@override@JsonKey() final  int totalIncorrect;
@override final  DateTime? lastSeen;
@override final  DateTime? masteredAt;
@override@JsonKey() final  int reviewCount;

/// Create a copy of LearningCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearningCardCopyWith<_LearningCard> get copyWith => __$LearningCardCopyWithImpl<_LearningCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearningCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearningCard&&(identical(other.id, id) || other.id == id)&&(identical(other.noteValue, noteValue) || other.noteValue == noteValue)&&(identical(other.isFlipped, isFlipped) || other.isFlipped == isFlipped)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.correctStreak, correctStreak) || other.correctStreak == correctStreak)&&(identical(other.totalCorrect, totalCorrect) || other.totalCorrect == totalCorrect)&&(identical(other.totalIncorrect, totalIncorrect) || other.totalIncorrect == totalIncorrect)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen)&&(identical(other.masteredAt, masteredAt) || other.masteredAt == masteredAt)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteValue,isFlipped,cardType,correctStreak,totalCorrect,totalIncorrect,lastSeen,masteredAt,reviewCount);

@override
String toString() {
  return 'LearningCard(id: $id, noteValue: $noteValue, isFlipped: $isFlipped, cardType: $cardType, correctStreak: $correctStreak, totalCorrect: $totalCorrect, totalIncorrect: $totalIncorrect, lastSeen: $lastSeen, masteredAt: $masteredAt, reviewCount: $reviewCount)';
}


}

/// @nodoc
abstract mixin class _$LearningCardCopyWith<$Res> implements $LearningCardCopyWith<$Res> {
  factory _$LearningCardCopyWith(_LearningCard value, $Res Function(_LearningCard) _then) = __$LearningCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String noteValue, bool isFlipped, CardType cardType, int correctStreak, int totalCorrect, int totalIncorrect, DateTime? lastSeen, DateTime? masteredAt, int reviewCount
});




}
/// @nodoc
class __$LearningCardCopyWithImpl<$Res>
    implements _$LearningCardCopyWith<$Res> {
  __$LearningCardCopyWithImpl(this._self, this._then);

  final _LearningCard _self;
  final $Res Function(_LearningCard) _then;

/// Create a copy of LearningCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? noteValue = null,Object? isFlipped = null,Object? cardType = null,Object? correctStreak = null,Object? totalCorrect = null,Object? totalIncorrect = null,Object? lastSeen = freezed,Object? masteredAt = freezed,Object? reviewCount = null,}) {
  return _then(_LearningCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteValue: null == noteValue ? _self.noteValue : noteValue // ignore: cast_nullable_to_non_nullable
as String,isFlipped: null == isFlipped ? _self.isFlipped : isFlipped // ignore: cast_nullable_to_non_nullable
as bool,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as CardType,correctStreak: null == correctStreak ? _self.correctStreak : correctStreak // ignore: cast_nullable_to_non_nullable
as int,totalCorrect: null == totalCorrect ? _self.totalCorrect : totalCorrect // ignore: cast_nullable_to_non_nullable
as int,totalIncorrect: null == totalIncorrect ? _self.totalIncorrect : totalIncorrect // ignore: cast_nullable_to_non_nullable
as int,lastSeen: freezed == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime?,masteredAt: freezed == masteredAt ? _self.masteredAt : masteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
