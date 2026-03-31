import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/constants.dart';
import 'realtime_service.dart';

/// Custom exception for auth errors with user-friendly messages
class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  /// Cached email verification status.
  /// null = unknown (not yet checked), true = verified, false = not verified.
  /// Read synchronously by GoRouter redirect.
  static bool? emailVerified;

  /// Fetch email_verified from DB and cache it.
  static Future<bool> fetchEmailVerified() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) {
      emailVerified = null;
      return false;
    }
    try {
      final result = await SupabaseConfig.client
          .from('profiles')
          .select('email_verified')
          .eq('id', user.id)
          .maybeSingle();
      emailVerified = result?['email_verified'] == true;
    } catch (e) {
      debugPrint('Error fetching email_verified: $e');
      // On error, assume verified to avoid blocking the user
      emailVerified = true;
    }
    return emailVerified!;
  }

  /// Sign up with email & password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        throw AuthException('No se pudo crear la cuenta. Intenta de nuevo.');
      }

      // Check if email confirmation is needed (user exists but no session)
      if (response.session == null && response.user != null) {
        // Check if the user identity list is empty (means email already registered)
        if (response.user!.identities?.isEmpty ?? false) {
          throw AuthException(
            'Este email ya está registrado. Intenta iniciar sesión.',
            code: 'email_exists',
          );
        }
        // Auto-confirm trigger should handle this, but if not:
        throw AuthException(
          'Cuenta creada. Revisa tu email para confirmar tu cuenta.',
          code: 'confirmation_needed',
        );
      }

      // Create profile after successful signup
      if (response.user != null) {
        try {
          await SupabaseConfig.client.from(AppConstants.tableProfiles).upsert({
            'id': response.user!.id,
            'display_name': displayName ?? email.split('@').first,
          });
        } catch (e) {
          debugPrint('Profile creation note: $e');
        }
      }

      return response;
    } on AuthApiException catch (e) {
      throw _mapAuthError(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  /// Sign in with email & password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
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
            await SupabaseConfig.client
                .from(AppConstants.tableProfiles)
                .insert({
              'id': response.user!.id,
              'display_name':
                  response.user!.userMetadata?['display_name'] ??
                      response.user!.email?.split('@').first,
            });
          }
        } catch (e) {
          debugPrint('Profile check note: $e');
        }
      }

      return response;
    } on AuthApiException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  /// Sign in with Google OAuth
  static Future<bool> signInWithGoogle() async {
    try {
      return await SupabaseConfig.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.atrio.atrio://callback',
      );
    } on AuthApiException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    emailVerified = null;
    await SupabaseConfig.auth.signOut();
  }

  /// Sign out and clear all cached state
  static Future<void> signOutAndClear() async {
    emailVerified = null;
    try {
      await RealtimeService.removeAllChannels();
    } catch (_) {}
    await SupabaseConfig.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  static User? get currentUser => SupabaseConfig.auth.currentUser;
  static Session? get currentSession => SupabaseConfig.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;

  /// Request email verification OTP
  static Future<void> requestVerificationCode() async {
    try {
      await SupabaseConfig.client.rpc('request_verification', params: {
        'p_api_key': AppConstants.brevoApiKey,
      });
    } catch (e) {
      debugPrint('Error requesting verification: $e');
      throw AuthException(
        'No se pudo enviar el código. Intenta de nuevo.',
        code: 'verification_send_error',
      );
    }
  }

  /// Verify OTP code
  static Future<bool> verifyOtpCode(String code) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) throw AuthException('No hay sesión activa.');

      final result = await SupabaseConfig.client.rpc('verify_otp_code', params: {
        'p_user_id': user.id,
        'p_code': code,
      });

      return result == true;
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('Error verifying OTP: $e');
      throw AuthException(
        'Error al verificar el código. Intenta de nuevo.',
        code: 'verification_error',
      );
    }
  }

  /// Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user == null) return false;

      final result = await SupabaseConfig.client
          .from('profiles')
          .select('email_verified')
          .eq('id', user.id)
          .maybeSingle();

      return result?['email_verified'] == true;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────
  // Error mapping helpers
  // ──────────────────────────────────────────

  static AuthException _mapAuthError(AuthApiException e) {
    final msg = e.message.toLowerCase();
    final code = e.code ?? '';

    // Invalid login credentials
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        code == 'invalid_credentials') {
      return AuthException(
        'Email o contraseña incorrectos. Verifica tus datos.',
        code: 'invalid_credentials',
      );
    }

    // Email not confirmed
    if (msg.contains('email not confirmed') ||
        code == 'email_not_confirmed') {
      return AuthException(
        'Tu email no está confirmado. Revisa tu bandeja de entrada.',
        code: 'email_not_confirmed',
      );
    }

    // User already registered
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        code == 'user_already_exists') {
      return AuthException(
        'Este email ya está registrado. Intenta iniciar sesión.',
        code: 'email_exists',
      );
    }

    // Too many requests / rate limited
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit') {
      return AuthException(
        'Demasiados intentos. Espera un momento e intenta de nuevo.',
        code: 'rate_limited',
      );
    }

    // Weak password
    if (msg.contains('password') && msg.contains('weak') ||
        msg.contains('password should be')) {
      return AuthException(
        'La contraseña es demasiado débil. Usa al menos 8 caracteres con mayúsculas y números.',
        code: 'weak_password',
      );
    }

    // Invalid email
    if (msg.contains('invalid email') ||
        msg.contains('unable to validate email')) {
      return AuthException(
        'El formato del email no es válido.',
        code: 'invalid_email',
      );
    }

    // Signup disabled
    if (msg.contains('signups not allowed') ||
        code == 'signup_disabled') {
      return AuthException(
        'El registro de nuevas cuentas no está disponible en este momento.',
        code: 'signup_disabled',
      );
    }

    // Generic auth error
    debugPrint('Unhandled auth error: ${e.message} (code: ${e.code})');
    return AuthException(
      'Error de autenticación. Intenta de nuevo.',
      code: 'auth_error',
    );
  }

  static AuthException _mapGenericError(Object e) {
    final msg = e.toString().toLowerCase();

    // Network / connection errors
    if (msg.contains('socketexception') ||
        msg.contains('handshakeexception') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated') ||
        msg.contains('clientexception') ||
        msg.contains('timeout')) {
      return AuthException(
        'Sin conexión a internet. Verifica tu red e intenta de nuevo.',
        code: 'network_error',
      );
    }

    // Certificate errors
    if (msg.contains('certificate') || msg.contains('ssl')) {
      return AuthException(
        'Error de conexión segura. Verifica tu red.',
        code: 'ssl_error',
      );
    }

    debugPrint('Unhandled error: $e');
    return AuthException(
      'Ocurrió un error inesperado. Intenta de nuevo.',
      code: 'unknown',
    );
  }
}
