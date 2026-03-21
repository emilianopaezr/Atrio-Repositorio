import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    @JsonKey(name: 'booking_id') required String bookingId,
    @JsonKey(name: 'listing_id') required String listingId,
    @JsonKey(name: 'reviewer_id') required String reviewerId,
    @JsonKey(name: 'host_id') required String hostId,
    required int rating,
    String? comment,
    @JsonKey(name: 'host_reply') String? hostReply,
    @JsonKey(name: 'host_reply_at') DateTime? hostReplyAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Joined data
    @JsonKey(name: 'reviewer') Map<String, dynamic>? reviewerData,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
}
