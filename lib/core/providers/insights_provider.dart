import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase/supabase_config.dart';

/// Aggregated monthly insights for the host's dashboard.
class HostInsights {
  final double revenueThisMonth;
  final double revenueLastMonth;
  final int bookingsThisMonth;
  final int totalViews;
  final int listingsCount;

  const HostInsights({
    this.revenueThisMonth = 0,
    this.revenueLastMonth = 0,
    this.bookingsThisMonth = 0,
    this.totalViews = 0,
    this.listingsCount = 0,
  });

  /// % change vs last month. 0 if last month was 0.
  double get revenueChangePct {
    if (revenueLastMonth <= 0) return 0;
    return ((revenueThisMonth - revenueLastMonth) / revenueLastMonth) * 100;
  }
}

/// Top performing listing for the host this month.
class TopListing {
  final String id;
  final String title;
  final String? imageUrl;
  final int bookingsCount;
  final double revenue;
  const TopListing({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.bookingsCount,
    required this.revenue,
  });
}

/// Per-rating breakdown plus aggregate flags.
class HostReviewSummary {
  final int total;
  final double averageRating;
  final Map<int, int> distribution; // {5: 12, 4: 3, 3: 1, ...}
  final int pendingReplies; // reviews where host_reply IS NULL
  final int negativeCount; // rating <= 3
  final List<RecentReview> recent;

  const HostReviewSummary({
    this.total = 0,
    this.averageRating = 0,
    this.distribution = const {},
    this.pendingReplies = 0,
    this.negativeCount = 0,
    this.recent = const [],
  });
}

class RecentReview {
  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? listingTitle;
  final bool hasReply;

  const RecentReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
    required this.listingTitle,
    required this.hasReply,
  });
}

// ─── Providers ──────────────────────────────────────────────

/// Aggregated insights for the current host.
final hostInsightsProvider = FutureProvider<HostInsights>((ref) async {
  final user = SupabaseConfig.auth.currentUser;
  if (user == null) return const HostInsights();

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

  final client = SupabaseConfig.client;

  // Bookings this month
  final thisMonth = await client
      .from('bookings')
      .select('total, service_fee')
      .eq('host_id', user.id)
      .eq('payment_status', 'paid')
      .gte('created_at', startOfMonth.toIso8601String());

  // Bookings last month
  final lastMonth = await client
      .from('bookings')
      .select('total, service_fee')
      .eq('host_id', user.id)
      .eq('payment_status', 'paid')
      .gte('created_at', startOfLastMonth.toIso8601String())
      .lt('created_at', startOfMonth.toIso8601String());

  // Host's listings (count + total views)
  final listings = await client
      .from('listings')
      .select('view_count')
      .eq('host_id', user.id);

  double revThis = 0, revLast = 0;
  for (final b in (thisMonth as List)) {
    final t = (b['total'] as num?)?.toDouble() ?? 0;
    final f = (b['service_fee'] as num?)?.toDouble() ?? 0;
    revThis += (t - f);
  }
  for (final b in (lastMonth as List)) {
    final t = (b['total'] as num?)?.toDouble() ?? 0;
    final f = (b['service_fee'] as num?)?.toDouble() ?? 0;
    revLast += (t - f);
  }

  int views = 0;
  for (final l in (listings as List)) {
    views += (l['view_count'] as num?)?.toInt() ?? 0;
  }

  return HostInsights(
    revenueThisMonth: revThis,
    revenueLastMonth: revLast,
    bookingsThisMonth: (thisMonth).length,
    totalViews: views,
    listingsCount: listings.length,
  );
});

/// Top 3 performing listings (this month, by revenue).
final topListingsProvider = FutureProvider<List<TopListing>>((ref) async {
  final user = SupabaseConfig.auth.currentUser;
  if (user == null) return [];

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  // Pull this month's paid bookings with listing info.
  final rows = await SupabaseConfig.client
      .from('bookings')
      .select('listing_id, total, service_fee, listing:listings!listing_id(id, title, images)')
      .eq('host_id', user.id)
      .eq('payment_status', 'paid')
      .gte('created_at', startOfMonth.toIso8601String());

  // Aggregate by listing.
  final byListing = <String, Map<String, dynamic>>{};
  for (final r in (rows as List)) {
    final listing = r['listing'] as Map<String, dynamic>?;
    if (listing == null) continue;
    final id = listing['id'] as String;
    final t = (r['total'] as num?)?.toDouble() ?? 0;
    final f = (r['service_fee'] as num?)?.toDouble() ?? 0;
    final net = t - f;
    final existing = byListing[id];
    if (existing == null) {
      byListing[id] = {
        'title': listing['title'] ?? '—',
        'images': listing['images'] ?? [],
        'count': 1,
        'revenue': net,
      };
    } else {
      existing['count'] = (existing['count'] as int) + 1;
      existing['revenue'] = (existing['revenue'] as double) + net;
    }
  }

  final list = byListing.entries.toList()
    ..sort((a, b) =>
        (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

  return list.take(3).map((e) {
    final images = (e.value['images'] as List?) ?? const [];
    return TopListing(
      id: e.key,
      title: e.value['title'] as String,
      imageUrl: images.isNotEmpty ? images.first as String : null,
      bookingsCount: e.value['count'] as int,
      revenue: e.value['revenue'] as double,
    );
  }).toList();
});

/// Review summary + recent reviews + pending replies / negatives.
final hostReviewSummaryProvider =
    FutureProvider<HostReviewSummary>((ref) async {
  final user = SupabaseConfig.auth.currentUser;
  if (user == null) return const HostReviewSummary();

  final all = await SupabaseConfig.client
      .from('reviews')
      .select(
          'id, rating, comment, host_reply, created_at, reviewer_id, listing_id, '
          'reviewer:profiles!reviewer_id(display_name), '
          'listing:listings!listing_id(title)')
      .eq('host_id', user.id)
      .order('created_at', ascending: false);

  final list = List<Map<String, dynamic>>.from(all as List);
  if (list.isEmpty) return const HostReviewSummary();

  int sum = 0;
  final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  int pending = 0;
  int negative = 0;

  for (final r in list) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    if (rating >= 1 && rating <= 5) {
      sum += rating;
      dist[rating] = (dist[rating] ?? 0) + 1;
    }
    final hasReply = (r['host_reply'] as String?)?.trim().isNotEmpty ?? false;
    if (!hasReply) pending++;
    if (rating > 0 && rating <= 3) negative++;
  }

  final recent = list.take(3).map((r) {
    final reviewer = r['reviewer'] as Map<String, dynamic>?;
    final listing = r['listing'] as Map<String, dynamic>?;
    return RecentReview(
      id: r['id'] as String,
      rating: (r['rating'] as num?)?.toInt() ?? 0,
      comment: r['comment'] as String?,
      createdAt: DateTime.tryParse(r['created_at'] as String) ?? DateTime.now(),
      reviewerName: reviewer?['display_name'] as String?,
      listingTitle: listing?['title'] as String?,
      hasReply: (r['host_reply'] as String?)?.trim().isNotEmpty ?? false,
    );
  }).toList();

  return HostReviewSummary(
    total: list.length,
    averageRating: list.isEmpty ? 0 : sum / list.length,
    distribution: dist,
    pendingReplies: pending,
    negativeCount: negative,
    recent: recent,
  );
});
