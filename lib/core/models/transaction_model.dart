import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @JsonKey(name: 'host_id') required String hostId,
    @JsonKey(name: 'booking_id') String? bookingId,
    required String type,
    required double amount,
    @Default('USD') String currency,
    @Default('pending') String status,
    String? description,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

@freezed
abstract class HostProfile with _$HostProfile {
  const factory HostProfile({
    required String id,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'account_last4') String? accountLast4,
    @JsonKey(name: 'bank_configured') @Default(false) bool bankConfigured,
    @JsonKey(name: 'total_earnings') @Default(0) double totalEarnings,
    @JsonKey(name: 'current_balance') @Default(0) double currentBalance,
    @JsonKey(name: 'pending_balance') @Default(0) double pendingBalance,
    @JsonKey(name: 'response_rate') @Default(0) double responseRate,
    @JsonKey(name: 'is_superhost') @Default(false) bool isSuperhost,
    @JsonKey(name: 'joined_as_host_at') DateTime? joinedAsHostAt,
  }) = _HostProfile;

  factory HostProfile.fromJson(Map<String, dynamic> json) =>
      _$HostProfileFromJson(json);
}
