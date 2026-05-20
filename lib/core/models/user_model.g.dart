// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  displayName: json['display_name'] as String?,
  photoUrl: json['photo_url'] as String?,
  phone: json['phone'] as String?,
  bio: json['bio'] as String?,
  isHost: json['is_host'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  isVerified: json['is_verified'] as bool? ?? false,
  emailVerified: json['email_verified'] as bool? ?? false,
  phoneVerified: json['phone_verified'] as bool? ?? false,
  phoneVerifiedAt: json['phone_verified_at'] == null
      ? null
      : DateTime.parse(json['phone_verified_at'] as String),
  kycStatus: json['kyc_status'] as String? ?? 'none',
  kycDocuments:
      json['kyc_documents'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  kycSubmittedAt: json['kyc_submitted_at'] == null
      ? null
      : DateTime.parse(json['kyc_submitted_at'] as String),
  kycReviewedAt: json['kyc_reviewed_at'] == null
      ? null
      : DateTime.parse(json['kyc_reviewed_at'] as String),
  kycReviewNote: json['kyc_review_note'] as String?,
  favoriteListingIds:
      (json['favorite_listing_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  profession: json['profession'] as String?,
  decadeBorn: json['decade_born'] as String?,
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  interests:
      (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  responseTimeHours: (json['response_time_hours'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'phone': instance.phone,
      'bio': instance.bio,
      'is_host': instance.isHost,
      'is_admin': instance.isAdmin,
      'is_verified': instance.isVerified,
      'email_verified': instance.emailVerified,
      'phone_verified': instance.phoneVerified,
      'phone_verified_at': instance.phoneVerifiedAt?.toIso8601String(),
      'kyc_status': instance.kycStatus,
      'kyc_documents': instance.kycDocuments,
      'kyc_submitted_at': instance.kycSubmittedAt?.toIso8601String(),
      'kyc_reviewed_at': instance.kycReviewedAt?.toIso8601String(),
      'kyc_review_note': instance.kycReviewNote,
      'favorite_listing_ids': instance.favoriteListingIds,
      'profession': instance.profession,
      'decade_born': instance.decadeBorn,
      'languages': instance.languages,
      'interests': instance.interests,
      'response_time_hours': instance.responseTimeHours,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
