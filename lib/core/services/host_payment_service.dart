import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/supabase/supabase_config.dart';
import '../utils/app_logger.dart';

/// Read-side helpers + OAuth init for the host's MP marketplace
/// account. Writes happen ONLY in the mp-oauth-callback Edge Function
/// (service_role). The Flutter side just kicks off the flow and polls
/// the status afterward.
class HostPaymentService {
  HostPaymentService._();

  /// Wired in .env. Empty when the marketplace flow hasn't been
  /// provisioned yet — UI uses [marketplaceConfigured] to gate the
  /// "Conectar" button.
  static String get oauthInitUrl =>
      dotenv.env['MP_OAUTH_INIT_URL'] ?? '';

  static bool get marketplaceConfigured => oauthInitUrl.isNotEmpty;

  /// Fetches the current host's MP connection status from the
  /// redacted `host_payment_status` view (via my_payment_status RPC).
  /// Returns null when the host hasn't connected yet.
  static Future<HostPaymentStatus?> fetchMyStatus() async {
    try {
      final response =
          await SupabaseConfig.client.rpc('my_payment_status');
      if (response == null) return null;
      // The RPC returns a composite row — supabase-js + flutter parse
      // it as a Map.
      if (response is Map<String, dynamic>) {
        return HostPaymentStatus.fromJson(response);
      }
      if (response is List && response.isNotEmpty) {
        final first = response.first;
        if (first is Map<String, dynamic>) {
          return HostPaymentStatus.fromJson(first);
        }
      }
      return null;
    } catch (e) {
      AppLogger.w('my_payment_status failed', tag: 'mp', data: {'err': '$e'});
      return null;
    }
  }

  /// Convenience: true when the host can receive split payments today.
  static Future<bool> isConnected() async {
    final s = await fetchMyStatus();
    if (s == null) return false;
    if (!s.isActive) return false;
    if (s.isExpired) return false;
    return true;
  }

  /// Asks the backend for the MP authorize URL. The mobile app then
  /// opens this URL in an external browser; MP redirects back to the
  /// mp-oauth-callback Edge Function which persists the tokens.
  static Future<String> requestAuthorizeUrl() async {
    if (!marketplaceConfigured) {
      throw const HostPaymentException(
          'MP Marketplace no está configurado en este build.');
    }
    final session = SupabaseConfig.auth.currentSession;
    if (session == null) {
      throw const HostPaymentException('Sesión expirada.');
    }
    final res = await http.post(
      Uri.parse(oauthInitUrl),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
    if (res.statusCode != 200) {
      AppLogger.e('mp-oauth-init failed (HTTP ${res.statusCode}): ${res.body}',
          tag: 'mp');
      throw HostPaymentException(
          'No se pudo iniciar la conexión (HTTP ${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final url = body['authorize_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const HostPaymentException(
          'Respuesta inválida del servidor (sin authorize_url).');
    }
    return url;
  }
}

class HostPaymentStatus {
  final String hostId;
  final String provider;
  final String? mpUserId;
  final bool mpLiveMode;
  final bool isActive;
  final bool isExpired;
  final DateTime? connectedAt;
  final DateTime? lastRefreshedAt;

  const HostPaymentStatus({
    required this.hostId,
    required this.provider,
    required this.mpUserId,
    required this.mpLiveMode,
    required this.isActive,
    required this.isExpired,
    required this.connectedAt,
    required this.lastRefreshedAt,
  });

  factory HostPaymentStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return HostPaymentStatus(
      hostId: (json['host_id'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      mpUserId: json['mp_user_id']?.toString(),
      mpLiveMode: json['mp_live_mode'] == true,
      isActive: json['is_active'] == true,
      isExpired: json['is_expired'] == true,
      connectedAt: parseTs(json['connected_at']),
      lastRefreshedAt: parseTs(json['last_refreshed_at']),
    );
  }

  /// Convenience: connected + token not expired.
  bool get isUsable => isActive && !isExpired && (mpUserId?.isNotEmpty ?? false);
}

class HostPaymentException implements Exception {
  final String message;
  const HostPaymentException(this.message);

  @override
  String toString() => message;
}
