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
  isVerified: json['is_verified'] as bool? ?? false,
  kycStatus: json['kyc_status'] as String? ?? 'none',
  favoriteListingIds:
      (json['favorite_listing_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
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
      'is_verified': instance.isVerified,
      'kyc_status': instance.kycStatus,
      'favorite_listing_ids': instance.favoriteListingIds,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
