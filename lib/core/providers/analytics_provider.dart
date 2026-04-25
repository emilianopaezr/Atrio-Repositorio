import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';

class AnalyticsData {
  final double totalRevenue;
  final int totalBookings;
  final double avgRating;
  final int totalReviews;
  final List<Map<String, dynamic>> topListings;
  final List<Map<String, dynamic>> recentBookings;
  final List<double> dailyRevenue;

  const AnalyticsData({
    required this.totalRevenue,
    required this.totalBookings,
    required this.avgRating,
    required this.totalReviews,
    required this.topListings,
    required this.recentBookings,
    required this.dailyRevenue,
  });
}

/// Fetches analytics data for the current host.
/// [periodIdx]: 0=week, 1=month, 2=year
final analyticsProvider = FutureProvider.family<AnalyticsData, int>((ref, periodIdx) async {
  final uid = SupabaseConfig.auth.currentUser?.id;
  if (uid == null) {
    return const AnalyticsData(
      totalRevenue: 0,
      totalBookings: 0,
      avgRating: 0,
      totalReviews: 0,
      topListings: [],
      recentBookings: [],
      dailyRevenue: [],
    );
  }

  final now = DateTime.now();
  late DateTime start;
  if (periodIdx == 0) {
    start = now.subtract(const Duration(days: 7));
  } else if (periodIdx == 1) {
    start = DateTime(now.year, now.month, 1);
  } else {
    start = DateTime(now.year, 1, 1);
  }

  // Fetch bookings for this host in period
  final bookings = await SupabaseConfig.client
      .from('bookings')
      .select('id, total_price, status, check_in, created_at, listing:listings(id, title, images)')
      .eq('host_id', uid)
      .gte('created_at', start.toIso8601String())
      .order('created_at', ascending: false);

  final bookingList = List<Map<String, dynamic>>.from(bookings);

  // Revenue from confirmed/completed only
  double rev = 0;
  for (final b in bookingList) {
    final s = b['status'] as String? ?? '';
    if (s == 'confirmed' || s == 'completed') {
      rev += (b['total_price'] as num?)?.toDouble() ?? 0;
    }
  }

  // Reviews
  final reviews = await SupabaseConfig.client
      .from('reviews')
      .select('rating')
      .eq('host_id', uid);
  final reviewList = List<Map<String, dynamic>>.from(reviews);
  double ratingSum = 0;
  for (final r in reviewList) {
    ratingSum += (r['rating'] as num?)?.toDouble() ?? 0;
  }

  // Top listings
  final listings = await SupabaseConfig.client
      .from('listings')
      .select('id, title, images, review_count, average_rating')
      .eq('host_id', uid)
      .order('review_count', ascending: false)
      .limit(5);

  // Daily revenue bars (last 7 entries)
  final Map<String, double> dailyMap = {};
  for (final b in bookingList) {
    final s = b['status'] as String? ?? '';
    if (s == 'confirmed' || s == 'completed') {
      final d = (b['created_at'] as String?)?.substring(0, 10) ?? '';
      dailyMap[d] = (dailyMap[d] ?? 0) + ((b['total_price'] as num?)?.toDouble() ?? 0);
    }
  }
  final dailyKeys = dailyMap.keys.toList()..sort();
  final daily = dailyKeys.take(7).map((k) => dailyMap[k]!).toList();

  debugPrint('Analytics loaded: rev=$rev, bookings=${bookingList.length}, reviews=${reviewList.length}');

  return AnalyticsData(
    totalRevenue: rev,
    totalBookings: bookingList.length,
    avgRating: reviewList.isEmpty ? 0 : ratingSum / reviewList.length,
    totalReviews: reviewList.length,
    topListings: List<Map<String, dynamic>>.from(listings),
    recentBookings: bookingList.take(5).toList(),
    dailyRevenue: daily,
  );
});
