import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';

/// Provider for user conversations
final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getConversations(user.id);
  },
);

/// Provider for messages in a conversation
final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, conversationId) async {
    return DatabaseService.getMessages(conversationId);
  },
);
