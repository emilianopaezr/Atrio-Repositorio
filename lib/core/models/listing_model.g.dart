// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Listing _$ListingFromJson(Map<String, dynamic> json) => _Listing(
  id: json['id'] as String,
  hostId: json['host_id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  category: json['category'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  address: json['address'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  basePrice: (json['base_price'] as num?)?.toDouble(),
  currency: json['currency'] as String? ?? 'USD',
  priceUnit: json['price_unit'] as String? ?? 'night',
  cleaningFee: (json['cleaning_fee'] as num?)?.toDouble() ?? 0,
  capacity: (json['capacity'] as num?)?.toInt(),
  status: json['status'] as String? ?? 'draft',
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
  viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
  isFeatured: json['is_featured'] as bool? ?? false,
  rentalMode: json['rental_mode'] as String? ?? 'nights',
  availableDays:
      (json['available_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [1, 2, 3, 4, 5, 6, 0],
  availableFrom: json['available_from'] as String?,
  availableUntil: json['available_until'] as String?,
  minHours: (json['min_hours'] as num?)?.toInt() ?? 1,
  maxHours: (json['max_hours'] as num?)?.toInt() ?? 12,
  minNights: (json['min_nights'] as num?)?.toInt() ?? 1,
  maxNights: (json['max_nights'] as num?)?.toInt() ?? 30,
  slotDurationMinutes: (json['slot_duration_minutes'] as num?)?.toInt() ?? 60,
  maxCapacity: (json['max_capacity'] as num?)?.toInt(),
  instantBooking: json['instant_booking'] as bool? ?? false,
  checkInTime: json['check_in_time'] as String?,
  checkOutTime: json['check_out_time'] as String?,
  cancellationPolicy: json['cancellation_policy'] as String? ?? 'flexible',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  hostData: json['host'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ListingToJson(_Listing instance) => <String, dynamic>{
  'id': instance.id,
  'host_id': instance.hostId,
  'type': instance.type,
  'title': instance.title,
  'description': instance.description,
  'images': instance.images,
  'category': instance.category,
  'tags': instance.tags,
  'amenities': instance.amenities,
  'address': instance.address,
  'city': instance.city,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'base_price': instance.basePrice,
  'currency': instance.currency,
  'price_unit': instance.priceUnit,
  'cleaning_fee': instance.cleaningFee,
  'capacity': instance.capacity,
  'status': instance.status,
  'rating': instance.rating,
  'review_count': instance.reviewCount,
  'view_count': instance.viewCount,
  'is_featured': instance.isFeatured,
  'rental_mode': instance.rentalMode,
  'available_days': instance.availableDays,
  'available_from': instance.availableFrom,
  'available_until': instance.availableUntil,
  'min_hours': instance.minHours,
  'max_hours': instance.maxHours,
  'min_nights': instance.minNights,
  'max_nights': instance.maxNights,
  'slot_duration_minutes': instance.slotDurationMinutes,
  'max_capacity': instance.maxCapacity,
  'instant_booking': instance.instantBooking,
  'check_in_time': instance.checkInTime,
  'check_out_time': instance.checkOutTime,
  'cancellation_policy': instance.cancellationPolicy,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'host': instance.hostData,
};
