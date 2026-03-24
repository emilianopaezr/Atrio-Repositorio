// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Booking _$BookingFromJson(Map<String, dynamic> json) => _Booking(
  id: json['id'] as String,
  guestId: json['guest_id'] as String,
  hostId: json['host_id'] as String,
  listingId: json['listing_id'] as String,
  checkIn: DateTime.parse(json['check_in'] as String),
  checkOut: DateTime.parse(json['check_out'] as String),
  guestsCount: (json['guests_count'] as num?)?.toInt() ?? 1,
  baseTotal: (json['base_total'] as num?)?.toDouble(),
  cleaningFee: (json['cleaning_fee'] as num?)?.toDouble() ?? 0,
  serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
  total: (json['total'] as num?)?.toDouble(),
  status: json['status'] as String? ?? 'pending',
  paymentStatus: json['payment_status'] as String? ?? 'pending',
  specialRequests: json['special_requests'] as String?,
  conversationId: json['conversation_id'] as String?,
  rentalMode: json['rental_mode'] as String? ?? 'nights',
  timeSlots: json['time_slots'] as List<dynamic>? ?? const [],
  bookingDate: json['booking_date'] as String?,
  startTime: json['start_time'] as String?,
  endTime: json['end_time'] as String?,
  durationHours: (json['duration_hours'] as num?)?.toDouble(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  listingData: json['listing'] as Map<String, dynamic>?,
  guestData: json['guest'] as Map<String, dynamic>?,
  hostProfileData: json['host'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$BookingToJson(_Booking instance) => <String, dynamic>{
  'id': instance.id,
  'guest_id': instance.guestId,
  'host_id': instance.hostId,
  'listing_id': instance.listingId,
  'check_in': instance.checkIn.toIso8601String(),
  'check_out': instance.checkOut.toIso8601String(),
  'guests_count': instance.guestsCount,
  'base_total': instance.baseTotal,
  'cleaning_fee': instance.cleaningFee,
  'service_fee': instance.serviceFee,
  'total': instance.total,
  'status': instance.status,
  'payment_status': instance.paymentStatus,
  'special_requests': instance.specialRequests,
  'conversation_id': instance.conversationId,
  'rental_mode': instance.rentalMode,
  'time_slots': instance.timeSlots,
  'booking_date': instance.bookingDate,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'duration_hours': instance.durationHours,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'listing': instance.listingData,
  'guest': instance.guestData,
  'host': instance.hostProfileData,
};
