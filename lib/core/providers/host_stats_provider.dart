import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/host_stats_model.dart';

/// Real-time stream provider for current user's host stats.
final hostStatsProvider = StreamProvider<HostStats?>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value(null);

    final controller = StreamController<HostStats?>();

    Future<void> fetch() async {
      try {
        final response = await SupabaseConfig.client
            .from('host_stats')
            .select()
            .eq('host_id', user.id)
            .maybeSingle();

        if (controller.isClosed) return;
        if (response == null) {
          controller.add(HostStats(hostId: user.id));
        } else {
          controller.add(HostStats.fromJson(response));
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Initial fetch
    fetch();

    // Subscribe to host_stats changes
    final channel = SupabaseConfig.client.channel('host_stats_stream:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'host_stats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'host_id',
            value: user.id,
          ),
          callback: (payload) => fetch(),
        )
        .subscribe();

    ref.onDispose(() {
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
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
