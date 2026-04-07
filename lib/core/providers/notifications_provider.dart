import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

const _debounceDuration = Duration(milliseconds: 500);

/// Real-time stream provider for user notifications.
/// Auto-updates when new notifications arrive or existing ones are updated/deleted.
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? debounceTimer;

    void refetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounceDuration, () {
        DatabaseService.getNotifications(user.id).then(
          (data) {
            if (!controller.isClosed) controller.add(data);
          },
        );
      });
    }

    // Initial fetch
    DatabaseService.getNotifications(user.id).then(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to all notification changes for this user
    final channel = SupabaseConfig.client.channel('notifications_stream:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableNotifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
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

/// Real-time stream provider for unread notification count.
final unreadNotificationCountProvider = StreamProvider<int>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value(0);

    final controller = StreamController<int>();
    Timer? debounceTimer;

    void refetchCount() {
      debounceTimer?.cancel();
      debounceTimer = Timer(_debounceDuration, () {
        DatabaseService.getUnreadNotificationCount(user.id).then(
          (count) {
            if (!controller.isClosed) controller.add(count);
          },
        );
      });
    }

    // Initial fetch
    DatabaseService.getUnreadNotificationCount(user.id).then(
      (count) {
        if (!controller.isClosed) controller.add(count);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to notification changes to update count
    final channel = SupabaseConfig.client.channel('unread_count:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.tableNotifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => refetchCount(),
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
