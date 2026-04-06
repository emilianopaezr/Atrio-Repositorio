import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Real-time stream provider for host financial profile.
final hostProfileProvider = StreamProvider<Map<String, dynamic>?>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value(null);

    final controller = StreamController<Map<String, dynamic>?>();

    // Initial fetch
    DatabaseService.getHostProfile(user.id).then(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to host_profiles changes
    final channel = SupabaseConfig.client.channel('host_profile_stream:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableHostProfiles,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: user.id,
          ),
          callback: (payload) {
            DatabaseService.getHostProfile(user.id).then(
              (data) {
                if (!controller.isClosed) controller.add(data);
              },
            );
          },
        )
        .subscribe();

    ref.onDispose(() {
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
  },
);

/// Real-time stream provider for host transactions.
final hostTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>();

    // Initial fetch
    DatabaseService.getHostTransactions(user.id).then(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to transactions changes
    final channel = SupabaseConfig.client.channel('host_transactions_stream:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableTransactions,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'host_id',
            value: user.id,
          ),
          callback: (payload) {
            DatabaseService.getHostTransactions(user.id).then(
              (data) {
                if (!controller.isClosed) controller.add(data);
              },
            );
          },
        )
        .subscribe();

    ref.onDispose(() {
      controller.close();
      SupabaseConfig.client.removeChannel(channel);
    });

    return controller.stream;
  },
);
