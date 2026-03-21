import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';

/// Provider for user notifications
final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getNotifications(user.id);
  },
);

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return 0;
    return DatabaseService.getUnreadNotificationCount(user.id);
  },
);
