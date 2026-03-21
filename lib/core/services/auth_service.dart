import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService._();

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await SupabaseConfig.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    // Create profile after successful signup
    if (response.user != null) {
      try {
        await SupabaseConfig.client.from(AppConstants.tableProfiles).upsert({
          'id': response.user!.id,
          'display_name': displayName ?? email.split('@').first,
        });
      } catch (e) {
        // Profile creation might fail if trigger already created it
        // or if user needs email confirmation first - that's OK
        debugPrint('Profile creation note: $e');
      }
    }

    return response;
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseConfig.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure profile exists on login
    if (response.user != null) {
      try {
        final existing = await SupabaseConfig.client
            .from(AppConstants.tableProfiles)
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (existing == null) {
          await SupabaseConfig.client.from(AppConstants.tableProfiles).insert({
            'id': response.user!.id,
            'display_name': response.user!.userMetadata?['display_name'] ??
                response.user!.email?.split('@').first,
          });
        }
      } catch (e) {
        debugPrint('Profile check note: $e');
      }
    }

    return response;
  }

  static Future<bool> signInWithGoogle() async {
    return SupabaseConfig.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.atrio.atrio://callback',
    );
  }

  static Future<void> signOut() async {
    await SupabaseConfig.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await SupabaseConfig.auth.resetPasswordForEmail(email);
  }

  static User? get currentUser => SupabaseConfig.auth.currentUser;
  static Session? get currentSession => SupabaseConfig.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;
}
