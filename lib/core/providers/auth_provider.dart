import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';

/// Stream-based auth state for reactive UI
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

/// Current user (reactive via auth state)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user)
      ?? SupabaseConfig.auth.currentUser;
});

/// Whether the user is authenticated (reactive)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session != null,
    loading: () => SupabaseConfig.auth.currentSession != null,
    error: (_, _) => false,
  );
});

/// Listenable that GoRouter can use to refresh on auth changes.
/// Converts the Supabase auth stream into a ChangeNotifier.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    _subscription = SupabaseConfig.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Single instance for GoRouter refreshListenable
final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
