import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/cache_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Debounce duration for realtime refetch to prevent query storms
const _debounceDuration = Duration(milliseconds: 500);

/// Real-time stream provider for guest bookings.
/// Re-fetches when any booking for this guest is inserted or updated.
final guestBookingsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final cacheKey = '${CacheService.keyGuestBookingsPrefix}${user.id}';
    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? debounceTimer;

    void refetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounceDuration, () {
        DatabaseService.getGuestBookings(user.id).then(
          (data) {
            CacheService.putBookingsList(cacheKey, data);
            if (!controller.isClosed) controller.add(data);
          },
        );
      });
    }

    // Hydrate from cache while network request runs.
    final cached = CacheService.getBookingsList(cacheKey);
    if (cached != null && !controller.isClosed) controller.add(cached);

    // Initial fetch (no debounce)
    DatabaseService.getGuestBookings(user.id).then(
      (data) {
        CacheService.putBookingsList(cacheKey, data);
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        // If we already emitted cached data, swallow the error; otherwise surface it.
        if (cached == null && !controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to all booking changes for this guest
    final channel = SupabaseConfig.client.channel('guest_bookings:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableBookings,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'guest_id',
            value: user.id,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    ref.onDispose(() {
      debounceTimer?.cancel();
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
  },
);

/// Real-time stream provider for host bookings.
/// Re-fetches when any booking for this host is inserted or updated.
final hostBookingsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final cacheKey = '${CacheService.keyHostBookingsPrefix}${user.id}';
    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? debounceTimer;

    void refetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounceDuration, () {
        DatabaseService.getHostBookings(user.id).then(
          (data) {
            CacheService.putBookingsList(cacheKey, data);
            if (!controller.isClosed) controller.add(data);
          },
        );
      });
    }

    final cached = CacheService.getBookingsList(cacheKey);
    if (cached != null && !controller.isClosed) controller.add(cached);

    // Initial fetch
    DatabaseService.getHostBookings(user.id).then(
      (data) {
        CacheService.putBookingsList(cacheKey, data);
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (cached == null && !controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to all booking changes for this host
    final channel = SupabaseConfig.client.channel('host_bookings_stream:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableBookings,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'host_id',
            value: user.id,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    ref.onDispose(() {
      debounceTimer?.cancel();
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
  },
);

/// Provider for a single booking detail
final bookingDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, bookingId) async {
    return DatabaseService.getBookingById(bookingId);
  },
);

/// Real-time stream provider for pending host bookings (dashboard).
final pendingHostBookingsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? debounceTimer;

    void refetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounceDuration, () {
        DatabaseService.getHostBookings(user.id, status: 'pending').then(
          (data) {
            if (!controller.isClosed) controller.add(data);
          },
        );
      });
    }

    // Initial fetch
    DatabaseService.getHostBookings(user.id, status: 'pending').then(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe - reuse the host bookings channel pattern
    final channel = SupabaseConfig.client.channel('pending_host_bookings:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableBookings,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'host_id',
            value: user.id,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    ref.onDispose(() {
      debounceTimer?.cancel();
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
  },
);
