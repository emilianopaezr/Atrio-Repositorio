import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';
import '../services/realtime_service.dart';

/// Real-time stream provider for user conversations.
/// Fetches initially, then re-fetches on any conversation update or new message.
final conversationsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>();

    // Initial fetch
    DatabaseService.getConversations(user.id).then(
      (data) {
        if (!controller.isClosed) controller.add(data);
      },
      onError: (e) {
        if (!controller.isClosed) controller.addError(e);
      },
    );

    // Subscribe to conversation updates (last_message changes)
    final convChannel = RealtimeService.subscribeToConversations(
      user.id,
      onUpdate: (_) {
        // Re-fetch full list on any update
        DatabaseService.getConversations(user.id).then(
          (data) {
            if (!controller.isClosed) controller.add(data);
          },
        );
      },
    );

    // Also subscribe to new inserts on conversations table
    final insertChannel = SupabaseConfig.client.channel('conv_inserts:${user.id}');
    insertChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            final participantIds = List<String>.from(
              payload.newRecord['participant_ids'] ?? [],
            );
            if (participantIds.contains(user.id)) {
              DatabaseService.getConversations(user.id).then(
                (data) {
                  if (!controller.isClosed) controller.add(data);
                },
              );
            }
          },
        )
        .subscribe();

    ref.onDispose(() {
      controller.close();
      RealtimeService.unsubscribe(convChannel);
      RealtimeService.unsubscribe(insertChannel);
    });

    return controller.stream;
  },
);

/// Provider for messages in a conversation (one-time fetch, chat screen uses .stream() directly)
final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, conversationId) async {
    return DatabaseService.getMessages(conversationId);
  },
);
