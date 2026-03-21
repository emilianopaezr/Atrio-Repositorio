import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/host_stats_model.dart';

/// Provider for current user's host stats
final hostStatsProvider = FutureProvider<HostStats?>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;

    final response = await SupabaseConfig.client
        .from('host_stats')
        .select()
        .eq('host_id', user.id)
        .maybeSingle();

    if (response == null) {
      // Return default stats for new hosts
      return HostStats(hostId: user.id);
    }
    return HostStats.fromJson(response);
  },
);

/// Provider for a specific host's stats (used in guest views)
final hostStatsByIdProvider = FutureProvider.family<HostStats?, String>(
  (ref, hostId) async {
    final response = await SupabaseConfig.client
        .from('host_stats')
        .select()
        .eq('host_id', hostId)
        .maybeSingle();

    if (response == null) return HostStats(hostId: hostId);
    return HostStats.fromJson(response);
  },
);
