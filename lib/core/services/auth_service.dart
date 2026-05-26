import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase/supabase_config.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'analytics_service.dart';
import 'observability_service.dart';
import 'push_service.dart';
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
      AppLogger.w('fetch email_verified: $e', tag: 'auth');
      // On error, keep previous state or set null to retry later
      emailVerified ??= null;
    }
    return emailVerified ?? false;
  }

  /// Sign up with email & password
  ///
  /// Handles a tricky edge case: when an email exists in `auth.users` but
  /// was never verified (e.g. user signed up, never received/used the
  /// OTP), Supabase reports the email as taken — but the user can't
  /// actually log in. To unstick them, when we detect this we try the
  /// password we were given:
  ///   • If it matches → restore the session, reset the verified flag,
  ///     request a fresh OTP, and let the caller route to the verify
  ///     screen.
  ///   • If it doesn't match → it's someone else's account; surface the
  ///     normal "ya registrado" error so they go to login.
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

      // Email taken case: identities list is empty when Supabase silently
      // refuses to recreate an existing account.
      final emailAlreadyTaken =
          response.session == null && (response.user!.identities?.isEmpty ?? false);

      if (emailAlreadyTaken) {
        // Try to log in with the password the user just gave us. If it
        // works AND the email isn't verified yet, we treat this as a
        // resumed signup: fire a new OTP and bubble the session up so the
        // UI can land on /auth/verify-email.
        try {
          final loginResp = await SupabaseConfig.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (loginResp.session != null && loginResp.user != null) {
            final isVerified = await isEmailVerified();
            if (!isVerified) {
              emailVerified = false;
              // Re-issue verification code; best-effort, ignore failures.
              try {
                await requestVerificationCode();
              } catch (_) {}
              return loginResp;
            }
            // Email IS already verified — the account is fully usable.
            // Tell the caller so they route to login.
            await SupabaseConfig.auth.signOut();
            throw AuthException(
              'Este email ya está registrado. Intenta iniciar sesión.',
              code: 'email_exists',
            );
          }
        } on AuthException {
          rethrow;
        } catch (_) {
          // Password didn't match: surface the standard "already taken"
          // error so the user is sent to login.
        }

        throw AuthException(
          'Este email ya está registrado. Intenta iniciar sesión.',
          code: 'email_exists',
        );
      }

      if (response.session == null && response.user != null) {
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
          AppLogger.w('profile creation: $e', tag: 'auth');
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
          AppLogger.w('profile check: $e', tag: 'auth');
        }

        // Wire identity into observability + analytics, register FCM token.
        await ObservabilityService.setUser(
          id: response.user!.id,
          email: response.user!.email,
        );
        await AnalyticsService.setUserId(response.user!.id);
        AnalyticsService.logLogin('password');
        // Fire-and-forget: never block login on permission prompt or token.
        unawaited(PushService.registerCurrentUser());
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
    await PushService.unregisterCurrentDevice();
    await ObservabilityService.setUser();
    await AnalyticsService.setUserId(null);
    await SupabaseConfig.auth.signOut();
  }

  /// Sign out and clear all cached state
  static Future<void> signOutAndClear() async {
    emailVerified = null;
    try {
      await RealtimeService.removeAllChannels();
    } catch (_) {}
    await PushService.unregisterCurrentDevice();
    await ObservabilityService.setUser();
    await AnalyticsService.setUserId(null);
    await SupabaseConfig.auth.signOut();
  }

  /// Reset password — sends a 6-digit OTP via our branded Brevo flow
  /// instead of the built-in Supabase recovery link (which only works
  /// with a real configured SMTP). The user then calls
  /// [verifyPasswordReset] with the code + new password to complete.
  static Future<void> resetPassword(String email) =>
      requestPasswordResetCode(email);

  static User? get currentUser => SupabaseConfig.auth.currentUser;
  static Session? get currentSession => SupabaseConfig.auth.currentSession;
  static bool get isAuthenticated => currentUser != null;

  /// Step 1 of strict signup. Stores email/name/password in a
  /// short-lived `pending_signups` row (NOT in auth.users) and emails
  /// the user a 6-digit OTP. Nothing in auth.users yet — if the user
  /// never verifies, the pending row expires on its own.
  ///
  /// Throws [AuthException] if the email is already registered, the
  /// rate limit is hit, validation fails, or Brevo rejects the email.
  static Future<void> requestPendingSignup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await SupabaseConfig.client.rpc('request_signup', params: {
        'p_email': email,
        'p_name': displayName,
        'p_password': password,
      });
    } on PostgrestException catch (e) {
      throw _mapPendingSignupError(e);
    } catch (e) {
      throw AuthException(
        'No se pudo iniciar el registro. Intenta de nuevo.',
        code: 'pending_signup_error',
      );
    }
  }

  /// Step 2 of strict signup. Validates the OTP against the
  /// `pending_signups` row, then atomically creates the real
  /// auth.users + profile rows and deletes the pending row.
  ///
  /// On success, sign the user in with the original password to
  /// obtain a session.
  static Future<void> verifyPendingSignup({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      await SupabaseConfig.client.rpc('verify_signup', params: {
        'p_email': email,
        'p_code': code,
      });
      // Account exists in auth.users now — sign in to obtain a JWT.
      await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on PostgrestException catch (e) {
      throw _mapPendingSignupError(e);
    } on AuthApiException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw AuthException(
        'Error al verificar el código. Intenta de nuevo.',
        code: 'verify_signup_error',
      );
    }
  }

  static AuthException _mapPendingSignupError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered')) {
      return AuthException(
        'Este email ya está registrado. Intenta iniciar sesión.',
        code: 'email_exists',
      );
    }
    if (msg.contains('too many attempts')) {
      return AuthException(
        'Demasiados intentos. Espera 10 minutos.',
        code: 'rate_limited',
      );
    }
    if (msg.contains('invalid code')) {
      return AuthException(
        'Código incorrecto. Intenta de nuevo.',
        code: 'invalid_code',
      );
    }
    if (msg.contains('code expired')) {
      return AuthException(
        'El código expiró. Solicita uno nuevo.',
        code: 'code_expired',
      );
    }
    if (msg.contains('no pending signup')) {
      return AuthException(
        'No hay registro pendiente. Empieza de nuevo.',
        code: 'no_pending',
      );
    }
    if (msg.contains('brevo')) {
      return AuthException(
        'No se pudo enviar el código. Intenta de nuevo en unos minutos.',
        code: 'brevo_error',
      );
    }
    if (msg.contains('invalid email')) {
      return AuthException('Email no válido', code: 'invalid_email');
    }
    if (msg.contains('password must be')) {
      return AuthException(
        'La contraseña debe tener al menos 8 caracteres.',
        code: 'weak_password',
      );
    }
    return AuthException(
      'No se pudo procesar el registro. Intenta de nuevo.',
      code: 'pending_signup_error',
    );
  }

  /// Asks the backend to email a 6-digit password-recovery code. To
  /// avoid email-enumeration, the RPC always returns success — the
  /// email is only actually sent when the address exists.
  static Future<void> requestPasswordResetCode(String email) async {
    try {
      await SupabaseConfig.client.rpc(
        'request_password_reset',
        params: {'p_email': email},
      );
    } on PostgrestException catch (e) {
      throw _mapPendingSignupError(e);
    } catch (e) {
      throw AuthException(
        'No se pudo enviar el código. Intenta de nuevo.',
        code: 'reset_request_error',
      );
    }
  }

  /// Completes the password reset: validates the 6-digit code and
  /// updates `auth.users.encrypted_password`. The DB trigger fires the
  /// "contraseña actualizada" confirmation email automatically.
  static Future<void> verifyPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await SupabaseConfig.client.rpc(
        'verify_password_reset',
        params: {
          'p_email': email,
          'p_code': code,
          'p_new_password': newPassword,
        },
      );
    } on PostgrestException catch (e) {
      throw _mapPendingSignupError(e);
    } catch (e) {
      throw AuthException(
        'Error al actualizar la contraseña. Intenta de nuevo.',
        code: 'reset_verify_error',
      );
    }
  }

  /// Legacy method retained for the resend-from-verify-screen flow
  /// (used when the user is already authenticated but unverified).
  /// New signups should use [requestPendingSignup] + [verifyPendingSignup].
  static Future<void> requestVerificationCode() async {
    try {
      await SupabaseConfig.client.rpc('request_verification');
    } catch (e) {
      AppLogger.w('request verification: $e', tag: 'auth');
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
      AppLogger.w('verify OTP: $e', tag: 'auth');
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
      AppLogger.w('check email verification: $e', tag: 'auth');
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
    if ((msg.contains('password') && msg.contains('weak')) ||
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
    AppLogger.w('unhandled auth error: ${e.message} (code: ${e.code})',
        tag: 'auth');
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

    AppLogger.w('unhandled error: $e', tag: 'auth');
    return AuthException(
      'Ocurrió un error inesperado. Intenta de nuevo.',
      code: 'unknown',
    );
  }
}
