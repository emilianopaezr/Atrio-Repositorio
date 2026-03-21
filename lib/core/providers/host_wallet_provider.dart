import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../services/database_service.dart';

/// Provider for host financial profile
final hostProfileProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;
    return DatabaseService.getHostProfile(user.id);
  },
);

/// Provider for host transactions
final hostTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];
    return DatabaseService.getHostTransactions(user.id);
  },
);
