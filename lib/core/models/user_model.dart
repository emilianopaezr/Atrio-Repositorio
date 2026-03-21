import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? phone,
    String? bio,
    @JsonKey(name: 'is_host') @Default(false) bool isHost,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'kyc_status') @Default('none') String kycStatus,
    @JsonKey(name: 'favorite_listing_ids') @Default([]) List<String> favoriteListingIds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
