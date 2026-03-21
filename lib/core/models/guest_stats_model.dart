import 'enums.dart';

/// Aggregated guest activity statistics
class GuestStats {
  final String guestId;
  final int completedBookingsCount;
  final double cancellationRate;
  final double totalSpent;
  final String currentLevel;
  final Map<String, dynamic> benefits;
  final DateTime? updatedAt;

  const GuestStats({
    required this.guestId,
    this.completedBookingsCount = 0,
    this.cancellationRate = 0,
    this.totalSpent = 0,
    this.currentLevel = 'EXPLORER',
    this.benefits = const {},
    this.updatedAt,
  });

  factory GuestStats.fromJson(Map<String, dynamic> json) {
    return GuestStats(
      guestId: json['guest_id'] as String,
      completedBookingsCount: (json['completed_bookings_count'] as num?)?.toInt() ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      currentLevel: json['current_level'] as String? ?? 'EXPLORER',
      benefits: json['benefits'] as Map<String, dynamic>? ?? {},
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  GuestLevel get level => GuestLevel.fromDb(currentLevel);

  GuestLevel? get nextLevel => level.nextLevel;

  int get bookingsToNextLevel {
    final next = nextLevel;
    if (next == null) return 0;
    return (next.minBookings - completedBookingsCount).clamp(0, 999);
  }

  double get progressToNextLevel {
    final next = nextLevel;
    if (next == null) return 1.0;
    final currentMin = level.minBookings;
    final nextMin = next.minBookings;
    final range = nextMin - currentMin;
    if (range <= 0) return 1.0;
    return ((completedBookingsCount - currentMin) / range).clamp(0.0, 1.0);
  }
}
