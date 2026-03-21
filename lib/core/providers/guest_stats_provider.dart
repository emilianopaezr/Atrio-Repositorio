import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/guest_stats_model.dart';

/// Provider for current user's guest stats
final guestStatsProvider = FutureProvider<GuestStats?>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;

    final response = await SupabaseConfig.client
        .from('guest_stats')
        .select()
        .eq('guest_id', user.id)
        .maybeSingle();

    if (response == null) {
      return GuestStats(guestId: user.id);
    }
    return GuestStats.fromJson(response);
  },
);
