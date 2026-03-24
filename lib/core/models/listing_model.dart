import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing_model.freezed.dart';
part 'listing_model.g.dart';

@freezed
abstract class Listing with _$Listing {
  const factory Listing({
    required String id,
    @JsonKey(name: 'host_id') required String hostId,
    required String type,
    required String title,
    String? description,
    @Default([]) List<String> images,
    String? category,
    @Default([]) List<String> tags,
    @Default([]) List<String> amenities,
    String? address,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'base_price') double? basePrice,
    @Default('USD') String currency,
    @JsonKey(name: 'price_unit') @Default('night') String priceUnit,
    @JsonKey(name: 'cleaning_fee') @Default(0) double cleaningFee,
    int? capacity,
    @Default('draft') String status,
    @Default(0) double rating,
    @JsonKey(name: 'review_count') @Default(0) int reviewCount,
    @JsonKey(name: 'view_count') @Default(0) int viewCount,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    // V2: Booking system fields
    @JsonKey(name: 'rental_mode') @Default('nights') String rentalMode,
    @JsonKey(name: 'available_days') @Default([1, 2, 3, 4, 5, 6, 0]) List<int> availableDays,
    @JsonKey(name: 'available_from') String? availableFrom,
    @JsonKey(name: 'available_until') String? availableUntil,
    @JsonKey(name: 'min_hours') @Default(1) int minHours,
    @JsonKey(name: 'max_hours') @Default(12) int maxHours,
    @JsonKey(name: 'min_nights') @Default(1) int minNights,
    @JsonKey(name: 'max_nights') @Default(30) int maxNights,
    @JsonKey(name: 'slot_duration_minutes') @Default(60) int slotDurationMinutes,
    @JsonKey(name: 'max_capacity') int? maxCapacity,
    @JsonKey(name: 'instant_booking') @Default(false) bool instantBooking,
    @JsonKey(name: 'check_in_time') String? checkInTime,
    @JsonKey(name: 'check_out_time') String? checkOutTime,
    @JsonKey(name: 'cancellation_policy') @Default('flexible') String cancellationPolicy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Joined data
    @JsonKey(name: 'host') Map<String, dynamic>? hostData,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}
