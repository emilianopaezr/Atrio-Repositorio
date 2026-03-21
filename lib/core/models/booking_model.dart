import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

@freezed
abstract class Booking with _$Booking {
  const factory Booking({
    required String id,
    @JsonKey(name: 'guest_id') required String guestId,
    @JsonKey(name: 'host_id') required String hostId,
    @JsonKey(name: 'listing_id') required String listingId,
    @JsonKey(name: 'check_in') required DateTime checkIn,
    @JsonKey(name: 'check_out') required DateTime checkOut,
    @JsonKey(name: 'guests_count') @Default(1) int guestsCount,
    @JsonKey(name: 'base_total') double? baseTotal,
    @JsonKey(name: 'cleaning_fee') @Default(0) double cleaningFee,
    @JsonKey(name: 'service_fee') @Default(0) double serviceFee,
    double? total,
    @Default('pending') String status,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'special_requests') String? specialRequests,
    @JsonKey(name: 'conversation_id') String? conversationId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Joined data
    @JsonKey(name: 'listing') Map<String, dynamic>? listingData,
    @JsonKey(name: 'guest') Map<String, dynamic>? guestData,
    @JsonKey(name: 'host') Map<String, dynamic>? hostProfileData,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}
