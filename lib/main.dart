import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase/supabase_config.dart';
import 'core/services/security_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load .env for development; in release builds with --dart-define this can fail safely
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env not found is OK if using --dart-define
      if (kDebugMode) debugPrint('.env not found, using --dart-define values');
    }

    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Fatal initialization error: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error de inicialización.\nVerifica tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center),
        ),
      ),
    ));
    return;
  }

  await initializeDateFormatting('es');

  // Run security checks in release mode
  if (!kDebugMode) {
    try {
      final securityResult = await SecurityService.runChecks();
      if (!securityResult.passed) {
        debugPrint('Security warnings: ${securityResult.issues}');
      }
    } catch (e) {
      debugPrint('Security check failed: $e');
    }
  }

  // Prevent screenshots and screen recording in release mode
  if (!kDebugMode) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: AtrioApp()));
}
