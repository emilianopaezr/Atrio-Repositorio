// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Listing {

 String get id;@JsonKey(name: 'host_id') String get hostId; String get type; String get title; String? get description; List<String> get images; String? get category; List<String> get tags; List<String> get amenities; String? get address; String? get city; String? get country; double? get latitude; double? get longitude;@JsonKey(name: 'base_price') double? get basePrice; String get currency;@JsonKey(name: 'price_unit') String get priceUnit;@JsonKey(name: 'cleaning_fee') double get cleaningFee; int? get capacity; String get status; double get rating;@JsonKey(name: 'review_count') int get reviewCount;@JsonKey(name: 'view_count') int get viewCount;@JsonKey(name: 'is_featured') bool get isFeatured;// V2: Booking system fields
@JsonKey(name: 'rental_mode') String get rentalMode;@JsonKey(name: 'available_days') List<int> get availableDays;@JsonKey(name: 'available_from') String? get availableFrom;@JsonKey(name: 'available_until') String? get availableUntil;@JsonKey(name: 'min_hours') int get minHours;@JsonKey(name: 'max_hours') int get maxHours;@JsonKey(name: 'min_nights') int get minNights;@JsonKey(name: 'max_nights') int get maxNights;@JsonKey(name: 'slot_duration_minutes') int get slotDurationMinutes;@JsonKey(name: 'block_hours') int get blockHours;@JsonKey(name: 'max_capacity') int? get maxCapacity;@JsonKey(name: 'instant_booking') bool get instantBooking;@JsonKey(name: 'check_in_time') String? get checkInTime;@JsonKey(name: 'check_out_time') String? get checkOutTime;@JsonKey(name: 'cancellation_policy') String get cancellationPolicy;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;// Joined data
@JsonKey(name: 'host') Map<String, dynamic>? get hostData;
/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListingCopyWith<Listing> get copyWith => _$ListingCopyWithImpl<Listing>(this as Listing, _$identity);

  /// Serializes this Listing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Listing&&(identical(other.id, id) || other.id == id)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.priceUnit, priceUnit) || other.priceUnit == priceUnit)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.rentalMode, rentalMode) || other.rentalMode == rentalMode)&&const DeepCollectionEquality().equals(other.availableDays, availableDays)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.availableUntil, availableUntil) || other.availableUntil == availableUntil)&&(identical(other.minHours, minHours) || other.minHours == minHours)&&(identical(other.maxHours, maxHours) || other.maxHours == maxHours)&&(identical(other.minNights, minNights) || other.minNights == minNights)&&(identical(other.maxNights, maxNights) || other.maxNights == maxNights)&&(identical(other.slotDurationMinutes, slotDurationMinutes) || other.slotDurationMinutes == slotDurationMinutes)&&(identical(other.blockHours, blockHours) || other.blockHours == blockHours)&&(identical(other.maxCapacity, maxCapacity) || other.maxCapacity == maxCapacity)&&(identical(other.instantBooking, instantBooking) || other.instantBooking == instantBooking)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.checkOutTime, checkOutTime) || other.checkOutTime == checkOutTime)&&(identical(other.cancellationPolicy, cancellationPolicy) || other.cancellationPolicy == cancellationPolicy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.hostData, hostData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,hostId,type,title,description,const DeepCollectionEquality().hash(images),category,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(amenities),address,city,country,latitude,longitude,basePrice,currency,priceUnit,cleaningFee,capacity,status,rating,reviewCount,viewCount,isFeatured,rentalMode,const DeepCollectionEquality().hash(availableDays),availableFrom,availableUntil,minHours,maxHours,minNights,maxNights,slotDurationMinutes,blockHours,maxCapacity,instantBooking,checkInTime,checkOutTime,cancellationPolicy,createdAt,updatedAt,const DeepCollectionEquality().hash(hostData)]);

@override
String toString() {
  return 'Listing(id: $id, hostId: $hostId, type: $type, title: $title, description: $description, images: $images, category: $category, tags: $tags, amenities: $amenities, address: $address, city: $city, country: $country, latitude: $latitude, longitude: $longitude, basePrice: $basePrice, currency: $currency, priceUnit: $priceUnit, cleaningFee: $cleaningFee, capacity: $capacity, status: $status, rating: $rating, reviewCount: $reviewCount, viewCount: $viewCount, isFeatured: $isFeatured, rentalMode: $rentalMode, availableDays: $availableDays, availableFrom: $availableFrom, availableUntil: $availableUntil, minHours: $minHours, maxHours: $maxHours, minNights: $minNights, maxNights: $maxNights, slotDurationMinutes: $slotDurationMinutes, blockHours: $blockHours, maxCapacity: $maxCapacity, instantBooking: $instantBooking, checkInTime: $checkInTime, checkOutTime: $checkOutTime, cancellationPolicy: $cancellationPolicy, createdAt: $createdAt, updatedAt: $updatedAt, hostData: $hostData)';
}


}

/// @nodoc
abstract mixin class $ListingCopyWith<$Res>  {
  factory $ListingCopyWith(Listing value, $Res Function(Listing) _then) = _$ListingCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'host_id') String hostId, String type, String title, String? description, List<String> images, String? category, List<String> tags, List<String> amenities, String? address, String? city, String? country, double? latitude, double? longitude,@JsonKey(name: 'base_price') double? basePrice, String currency,@JsonKey(name: 'price_unit') String priceUnit,@JsonKey(name: 'cleaning_fee') double cleaningFee, int? capacity, String status, double rating,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'view_count') int viewCount,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'rental_mode') String rentalMode,@JsonKey(name: 'available_days') List<int> availableDays,@JsonKey(name: 'available_from') String? availableFrom,@JsonKey(name: 'available_until') String? availableUntil,@JsonKey(name: 'min_hours') int minHours,@JsonKey(name: 'max_hours') int maxHours,@JsonKey(name: 'min_nights') int minNights,@JsonKey(name: 'max_nights') int maxNights,@JsonKey(name: 'slot_duration_minutes') int slotDurationMinutes,@JsonKey(name: 'block_hours') int blockHours,@JsonKey(name: 'max_capacity') int? maxCapacity,@JsonKey(name: 'instant_booking') bool instantBooking,@JsonKey(name: 'check_in_time') String? checkInTime,@JsonKey(name: 'check_out_time') String? checkOutTime,@JsonKey(name: 'cancellation_policy') String cancellationPolicy,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'host') Map<String, dynamic>? hostData
});




}
/// @nodoc
class _$ListingCopyWithImpl<$Res>
    implements $ListingCopyWith<$Res> {
  _$ListingCopyWithImpl(this._self, this._then);

  final Listing _self;
  final $Res Function(Listing) _then;

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostId = null,Object? type = null,Object? title = null,Object? description = freezed,Object? images = null,Object? category = freezed,Object? tags = null,Object? amenities = null,Object? address = freezed,Object? city = freezed,Object? country = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? basePrice = freezed,Object? currency = null,Object? priceUnit = null,Object? cleaningFee = null,Object? capacity = freezed,Object? status = null,Object? rating = null,Object? reviewCount = null,Object? viewCount = null,Object? isFeatured = null,Object? rentalMode = null,Object? availableDays = null,Object? availableFrom = freezed,Object? availableUntil = freezed,Object? minHours = null,Object? maxHours = null,Object? minNights = null,Object? maxNights = null,Object? slotDurationMinutes = null,Object? blockHours = null,Object? maxCapacity = freezed,Object? instantBooking = null,Object? checkInTime = freezed,Object? checkOutTime = freezed,Object? cancellationPolicy = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? hostData = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,basePrice: freezed == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,priceUnit: null == priceUnit ? _self.priceUnit : priceUnit // ignore: cast_nullable_to_non_nullable
as String,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,rentalMode: null == rentalMode ? _self.rentalMode : rentalMode // ignore: cast_nullable_to_non_nullable
as String,availableDays: null == availableDays ? _self.availableDays : availableDays // ignore: cast_nullable_to_non_nullable
as List<int>,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,availableUntil: freezed == availableUntil ? _self.availableUntil : availableUntil // ignore: cast_nullable_to_non_nullable
as String?,minHours: null == minHours ? _self.minHours : minHours // ignore: cast_nullable_to_non_nullable
as int,maxHours: null == maxHours ? _self.maxHours : maxHours // ignore: cast_nullable_to_non_nullable
as int,minNights: null == minNights ? _self.minNights : minNights // ignore: cast_nullable_to_non_nullable
as int,maxNights: null == maxNights ? _self.maxNights : maxNights // ignore: cast_nullable_to_non_nullable
as int,slotDurationMinutes: null == slotDurationMinutes ? _self.slotDurationMinutes : slotDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,blockHours: null == blockHours ? _self.blockHours : blockHours // ignore: cast_nullable_to_non_nullable
as int,maxCapacity: freezed == maxCapacity ? _self.maxCapacity : maxCapacity // ignore: cast_nullable_to_non_nullable
as int?,instantBooking: null == instantBooking ? _self.instantBooking : instantBooking // ignore: cast_nullable_to_non_nullable
as bool,checkInTime: freezed == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as String?,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as String?,cancellationPolicy: null == cancellationPolicy ? _self.cancellationPolicy : cancellationPolicy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hostData: freezed == hostData ? _self.hostData : hostData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Listing].
extension ListingPatterns on Listing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Listing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Listing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Listing value)  $default,){
final _that = this;
switch (_that) {
case _Listing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Listing value)?  $default,){
final _that = this;
switch (_that) {
case _Listing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'host_id')  String hostId,  String type,  String title,  String? description,  List<String> images,  String? category,  List<String> tags,  List<String> amenities,  String? address,  String? city,  String? country,  double? latitude,  double? longitude, @JsonKey(name: 'base_price')  double? basePrice,  String currency, @JsonKey(name: 'price_unit')  String priceUnit, @JsonKey(name: 'cleaning_fee')  double cleaningFee,  int? capacity,  String status,  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'rental_mode')  String rentalMode, @JsonKey(name: 'available_days')  List<int> availableDays, @JsonKey(name: 'available_from')  String? availableFrom, @JsonKey(name: 'available_until')  String? availableUntil, @JsonKey(name: 'min_hours')  int minHours, @JsonKey(name: 'max_hours')  int maxHours, @JsonKey(name: 'min_nights')  int minNights, @JsonKey(name: 'max_nights')  int maxNights, @JsonKey(name: 'slot_duration_minutes')  int slotDurationMinutes, @JsonKey(name: 'block_hours')  int blockHours, @JsonKey(name: 'max_capacity')  int? maxCapacity, @JsonKey(name: 'instant_booking')  bool instantBooking, @JsonKey(name: 'check_in_time')  String? checkInTime, @JsonKey(name: 'check_out_time')  String? checkOutTime, @JsonKey(name: 'cancellation_policy')  String cancellationPolicy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'host')  Map<String, dynamic>? hostData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Listing() when $default != null:
return $default(_that.id,_that.hostId,_that.type,_that.title,_that.description,_that.images,_that.category,_that.tags,_that.amenities,_that.address,_that.city,_that.country,_that.latitude,_that.longitude,_that.basePrice,_that.currency,_that.priceUnit,_that.cleaningFee,_that.capacity,_that.status,_that.rating,_that.reviewCount,_that.viewCount,_that.isFeatured,_that.rentalMode,_that.availableDays,_that.availableFrom,_that.availableUntil,_that.minHours,_that.maxHours,_that.minNights,_that.maxNights,_that.slotDurationMinutes,_that.blockHours,_that.maxCapacity,_that.instantBooking,_that.checkInTime,_that.checkOutTime,_that.cancellationPolicy,_that.createdAt,_that.updatedAt,_that.hostData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'host_id')  String hostId,  String type,  String title,  String? description,  List<String> images,  String? category,  List<String> tags,  List<String> amenities,  String? address,  String? city,  String? country,  double? latitude,  double? longitude, @JsonKey(name: 'base_price')  double? basePrice,  String currency, @JsonKey(name: 'price_unit')  String priceUnit, @JsonKey(name: 'cleaning_fee')  double cleaningFee,  int? capacity,  String status,  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'rental_mode')  String rentalMode, @JsonKey(name: 'available_days')  List<int> availableDays, @JsonKey(name: 'available_from')  String? availableFrom, @JsonKey(name: 'available_until')  String? availableUntil, @JsonKey(name: 'min_hours')  int minHours, @JsonKey(name: 'max_hours')  int maxHours, @JsonKey(name: 'min_nights')  int minNights, @JsonKey(name: 'max_nights')  int maxNights, @JsonKey(name: 'slot_duration_minutes')  int slotDurationMinutes, @JsonKey(name: 'block_hours')  int blockHours, @JsonKey(name: 'max_capacity')  int? maxCapacity, @JsonKey(name: 'instant_booking')  bool instantBooking, @JsonKey(name: 'check_in_time')  String? checkInTime, @JsonKey(name: 'check_out_time')  String? checkOutTime, @JsonKey(name: 'cancellation_policy')  String cancellationPolicy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'host')  Map<String, dynamic>? hostData)  $default,) {final _that = this;
switch (_that) {
case _Listing():
return $default(_that.id,_that.hostId,_that.type,_that.title,_that.description,_that.images,_that.category,_that.tags,_that.amenities,_that.address,_that.city,_that.country,_that.latitude,_that.longitude,_that.basePrice,_that.currency,_that.priceUnit,_that.cleaningFee,_that.capacity,_that.status,_that.rating,_that.reviewCount,_that.viewCount,_that.isFeatured,_that.rentalMode,_that.availableDays,_that.availableFrom,_that.availableUntil,_that.minHours,_that.maxHours,_that.minNights,_that.maxNights,_that.slotDurationMinutes,_that.blockHours,_that.maxCapacity,_that.instantBooking,_that.checkInTime,_that.checkOutTime,_that.cancellationPolicy,_that.createdAt,_that.updatedAt,_that.hostData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'host_id')  String hostId,  String type,  String title,  String? description,  List<String> images,  String? category,  List<String> tags,  List<String> amenities,  String? address,  String? city,  String? country,  double? latitude,  double? longitude, @JsonKey(name: 'base_price')  double? basePrice,  String currency, @JsonKey(name: 'price_unit')  String priceUnit, @JsonKey(name: 'cleaning_fee')  double cleaningFee,  int? capacity,  String status,  double rating, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'view_count')  int viewCount, @JsonKey(name: 'is_featured')  bool isFeatured, @JsonKey(name: 'rental_mode')  String rentalMode, @JsonKey(name: 'available_days')  List<int> availableDays, @JsonKey(name: 'available_from')  String? availableFrom, @JsonKey(name: 'available_until')  String? availableUntil, @JsonKey(name: 'min_hours')  int minHours, @JsonKey(name: 'max_hours')  int maxHours, @JsonKey(name: 'min_nights')  int minNights, @JsonKey(name: 'max_nights')  int maxNights, @JsonKey(name: 'slot_duration_minutes')  int slotDurationMinutes, @JsonKey(name: 'block_hours')  int blockHours, @JsonKey(name: 'max_capacity')  int? maxCapacity, @JsonKey(name: 'instant_booking')  bool instantBooking, @JsonKey(name: 'check_in_time')  String? checkInTime, @JsonKey(name: 'check_out_time')  String? checkOutTime, @JsonKey(name: 'cancellation_policy')  String cancellationPolicy, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'host')  Map<String, dynamic>? hostData)?  $default,) {final _that = this;
switch (_that) {
case _Listing() when $default != null:
return $default(_that.id,_that.hostId,_that.type,_that.title,_that.description,_that.images,_that.category,_that.tags,_that.amenities,_that.address,_that.city,_that.country,_that.latitude,_that.longitude,_that.basePrice,_that.currency,_that.priceUnit,_that.cleaningFee,_that.capacity,_that.status,_that.rating,_that.reviewCount,_that.viewCount,_that.isFeatured,_that.rentalMode,_that.availableDays,_that.availableFrom,_that.availableUntil,_that.minHours,_that.maxHours,_that.minNights,_that.maxNights,_that.slotDurationMinutes,_that.blockHours,_that.maxCapacity,_that.instantBooking,_that.checkInTime,_that.checkOutTime,_that.cancellationPolicy,_that.createdAt,_that.updatedAt,_that.hostData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Listing implements Listing {
  const _Listing({required this.id, @JsonKey(name: 'host_id') required this.hostId, required this.type, required this.title, this.description, final  List<String> images = const [], this.category, final  List<String> tags = const [], final  List<String> amenities = const [], this.address, this.city, this.country, this.latitude, this.longitude, @JsonKey(name: 'base_price') this.basePrice, this.currency = 'CLP', @JsonKey(name: 'price_unit') this.priceUnit = 'night', @JsonKey(name: 'cleaning_fee') this.cleaningFee = 0, this.capacity, this.status = 'draft', this.rating = 0, @JsonKey(name: 'review_count') this.reviewCount = 0, @JsonKey(name: 'view_count') this.viewCount = 0, @JsonKey(name: 'is_featured') this.isFeatured = false, @JsonKey(name: 'rental_mode') this.rentalMode = 'nights', @JsonKey(name: 'available_days') final  List<int> availableDays = const [1, 2, 3, 4, 5, 6, 0], @JsonKey(name: 'available_from') this.availableFrom, @JsonKey(name: 'available_until') this.availableUntil, @JsonKey(name: 'min_hours') this.minHours = 1, @JsonKey(name: 'max_hours') this.maxHours = 12, @JsonKey(name: 'min_nights') this.minNights = 1, @JsonKey(name: 'max_nights') this.maxNights = 30, @JsonKey(name: 'slot_duration_minutes') this.slotDurationMinutes = 60, @JsonKey(name: 'block_hours') this.blockHours = 1, @JsonKey(name: 'max_capacity') this.maxCapacity, @JsonKey(name: 'instant_booking') this.instantBooking = false, @JsonKey(name: 'check_in_time') this.checkInTime, @JsonKey(name: 'check_out_time') this.checkOutTime, @JsonKey(name: 'cancellation_policy') this.cancellationPolicy = 'flexible', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'host') final  Map<String, dynamic>? hostData}): _images = images,_tags = tags,_amenities = amenities,_availableDays = availableDays,_hostData = hostData;
  factory _Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);

@override final  String id;
@override@JsonKey(name: 'host_id') final  String hostId;
@override final  String type;
@override final  String title;
@override final  String? description;
 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String? category;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override final  String? address;
@override final  String? city;
@override final  String? country;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey(name: 'base_price') final  double? basePrice;
@override@JsonKey() final  String currency;
@override@JsonKey(name: 'price_unit') final  String priceUnit;
@override@JsonKey(name: 'cleaning_fee') final  double cleaningFee;
@override final  int? capacity;
@override@JsonKey() final  String status;
@override@JsonKey() final  double rating;
@override@JsonKey(name: 'review_count') final  int reviewCount;
@override@JsonKey(name: 'view_count') final  int viewCount;
@override@JsonKey(name: 'is_featured') final  bool isFeatured;
// V2: Booking system fields
@override@JsonKey(name: 'rental_mode') final  String rentalMode;
 final  List<int> _availableDays;
@override@JsonKey(name: 'available_days') List<int> get availableDays {
  if (_availableDays is EqualUnmodifiableListView) return _availableDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableDays);
}

@override@JsonKey(name: 'available_from') final  String? availableFrom;
@override@JsonKey(name: 'available_until') final  String? availableUntil;
@override@JsonKey(name: 'min_hours') final  int minHours;
@override@JsonKey(name: 'max_hours') final  int maxHours;
@override@JsonKey(name: 'min_nights') final  int minNights;
@override@JsonKey(name: 'max_nights') final  int maxNights;
@override@JsonKey(name: 'slot_duration_minutes') final  int slotDurationMinutes;
@override@JsonKey(name: 'block_hours') final  int blockHours;
@override@JsonKey(name: 'max_capacity') final  int? maxCapacity;
@override@JsonKey(name: 'instant_booking') final  bool instantBooking;
@override@JsonKey(name: 'check_in_time') final  String? checkInTime;
@override@JsonKey(name: 'check_out_time') final  String? checkOutTime;
@override@JsonKey(name: 'cancellation_policy') final  String cancellationPolicy;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
// Joined data
 final  Map<String, dynamic>? _hostData;
// Joined data
@override@JsonKey(name: 'host') Map<String, dynamic>? get hostData {
  final value = _hostData;
  if (value == null) return null;
  if (_hostData is EqualUnmodifiableMapView) return _hostData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListingCopyWith<_Listing> get copyWith => __$ListingCopyWithImpl<_Listing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Listing&&(identical(other.id, id) || other.id == id)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.priceUnit, priceUnit) || other.priceUnit == priceUnit)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.rentalMode, rentalMode) || other.rentalMode == rentalMode)&&const DeepCollectionEquality().equals(other._availableDays, _availableDays)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.availableUntil, availableUntil) || other.availableUntil == availableUntil)&&(identical(other.minHours, minHours) || other.minHours == minHours)&&(identical(other.maxHours, maxHours) || other.maxHours == maxHours)&&(identical(other.minNights, minNights) || other.minNights == minNights)&&(identical(other.maxNights, maxNights) || other.maxNights == maxNights)&&(identical(other.slotDurationMinutes, slotDurationMinutes) || other.slotDurationMinutes == slotDurationMinutes)&&(identical(other.blockHours, blockHours) || other.blockHours == blockHours)&&(identical(other.maxCapacity, maxCapacity) || other.maxCapacity == maxCapacity)&&(identical(other.instantBooking, instantBooking) || other.instantBooking == instantBooking)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.checkOutTime, checkOutTime) || other.checkOutTime == checkOutTime)&&(identical(other.cancellationPolicy, cancellationPolicy) || other.cancellationPolicy == cancellationPolicy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._hostData, _hostData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,hostId,type,title,description,const DeepCollectionEquality().hash(_images),category,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_amenities),address,city,country,latitude,longitude,basePrice,currency,priceUnit,cleaningFee,capacity,status,rating,reviewCount,viewCount,isFeatured,rentalMode,const DeepCollectionEquality().hash(_availableDays),availableFrom,availableUntil,minHours,maxHours,minNights,maxNights,slotDurationMinutes,blockHours,maxCapacity,instantBooking,checkInTime,checkOutTime,cancellationPolicy,createdAt,updatedAt,const DeepCollectionEquality().hash(_hostData)]);

@override
String toString() {
  return 'Listing(id: $id, hostId: $hostId, type: $type, title: $title, description: $description, images: $images, category: $category, tags: $tags, amenities: $amenities, address: $address, city: $city, country: $country, latitude: $latitude, longitude: $longitude, basePrice: $basePrice, currency: $currency, priceUnit: $priceUnit, cleaningFee: $cleaningFee, capacity: $capacity, status: $status, rating: $rating, reviewCount: $reviewCount, viewCount: $viewCount, isFeatured: $isFeatured, rentalMode: $rentalMode, availableDays: $availableDays, availableFrom: $availableFrom, availableUntil: $availableUntil, minHours: $minHours, maxHours: $maxHours, minNights: $minNights, maxNights: $maxNights, slotDurationMinutes: $slotDurationMinutes, blockHours: $blockHours, maxCapacity: $maxCapacity, instantBooking: $instantBooking, checkInTime: $checkInTime, checkOutTime: $checkOutTime, cancellationPolicy: $cancellationPolicy, createdAt: $createdAt, updatedAt: $updatedAt, hostData: $hostData)';
}


}

/// @nodoc
abstract mixin class _$ListingCopyWith<$Res> implements $ListingCopyWith<$Res> {
  factory _$ListingCopyWith(_Listing value, $Res Function(_Listing) _then) = __$ListingCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'host_id') String hostId, String type, String title, String? description, List<String> images, String? category, List<String> tags, List<String> amenities, String? address, String? city, String? country, double? latitude, double? longitude,@JsonKey(name: 'base_price') double? basePrice, String currency,@JsonKey(name: 'price_unit') String priceUnit,@JsonKey(name: 'cleaning_fee') double cleaningFee, int? capacity, String status, double rating,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'view_count') int viewCount,@JsonKey(name: 'is_featured') bool isFeatured,@JsonKey(name: 'rental_mode') String rentalMode,@JsonKey(name: 'available_days') List<int> availableDays,@JsonKey(name: 'available_from') String? availableFrom,@JsonKey(name: 'available_until') String? availableUntil,@JsonKey(name: 'min_hours') int minHours,@JsonKey(name: 'max_hours') int maxHours,@JsonKey(name: 'min_nights') int minNights,@JsonKey(name: 'max_nights') int maxNights,@JsonKey(name: 'slot_duration_minutes') int slotDurationMinutes,@JsonKey(name: 'block_hours') int blockHours,@JsonKey(name: 'max_capacity') int? maxCapacity,@JsonKey(name: 'instant_booking') bool instantBooking,@JsonKey(name: 'check_in_time') String? checkInTime,@JsonKey(name: 'check_out_time') String? checkOutTime,@JsonKey(name: 'cancellation_policy') String cancellationPolicy,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'host') Map<String, dynamic>? hostData
});




}
/// @nodoc
class __$ListingCopyWithImpl<$Res>
    implements _$ListingCopyWith<$Res> {
  __$ListingCopyWithImpl(this._self, this._then);

  final _Listing _self;
  final $Res Function(_Listing) _then;

/// Create a copy of Listing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostId = null,Object? type = null,Object? title = null,Object? description = freezed,Object? images = null,Object? category = freezed,Object? tags = null,Object? amenities = null,Object? address = freezed,Object? city = freezed,Object? country = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? basePrice = freezed,Object? currency = null,Object? priceUnit = null,Object? cleaningFee = null,Object? capacity = freezed,Object? status = null,Object? rating = null,Object? reviewCount = null,Object? viewCount = null,Object? isFeatured = null,Object? rentalMode = null,Object? availableDays = null,Object? availableFrom = freezed,Object? availableUntil = freezed,Object? minHours = null,Object? maxHours = null,Object? minNights = null,Object? maxNights = null,Object? slotDurationMinutes = null,Object? blockHours = null,Object? maxCapacity = freezed,Object? instantBooking = null,Object? checkInTime = freezed,Object? checkOutTime = freezed,Object? cancellationPolicy = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? hostData = freezed,}) {
  return _then(_Listing(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,basePrice: freezed == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,priceUnit: null == priceUnit ? _self.priceUnit : priceUnit // ignore: cast_nullable_to_non_nullable
as String,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,rentalMode: null == rentalMode ? _self.rentalMode : rentalMode // ignore: cast_nullable_to_non_nullable
as String,availableDays: null == availableDays ? _self._availableDays : availableDays // ignore: cast_nullable_to_non_nullable
as List<int>,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,availableUntil: freezed == availableUntil ? _self.availableUntil : availableUntil // ignore: cast_nullable_to_non_nullable
as String?,minHours: null == minHours ? _self.minHours : minHours // ignore: cast_nullable_to_non_nullable
as int,maxHours: null == maxHours ? _self.maxHours : maxHours // ignore: cast_nullable_to_non_nullable
as int,minNights: null == minNights ? _self.minNights : minNights // ignore: cast_nullable_to_non_nullable
as int,maxNights: null == maxNights ? _self.maxNights : maxNights // ignore: cast_nullable_to_non_nullable
as int,slotDurationMinutes: null == slotDurationMinutes ? _self.slotDurationMinutes : slotDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,blockHours: null == blockHours ? _self.blockHours : blockHours // ignore: cast_nullable_to_non_nullable
as int,maxCapacity: freezed == maxCapacity ? _self.maxCapacity : maxCapacity // ignore: cast_nullable_to_non_nullable
as int?,instantBooking: null == instantBooking ? _self.instantBooking : instantBooking // ignore: cast_nullable_to_non_nullable
as bool,checkInTime: freezed == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as String?,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as String?,cancellationPolicy: null == cancellationPolicy ? _self.cancellationPolicy : cancellationPolicy // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hostData: freezed == hostData ? _self._hostData : hostData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
