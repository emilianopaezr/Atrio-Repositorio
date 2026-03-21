import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

/// Provider for published listings feed
final listingsProvider = FutureProvider.family<List<Map<String, dynamic>>, ListingsFilter>(
  (ref, filter) async {
    return DatabaseService.getPublishedListings(
      type: filter.type,
      city: filter.city,
      category: filter.category,
      search: filter.search,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

/// Provider for featured listings
final featuredListingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    return DatabaseService.getFeaturedListings(limit: 10);
  },
);

/// Provider for a single listing detail
final listingDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, listingId) async {
    return DatabaseService.getListingById(listingId);
  },
);

/// Provider for host's listings
final hostListingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, hostId) async {
    return DatabaseService.getHostListings(hostId);
  },
);

/// Provider for listing reviews
final listingReviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, listingId) async {
    return DatabaseService.getListingReviews(listingId);
  },
);

/// Filter class for listings queries
class ListingsFilter {
  final String? type;
  final String? city;
  final String? category;
  final String? search;
  final int limit;
  final int offset;

  const ListingsFilter({
    this.type,
    this.city,
    this.category,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingsFilter &&
          type == other.type &&
          city == other.city &&
          category == other.category &&
          search == other.search &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(type, city, category, search, limit, offset);
}
