import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized initialization for crash reporting (Sentry) and a thin
/// reporting API for the rest of the app.
///
/// Sentry is OPTIONAL. If `SENTRY_DSN` is not present in `.env`, the rest of
/// the app continues to work — every helper degrades to a no-op (or a
/// `debugPrint` in debug builds).
///
/// Wrap the app entrypoint with [ObservabilityService.runApp] so that
/// uncaught zone errors and Flutter framework errors are forwarded to
/// Sentry automatically.
class ObservabilityService {
  static bool _initialized = false;
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  /// Initializes Sentry and runs [appRunner] inside a guarded zone.
  ///
  /// `tracesSampleRate` defaults to 20% in release, 0% in debug to avoid
  /// noisy local dev traces.
  static Future<void> runApp(FutureOr<void> Function() appRunner) async {
    final dsn = _dsn();

    if (dsn == null || dsn.isEmpty) {
      // No DSN — just run the app, no crash reporting.
      _initialized = true;
      _enabled = false;
      await runZonedGuarded(() async {
        await appRunner();
      }, (error, stack) {
        if (kDebugMode) {
          debugPrint('[UNCAUGHT] $error\n$stack');
        }
      });
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.attachScreenshot = false;
        options.sendDefaultPii = false;
        options.debug = false;
      },
      appRunner: appRunner,
    );

    _initialized = true;
    _enabled = true;
  }

  /// Captures a non-fatal exception. Safe to call before init (no-op).
  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!_initialized || !_enabled) {
      if (kDebugMode) debugPrint('[ERR] $error');
      return;
    }
    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (_) {
      // Never let observability break the app.
    }
  }

  /// Adds a breadcrumb describing user navigation or app state change.
  /// Free-tier safe — Sentry keeps only the most recent ~100 per session.
  static void addBreadcrumb({
    required String message,
    String category = 'app',
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized || !_enabled) return;
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ));
    } catch (_) {
      // Swallow.
    }
  }

  /// Identifies the current authenticated user. Call after login, and
  /// `setUser(null)` after logout.
  static Future<void> setUser({String? id, String? email}) async {
    if (!_initialized || !_enabled) return;
    try {
      if (id == null) {
        await Sentry.configureScope((s) => s.setUser(null));
        return;
      }
      await Sentry.configureScope(
        (s) => s.setUser(SentryUser(id: id, email: email)),
      );
    } catch (_) {
      // Swallow.
    }
  }

  static String? _dsn() {
    try {
      final v = dotenv.maybeGet('SENTRY_DSN');
      if (v == null || v.trim().isEmpty) return null;
      return v.trim();
    } catch (_) {
      return null;
    }
  }
}
