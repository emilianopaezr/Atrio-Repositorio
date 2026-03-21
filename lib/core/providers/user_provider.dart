import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await SupabaseConfig.client
      .from(AppConstants.tableProfiles)
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return UserProfile.fromJson(response);
});

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return SupabaseConfig.client
      .from(AppConstants.tableProfiles)
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) {
        if (data.isEmpty) return null;
        return UserProfile.fromJson(data.first);
      });
});
