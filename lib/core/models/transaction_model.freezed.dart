// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 String get id;@JsonKey(name: 'host_id') String get hostId;@JsonKey(name: 'booking_id') String? get bookingId; String get type; double get amount; String get currency; String get status; String? get description;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hostId,bookingId,type,amount,currency,status,description,createdAt);

@override
String toString() {
  return 'Transaction(id: $id, hostId: $hostId, bookingId: $bookingId, type: $type, amount: $amount, currency: $currency, status: $status, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'host_id') String hostId,@JsonKey(name: 'booking_id') String? bookingId, String type, double amount, String currency, String status, String? description,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostId = null,Object? bookingId = freezed,Object? type = null,Object? amount = null,Object? currency = null,Object? status = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'booking_id')  String? bookingId,  String type,  double amount,  String currency,  String status,  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.hostId,_that.bookingId,_that.type,_that.amount,_that.currency,_that.status,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'booking_id')  String? bookingId,  String type,  double amount,  String currency,  String status,  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.hostId,_that.bookingId,_that.type,_that.amount,_that.currency,_that.status,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'host_id')  String hostId, @JsonKey(name: 'booking_id')  String? bookingId,  String type,  double amount,  String currency,  String status,  String? description, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.hostId,_that.bookingId,_that.type,_that.amount,_that.currency,_that.status,_that.description,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction implements Transaction {
  const _Transaction({required this.id, @JsonKey(name: 'host_id') required this.hostId, @JsonKey(name: 'booking_id') this.bookingId, required this.type, required this.amount, this.currency = 'CLP', this.status = 'pending', this.description, @JsonKey(name: 'created_at') this.createdAt});
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'host_id') final  String hostId;
@override@JsonKey(name: 'booking_id') final  String? bookingId;
@override final  String type;
@override final  double amount;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String status;
@override final  String? description;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hostId,bookingId,type,amount,currency,status,description,createdAt);

@override
String toString() {
  return 'Transaction(id: $id, hostId: $hostId, bookingId: $bookingId, type: $type, amount: $amount, currency: $currency, status: $status, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'host_id') String hostId,@JsonKey(name: 'booking_id') String? bookingId, String type, double amount, String currency, String status, String? description,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostId = null,Object? bookingId = freezed,Object? type = null,Object? amount = null,Object? currency = null,Object? status = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$HostProfile {

 String get id;@JsonKey(name: 'bank_name') String? get bankName;@JsonKey(name: 'account_last4') String? get accountLast4;@JsonKey(name: 'bank_configured') bool get bankConfigured;@JsonKey(name: 'total_earnings') double get totalEarnings;@JsonKey(name: 'current_balance') double get currentBalance;@JsonKey(name: 'pending_balance') double get pendingBalance;@JsonKey(name: 'response_rate') double get responseRate;@JsonKey(name: 'is_superhost') bool get isSuperhost;@JsonKey(name: 'joined_as_host_at') DateTime? get joinedAsHostAt;
/// Create a copy of HostProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostProfileCopyWith<HostProfile> get copyWith => _$HostProfileCopyWithImpl<HostProfile>(this as HostProfile, _$identity);

  /// Serializes this HostProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.bankConfigured, bankConfigured) || other.bankConfigured == bankConfigured)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.pendingBalance, pendingBalance) || other.pendingBalance == pendingBalance)&&(identical(other.responseRate, responseRate) || other.responseRate == responseRate)&&(identical(other.isSuperhost, isSuperhost) || other.isSuperhost == isSuperhost)&&(identical(other.joinedAsHostAt, joinedAsHostAt) || other.joinedAsHostAt == joinedAsHostAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,accountLast4,bankConfigured,totalEarnings,currentBalance,pendingBalance,responseRate,isSuperhost,joinedAsHostAt);

@override
String toString() {
  return 'HostProfile(id: $id, bankName: $bankName, accountLast4: $accountLast4, bankConfigured: $bankConfigured, totalEarnings: $totalEarnings, currentBalance: $currentBalance, pendingBalance: $pendingBalance, responseRate: $responseRate, isSuperhost: $isSuperhost, joinedAsHostAt: $joinedAsHostAt)';
}


}

/// @nodoc
abstract mixin class $HostProfileCopyWith<$Res>  {
  factory $HostProfileCopyWith(HostProfile value, $Res Function(HostProfile) _then) = _$HostProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'account_last4') String? accountLast4,@JsonKey(name: 'bank_configured') bool bankConfigured,@JsonKey(name: 'total_earnings') double totalEarnings,@JsonKey(name: 'current_balance') double currentBalance,@JsonKey(name: 'pending_balance') double pendingBalance,@JsonKey(name: 'response_rate') double responseRate,@JsonKey(name: 'is_superhost') bool isSuperhost,@JsonKey(name: 'joined_as_host_at') DateTime? joinedAsHostAt
});




}
/// @nodoc
class _$HostProfileCopyWithImpl<$Res>
    implements $HostProfileCopyWith<$Res> {
  _$HostProfileCopyWithImpl(this._self, this._then);

  final HostProfile _self;
  final $Res Function(HostProfile) _then;

/// Create a copy of HostProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bankName = freezed,Object? accountLast4 = freezed,Object? bankConfigured = null,Object? totalEarnings = null,Object? currentBalance = null,Object? pendingBalance = null,Object? responseRate = null,Object? isSuperhost = null,Object? joinedAsHostAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,bankConfigured: null == bankConfigured ? _self.bankConfigured : bankConfigured // ignore: cast_nullable_to_non_nullable
as bool,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,pendingBalance: null == pendingBalance ? _self.pendingBalance : pendingBalance // ignore: cast_nullable_to_non_nullable
as double,responseRate: null == responseRate ? _self.responseRate : responseRate // ignore: cast_nullable_to_non_nullable
as double,isSuperhost: null == isSuperhost ? _self.isSuperhost : isSuperhost // ignore: cast_nullable_to_non_nullable
as bool,joinedAsHostAt: freezed == joinedAsHostAt ? _self.joinedAsHostAt : joinedAsHostAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HostProfile].
extension HostProfilePatterns on HostProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostProfile value)  $default,){
final _that = this;
switch (_that) {
case _HostProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostProfile value)?  $default,){
final _that = this;
switch (_that) {
case _HostProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_last4')  String? accountLast4, @JsonKey(name: 'bank_configured')  bool bankConfigured, @JsonKey(name: 'total_earnings')  double totalEarnings, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'pending_balance')  double pendingBalance, @JsonKey(name: 'response_rate')  double responseRate, @JsonKey(name: 'is_superhost')  bool isSuperhost, @JsonKey(name: 'joined_as_host_at')  DateTime? joinedAsHostAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostProfile() when $default != null:
return $default(_that.id,_that.bankName,_that.accountLast4,_that.bankConfigured,_that.totalEarnings,_that.currentBalance,_that.pendingBalance,_that.responseRate,_that.isSuperhost,_that.joinedAsHostAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_last4')  String? accountLast4, @JsonKey(name: 'bank_configured')  bool bankConfigured, @JsonKey(name: 'total_earnings')  double totalEarnings, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'pending_balance')  double pendingBalance, @JsonKey(name: 'response_rate')  double responseRate, @JsonKey(name: 'is_superhost')  bool isSuperhost, @JsonKey(name: 'joined_as_host_at')  DateTime? joinedAsHostAt)  $default,) {final _that = this;
switch (_that) {
case _HostProfile():
return $default(_that.id,_that.bankName,_that.accountLast4,_that.bankConfigured,_that.totalEarnings,_that.currentBalance,_that.pendingBalance,_that.responseRate,_that.isSuperhost,_that.joinedAsHostAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'account_last4')  String? accountLast4, @JsonKey(name: 'bank_configured')  bool bankConfigured, @JsonKey(name: 'total_earnings')  double totalEarnings, @JsonKey(name: 'current_balance')  double currentBalance, @JsonKey(name: 'pending_balance')  double pendingBalance, @JsonKey(name: 'response_rate')  double responseRate, @JsonKey(name: 'is_superhost')  bool isSuperhost, @JsonKey(name: 'joined_as_host_at')  DateTime? joinedAsHostAt)?  $default,) {final _that = this;
switch (_that) {
case _HostProfile() when $default != null:
return $default(_that.id,_that.bankName,_that.accountLast4,_that.bankConfigured,_that.totalEarnings,_that.currentBalance,_that.pendingBalance,_that.responseRate,_that.isSuperhost,_that.joinedAsHostAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HostProfile implements HostProfile {
  const _HostProfile({required this.id, @JsonKey(name: 'bank_name') this.bankName, @JsonKey(name: 'account_last4') this.accountLast4, @JsonKey(name: 'bank_configured') this.bankConfigured = false, @JsonKey(name: 'total_earnings') this.totalEarnings = 0, @JsonKey(name: 'current_balance') this.currentBalance = 0, @JsonKey(name: 'pending_balance') this.pendingBalance = 0, @JsonKey(name: 'response_rate') this.responseRate = 0, @JsonKey(name: 'is_superhost') this.isSuperhost = false, @JsonKey(name: 'joined_as_host_at') this.joinedAsHostAt});
  factory _HostProfile.fromJson(Map<String, dynamic> json) => _$HostProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'bank_name') final  String? bankName;
@override@JsonKey(name: 'account_last4') final  String? accountLast4;
@override@JsonKey(name: 'bank_configured') final  bool bankConfigured;
@override@JsonKey(name: 'total_earnings') final  double totalEarnings;
@override@JsonKey(name: 'current_balance') final  double currentBalance;
@override@JsonKey(name: 'pending_balance') final  double pendingBalance;
@override@JsonKey(name: 'response_rate') final  double responseRate;
@override@JsonKey(name: 'is_superhost') final  bool isSuperhost;
@override@JsonKey(name: 'joined_as_host_at') final  DateTime? joinedAsHostAt;

/// Create a copy of HostProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostProfileCopyWith<_HostProfile> get copyWith => __$HostProfileCopyWithImpl<_HostProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HostProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.bankConfigured, bankConfigured) || other.bankConfigured == bankConfigured)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.pendingBalance, pendingBalance) || other.pendingBalance == pendingBalance)&&(identical(other.responseRate, responseRate) || other.responseRate == responseRate)&&(identical(other.isSuperhost, isSuperhost) || other.isSuperhost == isSuperhost)&&(identical(other.joinedAsHostAt, joinedAsHostAt) || other.joinedAsHostAt == joinedAsHostAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bankName,accountLast4,bankConfigured,totalEarnings,currentBalance,pendingBalance,responseRate,isSuperhost,joinedAsHostAt);

@override
String toString() {
  return 'HostProfile(id: $id, bankName: $bankName, accountLast4: $accountLast4, bankConfigured: $bankConfigured, totalEarnings: $totalEarnings, currentBalance: $currentBalance, pendingBalance: $pendingBalance, responseRate: $responseRate, isSuperhost: $isSuperhost, joinedAsHostAt: $joinedAsHostAt)';
}


}

/// @nodoc
abstract mixin class _$HostProfileCopyWith<$Res> implements $HostProfileCopyWith<$Res> {
  factory _$HostProfileCopyWith(_HostProfile value, $Res Function(_HostProfile) _then) = __$HostProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'account_last4') String? accountLast4,@JsonKey(name: 'bank_configured') bool bankConfigured,@JsonKey(name: 'total_earnings') double totalEarnings,@JsonKey(name: 'current_balance') double currentBalance,@JsonKey(name: 'pending_balance') double pendingBalance,@JsonKey(name: 'response_rate') double responseRate,@JsonKey(name: 'is_superhost') bool isSuperhost,@JsonKey(name: 'joined_as_host_at') DateTime? joinedAsHostAt
});




}
/// @nodoc
class __$HostProfileCopyWithImpl<$Res>
    implements _$HostProfileCopyWith<$Res> {
  __$HostProfileCopyWithImpl(this._self, this._then);

  final _HostProfile _self;
  final $Res Function(_HostProfile) _then;

/// Create a copy of HostProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bankName = freezed,Object? accountLast4 = freezed,Object? bankConfigured = null,Object? totalEarnings = null,Object? currentBalance = null,Object? pendingBalance = null,Object? responseRate = null,Object? isSuperhost = null,Object? joinedAsHostAt = freezed,}) {
  return _then(_HostProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,bankConfigured: null == bankConfigured ? _self.bankConfigured : bankConfigured // ignore: cast_nullable_to_non_nullable
as bool,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,pendingBalance: null == pendingBalance ? _self.pendingBalance : pendingBalance // ignore: cast_nullable_to_non_nullable
as double,responseRate: null == responseRate ? _self.responseRate : responseRate // ignore: cast_nullable_to_non_nullable
as double,isSuperhost: null == isSuperhost ? _self.isSuperhost : isSuperhost // ignore: cast_nullable_to_non_nullable
as bool,joinedAsHostAt: freezed == joinedAsHostAt ? _self.joinedAsHostAt : joinedAsHostAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
