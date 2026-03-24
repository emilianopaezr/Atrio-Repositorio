import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

/// Booked dates for a listing in a date range
final bookedDatesProvider = FutureProvider.family<List<Map<String, dynamic>>, BookedDatesParams>(
  (ref, params) async {
    return DatabaseService.getBookedDates(
      params.listingId,
      params.startDate,
      params.endDate,
    );
  },
);

/// Booked time slots for a specific listing+date
final bookedTimeSlotsProvider = FutureProvider.family<List<Map<String, dynamic>>, TimeSlotsParams>(
  (ref, params) async {
    return DatabaseService.getBookedTimeSlots(params.listingId, params.date);
  },
);

/// Availability records for a listing
final availabilityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, listingId) async {
    final now = DateTime.now();
    return DatabaseService.getAvailability(
      listingId,
      startDate: now,
      endDate: now.add(const Duration(days: 90)),
    );
  },
);

// === Parameter classes ===

class BookedDatesParams {
  final String listingId;
  final DateTime startDate;
  final DateTime endDate;

  const BookedDatesParams({
    required this.listingId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookedDatesParams &&
          listingId == other.listingId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(listingId, startDate, endDate);
}

class TimeSlotsParams {
  final String listingId;
  final DateTime date;

  const TimeSlotsParams({required this.listingId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotsParams &&
          listingId == other.listingId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => Object.hash(listingId, date.year, date.month, date.day);
}
