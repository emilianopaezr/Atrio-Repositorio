import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized error handler that maps raw exceptions to
/// user-friendly Spanish messages for the Atrio app.
class ErrorHandler {
  ErrorHandler._();

  /// Convert any exception to a user-friendly message in Spanish.
  static String friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();

    // ── Supabase / PostgREST errors ──
    if (error is PostgrestException) {
      return _mapPostgrestError(error);
    }

    // ── Storage errors ──
    if (error is StorageException) {
      return _mapStorageError(error);
    }

    // ── Auth errors (from Supabase) ──
    if (error is AuthApiException) {
      return _mapAuthApiError(error);
    }

    // ── Network / connectivity ──
    if (error is SocketException ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('network is unreachable') ||
        msg.contains('no address associated') ||
        msg.contains('clientexception')) {
      return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
    }

    if (error is HttpException || msg.contains('httpexception')) {
      return 'Error de comunicación con el servidor. Intenta de nuevo.';
    }

    if (msg.contains('timeout') || error is TimeoutException) {
      return 'La solicitud tardó demasiado. Verifica tu conexión e intenta de nuevo.';
    }

    if (msg.contains('handshakeexception') ||
        msg.contains('certificate') ||
        msg.contains('ssl')) {
      return 'Error de conexión segura. Verifica tu red.';
    }

    // ── Format / parsing errors ──
    if (error is FormatException || msg.contains('formatexception')) {
      return 'Error al procesar los datos. Intenta de nuevo.';
    }

    // ── File size / upload ──
    if (msg.contains('demasiado grande') || msg.contains('too large') || msg.contains('payload too large')) {
      return 'El archivo es demasiado grande. Reduce su tamaño e intenta de nuevo.';
    }

    // ── Permission denied ──
    if (msg.contains('permission denied') || msg.contains('permiso')) {
      return 'No tienes permiso para realizar esta acción.';
    }

    // ── Session expired ──
    if (msg.contains('jwt expired') ||
        msg.contains('token expired') ||
        msg.contains('sesión expirada') ||
        msg.contains('refresh_token_not_found')) {
      return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
    }

    // ── RLS / row-level security ──
    if (msg.contains('row-level security') || msg.contains('rls')) {
      return 'No tienes acceso a este recurso.';
    }

    // ── Generic ──
    debugPrint('ErrorHandler unhandled: $error');
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }

  // ── PostgREST (database) errors ──
  static String _mapPostgrestError(PostgrestException e) {
    final code = e.code ?? '';
    final msg = (e.message).toLowerCase();

    if (code == '23505' || msg.contains('duplicate') || msg.contains('unique')) {
      return 'Este registro ya existe.';
    }
    if (code == '23503' || msg.contains('foreign key')) {
      return 'No se puede completar porque depende de otro registro.';
    }
    if (code == '23502' || msg.contains('not-null')) {
      return 'Faltan datos obligatorios. Completa todos los campos.';
    }
    if (code == '42501' || msg.contains('permission denied')) {
      return 'No tienes permiso para realizar esta acción.';
    }
    if (code == 'PGRST301' || msg.contains('jwt expired')) {
      return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
    }
    if (msg.contains('timeout') || msg.contains('canceling statement')) {
      return 'La consulta tardó demasiado. Intenta de nuevo.';
    }

    debugPrint('PostgREST error: ${e.code} - ${e.message}');
    return 'Error al acceder a los datos. Intenta de nuevo.';
  }

  // ── Storage errors ──
  static String _mapStorageError(StorageException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('not found') || msg.contains('404')) {
      return 'El archivo no fue encontrado.';
    }
    if (msg.contains('too large') || msg.contains('payload')) {
      return 'El archivo es demasiado grande.';
    }
    if (msg.contains('permission') || msg.contains('policy') || msg.contains('403')) {
      return 'No tienes permiso para subir este archivo.';
    }
    if (msg.contains('duplicate') || msg.contains('already exists')) {
      return 'Ya existe un archivo con ese nombre.';
    }

    debugPrint('Storage error: ${e.message}');
    return 'Error al procesar el archivo. Intenta de nuevo.';
  }

  // ── Auth API errors ──
  static String _mapAuthApiError(AuthApiException e) {
    final msg = e.message.toLowerCase();
    final code = e.code ?? '';

    if (msg.contains('invalid login') || code == 'invalid_credentials') {
      return 'Email o contraseña incorrectos.';
    }
    if (msg.contains('email not confirmed') || code == 'email_not_confirmed') {
      return 'Tu email no está confirmado. Revisa tu bandeja de entrada.';
    }
    if (msg.contains('already registered') || code == 'user_already_exists') {
      return 'Este email ya está registrado.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Demasiados intentos. Espera un momento.';
    }

    debugPrint('Auth API error: ${e.message} (code: ${e.code})');
    return 'Error de autenticación. Intenta de nuevo.';
  }

  /// Show a SnackBar with the friendly error message.
  static void showError(BuildContext context, Object error) {
    final message = friendlyMessage(error);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show a success SnackBar.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Colors.black))),
          ],
        ),
        backgroundColor: const Color(0xFFD4FF00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
