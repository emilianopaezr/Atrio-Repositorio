import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../services/geo_service.dart';

/// Provider for published listings feed.
///
/// Caches only the default (unfiltered) feed so the home landing page survives
/// offline. Filtered queries hit the network directly.
final listingsProvider = FutureProvider.family<List<Map<String, dynamic>>, ListingsFilter>(
  (ref, filter) async {
    final isDefault = filter.type == null &&
        filter.city == null &&
        filter.category == null &&
        (filter.search == null || filter.search!.isEmpty) &&
        filter.offset == 0;

    try {
      final rows = await DatabaseService.getPublishedListings(
        type: filter.type,
        city: filter.city,
        category: filter.category,
        search: filter.search,
        limit: filter.limit,
        offset: filter.offset,
      );
      if (isDefault) {
        await CacheService.putListingsList(
          CacheService.keyPublishedListings,
          rows,
        );
      }
      return rows;
    } catch (e) {
      if (isDefault) {
        final cached = CacheService.getListingsList(
          CacheService.keyPublishedListings,
        );
        if (cached != null && cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  },
);

/// Radius search provider (PostGIS-powered). Returns listings ordered by
/// distance ascending; each row includes `distance_m`.
final nearbyListingsProvider = FutureProvider.family<List<Map<String, dynamic>>, NearbyFilter>(
  (ref, filter) async {
    return DatabaseService.searchListingsNearby(
      latitude: filter.center.latitude,
      longitude: filter.center.longitude,
      radiusMeters: filter.radiusMeters,
      type: filter.type,
      category: filter.category,
      limit: filter.limit,
    );
  },
);

/// Resolves device position (with permission prompt). `null` means permission
/// denied / unavailable; the UI should fall back to [GeoService.defaultCenter].
final devicePositionProvider = FutureProvider<GeoPoint?>((ref) async {
  final pos = await GeoService.getCurrentPosition();
  if (pos == null) return null;
  return GeoPoint(pos.latitude, pos.longitude);
});

/// Provider for featured listings
final featuredListingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final rows = await DatabaseService.getFeaturedListings(limit: 10);
      await CacheService.putListingsList(
        CacheService.keyFeaturedListings,
        rows,
      );
      return rows;
    } catch (e) {
      final cached = CacheService.getListingsList(
        CacheService.keyFeaturedListings,
      );
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  },
);

/// Provider for a single listing detail
final listingDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, listingId) async {
    try {
      final row = await DatabaseService.getListingById(listingId);
      if (row != null) {
        await CacheService.putListingDetail(listingId, row);
      }
      return row;
    } catch (e) {
      final cached = CacheService.getListingDetail(listingId);
      if (cached != null) return cached;
      rethrow;
    }
  },
);

/// Provider for host's listings
final hostListingsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, hostId) async {
    final cacheKey = '${CacheService.keyHostListingsPrefix}$hostId';
    try {
      final rows = await DatabaseService.getHostListings(hostId);
      await CacheService.putListingsList(cacheKey, rows);
      return rows;
    } catch (e) {
      final cached = CacheService.getListingsList(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
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

/// Filter for radius-based listings search.
class NearbyFilter {
  final GeoPoint center;
  final double radiusMeters;
  final String? type;
  final String? category;
  final int limit;

  const NearbyFilter({
    required this.center,
    this.radiusMeters = 10000,
    this.type,
    this.category,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyFilter &&
          center == other.center &&
          radiusMeters == other.radiusMeters &&
          type == other.type &&
          category == other.category &&
          limit == other.limit;

  @override
  int get hashCode =>
      Object.hash(center, radiusMeters, type, category, limit);
}
