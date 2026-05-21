import 'package:flutter/foundation.dart';

import '../services/observability_service.dart';

/// Lightweight logger wrapper.
///
///   • `d` (debug) — only prints in debug builds. Use for verbose
///     diagnostic output.
///   • `i` (info)  — prints in debug + adds a Sentry breadcrumb.
///   • `w` (warn)  — prints in debug + adds a warning breadcrumb. Use
///     for recoverable issues you want to see in Sentry context.
///   • `e` (error) — prints in debug + forwards to Sentry as a captured
///     exception (non-fatal). Always include the original `error` and
///     `stackTrace` if you have them.
///
/// `e` is the only level that creates a Sentry event. The rest are
/// breadcrumbs (free, attached to the next captured exception).
class AppLogger {
  AppLogger._();

  static void d(Object? message, {String tag = 'app'}) {
    if (kDebugMode) debugPrint('[D][$tag] $message');
  }

  static void i(Object? message, {String tag = 'app', Map<String, dynamic>? data}) {
    if (kDebugMode) debugPrint('[I][$tag] $message');
    ObservabilityService.addBreadcrumb(
      message: message.toString(),
      category: tag,
      data: data,
    );
  }

  static void w(Object? message, {String tag = 'app', Map<String, dynamic>? data}) {
    if (kDebugMode) debugPrint('[W][$tag] $message');
    ObservabilityService.addBreadcrumb(
      message: message.toString(),
      category: tag,
      data: data,
    );
  }

  static void e(
    Object? message, {
    String tag = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[E][$tag] $message');
      if (error != null) debugPrint('  └─ error: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
    if (error != null) {
      ObservabilityService.captureException(
        error,
        stackTrace: stackTrace,
        hint: '[$tag] $message',
      );
    }
  }
}
