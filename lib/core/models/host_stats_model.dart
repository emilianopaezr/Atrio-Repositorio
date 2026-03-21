import 'enums.dart';

/// Aggregated host performance statistics
class HostStats {
  final String hostId;
  final int completedBookingsCount;
  final double averageRating;
  final String currentLevel;
  final double currentCommissionRate;
  final double totalEarnings;
  final double responseRate;
  final bool eliteEligible;
  final DateTime? updatedAt;

  const HostStats({
    required this.hostId,
    this.completedBookingsCount = 0,
    this.averageRating = 0,
    this.currentLevel = 'NEW_HOST',
    this.currentCommissionRate = 0.09,
    this.totalEarnings = 0,
    this.responseRate = 0,
    this.eliteEligible = false,
    this.updatedAt,
  });

  factory HostStats.fromJson(Map<String, dynamic> json) {
    return HostStats(
      hostId: json['host_id'] as String,
      completedBookingsCount: (json['completed_bookings_count'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      currentLevel: json['current_level'] as String? ?? 'NEW_HOST',
      currentCommissionRate: (json['current_commission_rate'] as num?)?.toDouble() ?? 0.09,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0,
      eliteEligible: json['elite_eligible'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  HostLevel get level => HostLevel.fromDb(currentLevel);

  HostLevel? get nextLevel => level.nextLevel;

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

  String get commissionLabel {
    if (currentCommissionRate == 0) return '0%';
    return '${(currentCommissionRate * 100).toStringAsFixed(0)}%';
  }
}
