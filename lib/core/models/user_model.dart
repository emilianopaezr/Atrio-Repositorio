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
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'email_verified') @Default(false) bool emailVerified,
    @JsonKey(name: 'phone_verified') @Default(false) bool phoneVerified,
    @JsonKey(name: 'phone_verified_at') DateTime? phoneVerifiedAt,
    @JsonKey(name: 'kyc_status') @Default('none') String kycStatus,
    @JsonKey(name: 'kyc_documents') @Default(<String, dynamic>{}) Map<String, dynamic> kycDocuments,
    @JsonKey(name: 'kyc_submitted_at') DateTime? kycSubmittedAt,
    @JsonKey(name: 'kyc_reviewed_at') DateTime? kycReviewedAt,
    @JsonKey(name: 'kyc_review_note') String? kycReviewNote,
    @JsonKey(name: 'favorite_listing_ids') @Default([]) List<String> favoriteListingIds,
    String? profession,
    @JsonKey(name: 'decade_born') String? decadeBorn,
    @Default([]) List<String> languages,
    @Default([]) List<String> interests,
    @JsonKey(name: 'response_time_hours') int? responseTimeHours,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
