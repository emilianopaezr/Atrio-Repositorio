import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration with secure key management.
///
/// Keys are loaded from either:
/// 1. Compile-time --dart-define (preferred for release builds)
/// 2. .env file fallback (for local development only)
///
/// To build with compile-time keys:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  // Compile-time constants from --dart-define (empty string if not provided)
  static const _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    // Prefer compile-time define, fall back to .env
    if (_defineUrl.isNotEmpty) return _defineUrl;
    final value = dotenv.env['SUPABASE_URL'] ?? '';
    if (value.isEmpty) {
      throw Exception('SUPABASE_URL not configured. Use --dart-define or .env');
    }
    return value;
  }

  static String get anonKey {
    if (_defineAnonKey.isNotEmpty) return _defineAnonKey;
    final value = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (value.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not configured. Use --dart-define or .env');
    }
    return value;
  }

  /// Google Maps API key (compile-time only, never in .env)
  static const mapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static Future<void> initialize() async {
    final supabaseUrl = url;
    final supabaseKey = anonKey;

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Supabase credentials missing. Check configuration.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    if (kDebugMode) {
      debugPrint('Supabase initialized (${_defineUrl.isNotEmpty ? "dart-define" : ".env"})');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
}
