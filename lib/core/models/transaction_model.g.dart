// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  hostId: json['host_id'] as String,
  bookingId: json['booking_id'] as String?,
  type: json['type'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'CLP',
  status: json['status'] as String? ?? 'pending',
  description: json['description'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'host_id': instance.hostId,
      'booking_id': instance.bookingId,
      'type': instance.type,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'description': instance.description,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_HostProfile _$HostProfileFromJson(Map<String, dynamic> json) => _HostProfile(
  id: json['id'] as String,
  bankName: json['bank_name'] as String?,
  accountLast4: json['account_last4'] as String?,
  bankConfigured: json['bank_configured'] as bool? ?? false,
  totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
  currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
  pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0,
  responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0,
  isSuperhost: json['is_superhost'] as bool? ?? false,
  joinedAsHostAt: json['joined_as_host_at'] == null
      ? null
      : DateTime.parse(json['joined_as_host_at'] as String),
);

Map<String, dynamic> _$HostProfileToJson(_HostProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_name': instance.bankName,
      'account_last4': instance.accountLast4,
      'bank_configured': instance.bankConfigured,
      'total_earnings': instance.totalEarnings,
      'current_balance': instance.currentBalance,
      'pending_balance': instance.pendingBalance,
      'response_rate': instance.responseRate,
      'is_superhost': instance.isSuperhost,
      'joined_as_host_at': instance.joinedAsHostAt?.toIso8601String(),
    };
