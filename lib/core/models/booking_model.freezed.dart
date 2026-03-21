// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Booking {

 String get id;@JsonKey(name: 'guest_id') String get guestId;@JsonKey(name: 'host_id') String get hostId;@JsonKey(name: 'listing_id') String get listingId;@JsonKey(name: 'check_in') DateTime get checkIn;@JsonKey(name: 'check_out') DateTime get checkOut;@JsonKey(name: 'guests_count') int get guestsCount;@JsonKey(name: 'base_total') double? get baseTotal;@JsonKey(name: 'cleaning_fee') double get cleaningFee;@JsonKey(name: 'service_fee') double get serviceFee; double? get total; String get status;@JsonKey(name: 'payment_status') String get paymentStatus;@JsonKey(name: 'special_requests') String? get specialRequests;@JsonKey(name: 'conversation_id') String? get conversationId;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;// Joined data
@JsonKey(name: 'listing') Map<String, dynamic>? get listingData;@JsonKey(name: 'guest') Map<String, dynamic>? get guestData;@JsonKey(name: 'host') Map<String, dynamic>? get hostProfileData;
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCopyWith<Booking> get copyWith => _$BookingCopyWithImpl<Booking>(this as Booking, _$identity);

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.guestsCount, guestsCount) || other.guestsCount == guestsCount)&&(identical(other.baseTotal, baseTotal) || other.baseTotal == baseTotal)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.total, total) || other.total == total)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.specialRequests, specialRequests) || other.specialRequests == specialRequests)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.listingData, listingData)&&const DeepCollectionEquality().equals(other.guestData, guestData)&&const DeepCollectionEquality().equals(other.hostProfileData, hostProfileData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,guestId,hostId,listingId,checkIn,checkOut,guestsCount,baseTotal,cleaningFee,serviceFee,total,status,paymentStatus,specialRequests,conversationId,createdAt,updatedAt,const DeepCollectionEquality().hash(listingData),const DeepCollectionEquality().hash(guestData),const DeepCollectionEquality().hash(hostProfileData)]);

@override
String toString() {
  return 'Booking(id: $id, guestId: $guestId, hostId: $hostId, listingId: $listingId, checkIn: $checkIn, checkOut: $checkOut, guestsCount: $guestsCount, baseTotal: $baseTotal, cleaningFee: $cleaningFee, serviceFee: $serviceFee, total: $total, status: $status, paymentStatus: $paymentStatus, specialRequests: $specialRequests, conversationId: $conversationId, createdAt: $createdAt, updatedAt: $updatedAt, listingData: $listingData, guestData: $guestData, hostProfileData: $hostProfileData)';
}


}

/// @nodoc
abstract mixin class $BookingCopyWith<$Res>  {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) _then) = _$BookingCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'guest_id') String guestId,@JsonKey(name: 'host_id') String hostId,@JsonKey(name: 'listing_id') String listingId,@JsonKey(name: 'check_in') DateTime checkIn,@JsonKey(name: 'check_out') DateTime checkOut,@JsonKey(name: 'guests_count') int guestsCount,@JsonKey(name: 'base_total') double? baseTotal,@JsonKey(name: 'cleaning_fee') double cleaningFee,@JsonKey(name: 'service_fee') double serviceFee, double? total, String status,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'special_requests') String? specialRequests,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'listing') Map<String, dynamic>? listingData,@JsonKey(name: 'guest') Map<String, dynamic>? guestData,@JsonKey(name: 'host') Map<String, dynamic>? hostProfileData
});




}
/// @nodoc
class _$BookingCopyWithImpl<$Res>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._self, this._then);

  final Booking _self;
  final $Res Function(Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? guestId = null,Object? hostId = null,Object? listingId = null,Object? checkIn = null,Object? checkOut = null,Object? guestsCount = null,Object? baseTotal = freezed,Object? cleaningFee = null,Object? serviceFee = null,Object? total = freezed,Object? status = null,Object? paymentStatus = null,Object? specialRequests = freezed,Object? conversationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? listingData = freezed,Object? guestData = freezed,Object? hostProfileData = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,guestId: null == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,listingId: null == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,guestsCount: null == guestsCount ? _self.guestsCount : guestsCount // ignore: cast_nullable_to_non_nullable
as int,baseTotal: freezed == baseTotal ? _self.baseTotal : baseTotal // ignore: cast_nullable_to_non_nullable
as double?,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,serviceFee: null == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,specialRequests: freezed == specialRequests ? _self.specialRequests : specialRequests // ignore: cast_nullable_to_non_nullable
as String?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,listingData: freezed == listingData ? _self.listingData : listingData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,guestData: freezed == guestData ? _self.guestData : guestData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,hostProfileData: freezed == hostProfileData ? _self.hostProfileData : hostProfileData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Booking].
extension BookingPatterns on Booking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Booking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Booking value)  $default,){
final _that = this;
switch (_that) {
case _Booking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Booking value)?  $default,){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'guest_id')  String guestId, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'check_in')  DateTime checkIn, @JsonKey(name: 'check_out')  DateTime checkOut, @JsonKey(name: 'guests_count')  int guestsCount, @JsonKey(name: 'base_total')  double? baseTotal, @JsonKey(name: 'cleaning_fee')  double cleaningFee, @JsonKey(name: 'service_fee')  double serviceFee,  double? total,  String status, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'special_requests')  String? specialRequests, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'listing')  Map<String, dynamic>? listingData, @JsonKey(name: 'guest')  Map<String, dynamic>? guestData, @JsonKey(name: 'host')  Map<String, dynamic>? hostProfileData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.guestId,_that.hostId,_that.listingId,_that.checkIn,_that.checkOut,_that.guestsCount,_that.baseTotal,_that.cleaningFee,_that.serviceFee,_that.total,_that.status,_that.paymentStatus,_that.specialRequests,_that.conversationId,_that.createdAt,_that.updatedAt,_that.listingData,_that.guestData,_that.hostProfileData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'guest_id')  String guestId, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'check_in')  DateTime checkIn, @JsonKey(name: 'check_out')  DateTime checkOut, @JsonKey(name: 'guests_count')  int guestsCount, @JsonKey(name: 'base_total')  double? baseTotal, @JsonKey(name: 'cleaning_fee')  double cleaningFee, @JsonKey(name: 'service_fee')  double serviceFee,  double? total,  String status, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'special_requests')  String? specialRequests, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'listing')  Map<String, dynamic>? listingData, @JsonKey(name: 'guest')  Map<String, dynamic>? guestData, @JsonKey(name: 'host')  Map<String, dynamic>? hostProfileData)  $default,) {final _that = this;
switch (_that) {
case _Booking():
return $default(_that.id,_that.guestId,_that.hostId,_that.listingId,_that.checkIn,_that.checkOut,_that.guestsCount,_that.baseTotal,_that.cleaningFee,_that.serviceFee,_that.total,_that.status,_that.paymentStatus,_that.specialRequests,_that.conversationId,_that.createdAt,_that.updatedAt,_that.listingData,_that.guestData,_that.hostProfileData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'guest_id')  String guestId, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'listing_id')  String listingId, @JsonKey(name: 'check_in')  DateTime checkIn, @JsonKey(name: 'check_out')  DateTime checkOut, @JsonKey(name: 'guests_count')  int guestsCount, @JsonKey(name: 'base_total')  double? baseTotal, @JsonKey(name: 'cleaning_fee')  double cleaningFee, @JsonKey(name: 'service_fee')  double serviceFee,  double? total,  String status, @JsonKey(name: 'payment_status')  String paymentStatus, @JsonKey(name: 'special_requests')  String? specialRequests, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'listing')  Map<String, dynamic>? listingData, @JsonKey(name: 'guest')  Map<String, dynamic>? guestData, @JsonKey(name: 'host')  Map<String, dynamic>? hostProfileData)?  $default,) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.guestId,_that.hostId,_that.listingId,_that.checkIn,_that.checkOut,_that.guestsCount,_that.baseTotal,_that.cleaningFee,_that.serviceFee,_that.total,_that.status,_that.paymentStatus,_that.specialRequests,_that.conversationId,_that.createdAt,_that.updatedAt,_that.listingData,_that.guestData,_that.hostProfileData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Booking implements Booking {
  const _Booking({required this.id, @JsonKey(name: 'guest_id') required this.guestId, @JsonKey(name: 'host_id') required this.hostId, @JsonKey(name: 'listing_id') required this.listingId, @JsonKey(name: 'check_in') required this.checkIn, @JsonKey(name: 'check_out') required this.checkOut, @JsonKey(name: 'guests_count') this.guestsCount = 1, @JsonKey(name: 'base_total') this.baseTotal, @JsonKey(name: 'cleaning_fee') this.cleaningFee = 0, @JsonKey(name: 'service_fee') this.serviceFee = 0, this.total, this.status = 'pending', @JsonKey(name: 'payment_status') this.paymentStatus = 'pending', @JsonKey(name: 'special_requests') this.specialRequests, @JsonKey(name: 'conversation_id') this.conversationId, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'listing') final  Map<String, dynamic>? listingData, @JsonKey(name: 'guest') final  Map<String, dynamic>? guestData, @JsonKey(name: 'host') final  Map<String, dynamic>? hostProfileData}): _listingData = listingData,_guestData = guestData,_hostProfileData = hostProfileData;
  factory _Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

@override final  String id;
@override@JsonKey(name: 'guest_id') final  String guestId;
@override@JsonKey(name: 'host_id') final  String hostId;
@override@JsonKey(name: 'listing_id') final  String listingId;
@override@JsonKey(name: 'check_in') final  DateTime checkIn;
@override@JsonKey(name: 'check_out') final  DateTime checkOut;
@override@JsonKey(name: 'guests_count') final  int guestsCount;
@override@JsonKey(name: 'base_total') final  double? baseTotal;
@override@JsonKey(name: 'cleaning_fee') final  double cleaningFee;
@override@JsonKey(name: 'service_fee') final  double serviceFee;
@override final  double? total;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'payment_status') final  String paymentStatus;
@override@JsonKey(name: 'special_requests') final  String? specialRequests;
@override@JsonKey(name: 'conversation_id') final  String? conversationId;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
// Joined data
 final  Map<String, dynamic>? _listingData;
// Joined data
@override@JsonKey(name: 'listing') Map<String, dynamic>? get listingData {
  final value = _listingData;
  if (value == null) return null;
  if (_listingData is EqualUnmodifiableMapView) return _listingData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _guestData;
@override@JsonKey(name: 'guest') Map<String, dynamic>? get guestData {
  final value = _guestData;
  if (value == null) return null;
  if (_guestData is EqualUnmodifiableMapView) return _guestData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _hostProfileData;
@override@JsonKey(name: 'host') Map<String, dynamic>? get hostProfileData {
  final value = _hostProfileData;
  if (value == null) return null;
  if (_hostProfileData is EqualUnmodifiableMapView) return _hostProfileData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCopyWith<_Booking> get copyWith => __$BookingCopyWithImpl<_Booking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.guestId, guestId) || other.guestId == guestId)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.guestsCount, guestsCount) || other.guestsCount == guestsCount)&&(identical(other.baseTotal, baseTotal) || other.baseTotal == baseTotal)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.total, total) || other.total == total)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.specialRequests, specialRequests) || other.specialRequests == specialRequests)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._listingData, _listingData)&&const DeepCollectionEquality().equals(other._guestData, _guestData)&&const DeepCollectionEquality().equals(other._hostProfileData, _hostProfileData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,guestId,hostId,listingId,checkIn,checkOut,guestsCount,baseTotal,cleaningFee,serviceFee,total,status,paymentStatus,specialRequests,conversationId,createdAt,updatedAt,const DeepCollectionEquality().hash(_listingData),const DeepCollectionEquality().hash(_guestData),const DeepCollectionEquality().hash(_hostProfileData)]);

@override
String toString() {
  return 'Booking(id: $id, guestId: $guestId, hostId: $hostId, listingId: $listingId, checkIn: $checkIn, checkOut: $checkOut, guestsCount: $guestsCount, baseTotal: $baseTotal, cleaningFee: $cleaningFee, serviceFee: $serviceFee, total: $total, status: $status, paymentStatus: $paymentStatus, specialRequests: $specialRequests, conversationId: $conversationId, createdAt: $createdAt, updatedAt: $updatedAt, listingData: $listingData, guestData: $guestData, hostProfileData: $hostProfileData)';
}


}

/// @nodoc
abstract mixin class _$BookingCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$BookingCopyWith(_Booking value, $Res Function(_Booking) _then) = __$BookingCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'guest_id') String guestId,@JsonKey(name: 'host_id') String hostId,@JsonKey(name: 'listing_id') String listingId,@JsonKey(name: 'check_in') DateTime checkIn,@JsonKey(name: 'check_out') DateTime checkOut,@JsonKey(name: 'guests_count') int guestsCount,@JsonKey(name: 'base_total') double? baseTotal,@JsonKey(name: 'cleaning_fee') double cleaningFee,@JsonKey(name: 'service_fee') double serviceFee, double? total, String status,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'special_requests') String? specialRequests,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'listing') Map<String, dynamic>? listingData,@JsonKey(name: 'guest') Map<String, dynamic>? guestData,@JsonKey(name: 'host') Map<String, dynamic>? hostProfileData
});




}
/// @nodoc
class __$BookingCopyWithImpl<$Res>
    implements _$BookingCopyWith<$Res> {
  __$BookingCopyWithImpl(this._self, this._then);

  final _Booking _self;
  final $Res Function(_Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? guestId = null,Object? hostId = null,Object? listingId = null,Object? checkIn = null,Object? checkOut = null,Object? guestsCount = null,Object? baseTotal = freezed,Object? cleaningFee = null,Object? serviceFee = null,Object? total = freezed,Object? status = null,Object? paymentStatus = null,Object? specialRequests = freezed,Object? conversationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? listingData = freezed,Object? guestData = freezed,Object? hostProfileData = freezed,}) {
  return _then(_Booking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,guestId: null == guestId ? _self.guestId : guestId // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,listingId: null == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,guestsCount: null == guestsCount ? _self.guestsCount : guestsCount // ignore: cast_nullable_to_non_nullable
as int,baseTotal: freezed == baseTotal ? _self.baseTotal : baseTotal // ignore: cast_nullable_to_non_nullable
as double?,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,serviceFee: null == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,specialRequests: freezed == specialRequests ? _self.specialRequests : specialRequests // ignore: cast_nullable_to_non_nullable
as String?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,listingData: freezed == listingData ? _self._listingData : listingData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,guestData: freezed == guestData ? _self._guestData : guestData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,hostProfileData: freezed == hostProfileData ? _self._hostProfileData : hostProfileData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
