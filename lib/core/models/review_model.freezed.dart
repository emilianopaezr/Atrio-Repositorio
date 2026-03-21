// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Review {

 String get id;@JsonKey(name: 'booking_id') String get bookingId;@JsonKey(name: 'listing_id') String get listingId;@JsonKey(name: 'reviewer_id') String get reviewerId;@JsonKey(name: 'host_id') String get hostId; int get rating; String? get comment;@JsonKey(name: 'host_reply') String? get hostReply;@JsonKey(name: 'host_reply_at') DateTime? get hostReplyAt;@JsonKey(name: 'created_at') DateTime? get createdAt;// Joined data
@JsonKey(name: 'reviewer') Map<String, dynamic>? get reviewerData;
/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewCopyWith<Review> get copyWith => _$ReviewCopyWithImpl<Review>(this as Review, _$identity);

  /// Serializes this Review to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Review&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.hostReply, hostReply) || other.hostReply == hostReply)&&(identical(other.hostReplyAt, hostReplyAt) || other.hostReplyAt == hostReplyAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.reviewerData, reviewerData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,listingId,reviewerId,hostId,rating,comment,hostReply,hostReplyAt,createdAt,const DeepCollectionEquality().hash(reviewerData));

@override
String toString() {
  return 'Review(id: $id, bookingId: $bookingId, listingId: $listingId, reviewerId: $reviewerId, hostId: $hostId, rating: $rating, comment: $comment, hostReply: $hostReply, hostReplyAt: $hostReplyAt, createdAt: $createdAt, reviewerData: $reviewerData)';
}


}

/// @nodoc
abstract mixin class $ReviewCopyWith<$Res>  {
  factory $ReviewCopyWith(Review value, $Res Function(Review) _then) = _$ReviewCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'booking_id') String bookingId,@JsonKey(name: 'listing_id') String listingId,@JsonKey(name: 'reviewer_id') String reviewerId,@JsonKey(name: 'host_id') String hostId, int rating, String? comment,@JsonKey(name: 'host_reply') String? hostReply,@JsonKey(name: 'host_reply_at') DateTime? hostReplyAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'reviewer') Map<String, dynamic>? reviewerData
});




}
/// @nodoc
class _$ReviewCopyWithImpl<$Res>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._self, this._then);

  final Review _self;
  final $Res Function(Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? listingId = null,Object? reviewerId = null,Object? hostId = null,Object? rating = null,Object? comment = freezed,Object? hostReply = freezed,Object? hostReplyAt = freezed,Object? createdAt = freezed,Object? reviewerData = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,listingId: null == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,hostReply: freezed == hostReply ? _self.hostReply : hostReply // ignore: cast_nullable_to_non_nullable
as String?,hostReplyAt: freezed == hostReplyAt ? _self.hostReplyAt : hostReplyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewerData: freezed == reviewerData ? _self.reviewerData : reviewerData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Review].
extension ReviewPatterns on Review {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Review value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Review value)  $default,){
final _that = this;
switch (_that) {
case _Review():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Review value)?  $default,){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'host_id')  String hostId,  int rating,  String? comment, @JsonKey(name: 'host_reply')  String? hostReply, @JsonKey(name: 'host_reply_at')  DateTime? hostReplyAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'reviewer')  Map<String, dynamic>? reviewerData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.id,_that.bookingId,_that.listingId,_that.reviewerId,_that.hostId,_that.rating,_that.comment,_that.hostReply,_that.hostReplyAt,_that.createdAt,_that.reviewerData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'host_id')  String hostId,  int rating,  String? comment, @JsonKey(name: 'host_reply')  String? hostReply, @JsonKey(name: 'host_reply_at')  DateTime? hostReplyAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'reviewer')  Map<String, dynamic>? reviewerData)  $default,) {final _that = this;
switch (_that) {
case _Review():
return $default(_that.id,_that.bookingId,_that.listingId,_that.reviewerId,_that.hostId,_that.rating,_that.comment,_that.hostReply,_that.hostReplyAt,_that.createdAt,_that.reviewerData);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'booking_id')  String bookingId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'host_id')  String hostId,  int rating,  String? comment, @JsonKey(name: 'host_reply')  String? hostReply, @JsonKey(name: 'host_reply_at')  DateTime? hostReplyAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'reviewer')  Map<String, dynamic>? reviewerData)?  $default,) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.id,_that.bookingId,_that.listingId,_that.reviewerId,_that.hostId,_that.rating,_that.comment,_that.hostReply,_that.hostReplyAt,_that.createdAt,_that.reviewerData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Review implements Review {
  const _Review({required this.id, @JsonKey(name: 'booking_id') required this.bookingId, @JsonKey(name: 'listing_id') required this.listingId, @JsonKey(name: 'reviewer_id') required this.reviewerId, @JsonKey(name: 'host_id') required this.hostId, required this.rating, this.comment, @JsonKey(name: 'host_reply') this.hostReply, @JsonKey(name: 'host_reply_at') this.hostReplyAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'reviewer') final  Map<String, dynamic>? reviewerData}): _reviewerData = reviewerData;
  factory _Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

@override final  String id;
@override@JsonKey(name: 'booking_id') final  String bookingId;
@override@JsonKey(name: 'listing_id') final  String listingId;
@override@JsonKey(name: 'reviewer_id') final  String reviewerId;
@override@JsonKey(name: 'host_id') final  String hostId;
@override final  int rating;
@override final  String? comment;
@override@JsonKey(name: 'host_reply') final  String? hostReply;
@override@JsonKey(name: 'host_reply_at') final  DateTime? hostReplyAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
// Joined data
 final  Map<String, dynamic>? _reviewerData;
// Joined data
@override@JsonKey(name: 'reviewer') Map<String, dynamic>? get reviewerData {
  final value = _reviewerData;
  if (value == null) return null;
  if (_reviewerData is EqualUnmodifiableMapView) return _reviewerData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewCopyWith<_Review> get copyWith => __$ReviewCopyWithImpl<_Review>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Review&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.hostReply, hostReply) || other.hostReply == hostReply)&&(identical(other.hostReplyAt, hostReplyAt) || other.hostReplyAt == hostReplyAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._reviewerData, _reviewerData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,listingId,reviewerId,hostId,rating,comment,hostReply,hostReplyAt,createdAt,const DeepCollectionEquality().hash(_reviewerData));

@override
String toString() {
  return 'Review(id: $id, bookingId: $bookingId, listingId: $listingId, reviewerId: $reviewerId, hostId: $hostId, rating: $rating, comment: $comment, hostReply: $hostReply, hostReplyAt: $hostReplyAt, createdAt: $createdAt, reviewerData: $reviewerData)';
}


}

/// @nodoc
abstract mixin class _$ReviewCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$ReviewCopyWith(_Review value, $Res Function(_Review) _then) = __$ReviewCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'booking_id') String bookingId,@JsonKey(name: 'listing_id') String listingId,@JsonKey(name: 'reviewer_id') String reviewerId,@JsonKey(name: 'host_id') String hostId, int rating, String? comment,@JsonKey(name: 'host_reply') String? hostReply,@JsonKey(name: 'host_reply_at') DateTime? hostReplyAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'reviewer') Map<String, dynamic>? reviewerData
});




}
/// @nodoc
class __$ReviewCopyWithImpl<$Res>
    implements _$ReviewCopyWith<$Res> {
  __$ReviewCopyWithImpl(this._self, this._then);

  final _Review _self;
  final $Res Function(_Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? listingId = null,Object? reviewerId = null,Object? hostId = null,Object? rating = null,Object? comment = freezed,Object? hostReply = freezed,Object? hostReplyAt = freezed,Object? createdAt = freezed,Object? reviewerData = freezed,}) {
  return _then(_Review(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,listingId: null == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,hostReply: freezed == hostReply ? _self.hostReply : hostReply // ignore: cast_nullable_to_non_nullable
as String?,hostReplyAt: freezed == hostReplyAt ? _self.hostReplyAt : hostReplyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewerData: freezed == reviewerData ? _self._reviewerData : reviewerData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
