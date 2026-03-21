import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.auth.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session != null,
    loading: () => SupabaseConfig.auth.currentSession != null,
    error: (_, _) => false,
  );
});
