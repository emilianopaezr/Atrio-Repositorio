// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id;@JsonKey(name: 'display_name') String? get displayName;@JsonKey(name: 'photo_url') String? get photoUrl; String? get phone; String? get bio;@JsonKey(name: 'is_host') bool get isHost;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'kyc_status') String get kycStatus;@JsonKey(name: 'favorite_listing_ids') List<String> get favoriteListingIds;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&const DeepCollectionEquality().equals(other.favoriteListingIds, favoriteListingIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,photoUrl,phone,bio,isHost,isVerified,kycStatus,const DeepCollectionEquality().hash(favoriteListingIds),createdAt,updatedAt);

@override
String toString() {
  return 'UserProfile(id: $id, displayName: $displayName, photoUrl: $photoUrl, phone: $phone, bio: $bio, isHost: $isHost, isVerified: $isVerified, kycStatus: $kycStatus, favoriteListingIds: $favoriteListingIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String? displayName,@JsonKey(name: 'photo_url') String? photoUrl, String? phone, String? bio,@JsonKey(name: 'is_host') bool isHost,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'favorite_listing_ids') List<String> favoriteListingIds,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? phone = freezed,Object? bio = freezed,Object? isHost = null,Object? isVerified = null,Object? kycStatus = null,Object? favoriteListingIds = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,favoriteListingIds: null == favoriteListingIds ? _self.favoriteListingIds : favoriteListingIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  String? phone,  String? bio, @JsonKey(name: 'is_host')  bool isHost, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'favorite_listing_ids')  List<String> favoriteListingIds, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.displayName,_that.photoUrl,_that.phone,_that.bio,_that.isHost,_that.isVerified,_that.kycStatus,_that.favoriteListingIds,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  String? phone,  String? bio, @JsonKey(name: 'is_host')  bool isHost, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'favorite_listing_ids')  List<String> favoriteListingIds, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.displayName,_that.photoUrl,_that.phone,_that.bio,_that.isHost,_that.isVerified,_that.kycStatus,_that.favoriteListingIds,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'display_name')  String? displayName, @JsonKey(name: 'photo_url')  String? photoUrl,  String? phone,  String? bio, @JsonKey(name: 'is_host')  bool isHost, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'favorite_listing_ids')  List<String> favoriteListingIds, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.displayName,_that.photoUrl,_that.phone,_that.bio,_that.isHost,_that.isVerified,_that.kycStatus,_that.favoriteListingIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, @JsonKey(name: 'display_name') this.displayName, @JsonKey(name: 'photo_url') this.photoUrl, this.phone, this.bio, @JsonKey(name: 'is_host') this.isHost = false, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'kyc_status') this.kycStatus = 'none', @JsonKey(name: 'favorite_listing_ids') final  List<String> favoriteListingIds = const [], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _favoriteListingIds = favoriteListingIds;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override final  String? phone;
@override final  String? bio;
@override@JsonKey(name: 'is_host') final  bool isHost;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'kyc_status') final  String kycStatus;
 final  List<String> _favoriteListingIds;
@override@JsonKey(name: 'favorite_listing_ids') List<String> get favoriteListingIds {
  if (_favoriteListingIds is EqualUnmodifiableListView) return _favoriteListingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteListingIds);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&const DeepCollectionEquality().equals(other._favoriteListingIds, _favoriteListingIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,photoUrl,phone,bio,isHost,isVerified,kycStatus,const DeepCollectionEquality().hash(_favoriteListingIds),createdAt,updatedAt);

@override
String toString() {
  return 'UserProfile(id: $id, displayName: $displayName, photoUrl: $photoUrl, phone: $phone, bio: $bio, isHost: $isHost, isVerified: $isVerified, kycStatus: $kycStatus, favoriteListingIds: $favoriteListingIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String? displayName,@JsonKey(name: 'photo_url') String? photoUrl, String? phone, String? bio,@JsonKey(name: 'is_host') bool isHost,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'favorite_listing_ids') List<String> favoriteListingIds,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? photoUrl = freezed,Object? phone = freezed,Object? bio = freezed,Object? isHost = null,Object? isVerified = null,Object? kycStatus = null,Object? favoriteListingIds = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,favoriteListingIds: null == favoriteListingIds ? _self._favoriteListingIds : favoriteListingIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
