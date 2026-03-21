import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';

/// Provider for guest bookings
final guestBookingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getGuestBookings(user.id);
  },
);

/// Provider for host bookings
final hostBookingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getHostBookings(user.id);
  },
);

/// Provider for a single booking detail
final bookingDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, bookingId) async {
    return DatabaseService.getBookingById(bookingId);
  },
);

/// Provider for pending host bookings (for dashboard)
final pendingHostBookingsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getHostBookings(user.id, status: 'pending');
  },
);
