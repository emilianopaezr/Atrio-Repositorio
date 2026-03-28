import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/dispute_model.dart';
import '../services/database_service.dart';

final disputeFilterProvider = NotifierProvider<DisputeFilterNotifier, String>(
  DisputeFilterNotifier.new,
);

class DisputeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'todas';
  void setFilter(String value) => state = value;
}

/// Provider for all disputes belonging to the current user
final disputesProvider = FutureProvider<List<DisputeModel>>((ref) async {
  final user = SupabaseConfig.auth.currentUser;
  if (user == null) return [];

  try {
    final data = await DatabaseService.getUserDisputes(user.id);
    return data.map((json) => DisputeModel.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
});

/// Provider for a single dispute by ID
final disputeDetailProvider =
    FutureProvider.family<DisputeModel?, String>((ref, id) async {
  try {
    final data = await DatabaseService.getDisputeById(id);
    if (data == null) return null;
    return DisputeModel.fromJson(data);
  } catch (e) {
    return null;
  }
});

/// Filtered disputes based on the current filter selection
final filteredDisputesProvider =
    Provider<AsyncValue<List<DisputeModel>>>((ref) {
  final filter = ref.watch(disputeFilterProvider);
  final disputesAsync = ref.watch(disputesProvider);

  return disputesAsync.whenData((disputes) {
    if (filter == 'todas') return disputes;
    return disputes.where((d) => d.status == _filterToStatus(filter)).toList();
  });
});

String _filterToStatus(String filter) {
  switch (filter) {
    case 'abiertas':
      return 'abierta';
    case 'en_revision':
      return 'en_revision';
    case 'cerradas':
      return 'cerrada';
    default:
      return filter;
  }
}
