import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';

/// Service for Supabase Realtime subscriptions
class RealtimeService {
  RealtimeService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// Subscribe to messages in a conversation
  static RealtimeChannel subscribeToMessages(
    String conversationId, {
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    final channel = _client.channel('messages:$conversationId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.tableMessages,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation updates for a user
  static RealtimeChannel subscribeToConversations(
    String userId, {
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    final channel = _client.channel('conversations:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.tableConversations,
          callback: (payload) {
            final participantIds = List<String>.from(
              payload.newRecord['participant_ids'] ?? [],
            );
            if (participantIds.contains(userId)) {
              onUpdate(payload.newRecord);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to booking status changes (for host)
  static RealtimeChannel subscribeToHostBookings(
    String hostId, {
    required void Function(Map<String, dynamic>) onUpdate,
    void Function(Map<String, dynamic>)? onInsert,
  }) {
    final channel = _client.channel('host_bookings:$hostId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: AppConstants.tableBookings,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'host_id',
        value: hostId,
      ),
      callback: (payload) {
        onUpdate(payload.newRecord);
      },
    );

    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: AppConstants.tableBookings,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'host_id',
          value: hostId,
        ),
        callback: (payload) {
          onInsert(payload.newRecord);
        },
      );
    }

    channel.subscribe();
    return channel;
  }

  /// Subscribe to notifications for a user
  static RealtimeChannel subscribeToNotifications(
    String userId, {
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    final channel = _client.channel('notifications:$userId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.tableNotifications,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// Remove all subscriptions
  static Future<void> removeAllChannels() async {
    await _client.removeAllChannels();
  }
}
