import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase/supabase_config.dart';
import 'core/services/cache_service.dart';
import 'core/services/observability_service.dart';
import 'core/services/push_service.dart';
import 'core/services/security_service.dart';
import 'core/utils/app_logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env BEFORE Sentry so we can read SENTRY_DSN.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not found is OK if using --dart-define
    AppLogger.d('.env not found, using --dart-define values');
  }

  // Wrap everything so uncaught errors land in Sentry.
  await ObservabilityService.runApp(() async {
    try {
      await SupabaseConfig.initialize();
      // Offline cache — best-effort, never fatal.
      await CacheService.initialize();
      // Push notifications — no-op if google-services.json is missing.
      await PushService.initialize();
    } catch (e, st) {
      AppLogger.e('Fatal initialization error', error: e, stackTrace: st);
      await ObservabilityService.captureException(e, stackTrace: st);
      runApp(const _BootError());
      return;
    }

    await initializeDateFormatting('es');

    // Run security checks in release mode
    if (!kDebugMode) {
      try {
        final securityResult = await SecurityService.runChecks();
        if (!securityResult.passed) {
          AppLogger.w('Security warnings: ${securityResult.issues}');
        }
      } catch (e, st) {
        AppLogger.e('Security check failed', error: e, stackTrace: st);
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

    // Forward Flutter framework errors to Sentry too.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ObservabilityService.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    };

    runApp(const ProviderScope(child: AtrioApp()));
  });
}

class _BootError extends StatelessWidget {
  const _BootError();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Error de inicialización.\nVerifica tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
