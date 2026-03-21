// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Review _$ReviewFromJson(Map<String, dynamic> json) => _Review(
  id: json['id'] as String,
  bookingId: json['booking_id'] as String,
  listingId: json['listing_id'] as String,
  reviewerId: json['reviewer_id'] as String,
  hostId: json['host_id'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  hostReply: json['host_reply'] as String?,
  hostReplyAt: json['host_reply_at'] == null
      ? null
      : DateTime.parse(json['host_reply_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  reviewerData: json['reviewer'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ReviewToJson(_Review instance) => <String, dynamic>{
  'id': instance.id,
  'booking_id': instance.bookingId,
  'listing_id': instance.listingId,
  'reviewer_id': instance.reviewerId,
  'host_id': instance.hostId,
  'rating': instance.rating,
  'comment': instance.comment,
  'host_reply': instance.hostReply,
  'host_reply_at': instance.hostReplyAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'reviewer': instance.reviewerData,
};
