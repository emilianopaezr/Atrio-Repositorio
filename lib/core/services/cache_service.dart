import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight offline cache layer built on Hive.
///
/// Stores JSON-serialisable maps/lists per key and tracks a writtenAt timestamp
/// so callers can apply a TTL when reading. All failures are swallowed: caching
/// is best-effort and must never break the online code path.
class CacheService {
  CacheService._();

  static const String _listingsBox = 'cache_listings';
  static const String _bookingsBox = 'cache_bookings';
  static const String _metaBox = 'cache_meta';

  // Meta keys
  static const String _writtenAtSuffix = ':written_at';

  /// Keys for list-type caches
  static const String keyPublishedListings = 'published_listings';
  static const String keyFeaturedListings = 'featured_listings';
  static const String keyHostListingsPrefix = 'host_listings:';
  static const String keyListingDetailPrefix = 'listing_detail:';
  static const String keyGuestBookingsPrefix = 'guest_bookings:';
  static const String keyHostBookingsPrefix = 'host_bookings:';

  static bool _initialized = false;

  /// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox<dynamic>(_listingsBox),
        Hive.openBox<dynamic>(_bookingsBox),
        Hive.openBox<dynamic>(_metaBox),
      ]);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] init failed: $e');
    }
  }

  static Box<dynamic>? _box(String name) {
    if (!_initialized) return null;
    try {
      return Hive.box<dynamic>(name);
    } catch (_) {
      return null;
    }
  }

  static Box<dynamic>? get _listings => _box(_listingsBox);
  static Box<dynamic>? get _bookings => _box(_bookingsBox);
  static Box<dynamic>? get _meta => _box(_metaBox);

  // ---------------------------------------------------------------------------
  // List-of-maps helpers (listings feed, bookings list, etc.)
  // ---------------------------------------------------------------------------

  static Future<void> putListingsList(
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    final box = _listings;
    if (box == null) return;
    try {
      await box.put(key, rows);
      await _meta?.put(
        '$key$_writtenAtSuffix',
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] putListingsList($key): $e');
    }
  }

  static List<Map<String, dynamic>>? getListingsList(String key) {
    final box = _listings;
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] getListingsList($key): $e');
    }
    return null;
  }

  static Future<void> putListingDetail(
    String listingId,
    Map<String, dynamic> row,
  ) async {
    final box = _listings;
    if (box == null) return;
    try {
      final key = '$keyListingDetailPrefix$listingId';
      await box.put(key, row);
      await _meta?.put(
        '$key$_writtenAtSuffix',
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] putListingDetail: $e');
    }
  }

  static Map<String, dynamic>? getListingDetail(String listingId) {
    final box = _listings;
    if (box == null) return null;
    try {
      final raw = box.get('$keyListingDetailPrefix$listingId');
      if (raw is Map) return Map<String, dynamic>.from(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] getListingDetail: $e');
    }
    return null;
  }

  // Bookings --------------------------------------------------------------

  static Future<void> putBookingsList(
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    final box = _bookings;
    if (box == null) return;
    try {
      await box.put(key, rows);
      await _meta?.put(
        '$key$_writtenAtSuffix',
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] putBookingsList($key): $e');
    }
  }

  static List<Map<String, dynamic>>? getBookingsList(String key) {
    final box = _bookings;
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] getBookingsList($key): $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Metadata / invalidation
  // ---------------------------------------------------------------------------

  /// Returns when the entry was written to cache, or null if never.
  static DateTime? writtenAt(String key) {
    final meta = _meta;
    if (meta == null) return null;
    final raw = meta.get('$key$_writtenAtSuffix');
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Whether the cached entry under [key] is still fresh given a TTL.
  static bool isFresh(String key, Duration ttl) {
    final ts = writtenAt(key);
    if (ts == null) return false;
    return DateTime.now().toUtc().difference(ts) < ttl;
  }

  static Future<void> invalidate(String key) async {
    try {
      await _listings?.delete(key);
      await _bookings?.delete(key);
      await _meta?.delete('$key$_writtenAtSuffix');
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] invalidate($key): $e');
    }
  }

  /// Invalidate every key starting with [prefix]. Useful after user actions
  /// that affect many cached entries (e.g., creating a booking).
  static Future<void> invalidatePrefix(String prefix) async {
    try {
      for (final box in [_listings, _bookings]) {
        if (box == null) continue;
        final keys = box.keys
            .whereType<String>()
            .where((k) => k.startsWith(prefix))
            .toList();
        await box.deleteAll(keys);
      }
      final meta = _meta;
      if (meta != null) {
        final metaKeys = meta.keys
            .whereType<String>()
            .where((k) => k.startsWith(prefix))
            .toList();
        await meta.deleteAll(metaKeys);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] invalidatePrefix($prefix): $e');
    }
  }

  /// Nuke everything. Usually called on sign-out.
  static Future<void> clearAll() async {
    try {
      await _listings?.clear();
      await _bookings?.clear();
      await _meta?.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheService] clearAll: $e');
    }
  }
}
