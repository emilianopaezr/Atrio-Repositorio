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
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Joined data
    @JsonKey(name: 'host') Map<String, dynamic>? hostData,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}
