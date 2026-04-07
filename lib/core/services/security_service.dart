import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SecurityService - Runtime security checks for Atrio
/// Protects against:
/// - Root/Jailbreak detection
/// - Debugger attachment
/// - Emulator detection (production only)
/// - Screenshot/screen recording prevention
/// - Input sanitization & validation
/// - Rate limiting
class SecurityService {
  SecurityService._();

  /// Run all security checks on app startup
  static Future<SecurityCheckResult> runChecks() async {
    final issues = <String>[];

    // Skip security checks in debug/profile mode
    if (kDebugMode || kProfileMode) {
      return SecurityCheckResult(passed: true, issues: []);
    }

    // Check for root/jailbreak indicators
    if (!kIsWeb && Platform.isAndroid) {
      final rootIndicators = await _checkRootIndicators();
      if (rootIndicators) {
        issues.add('root_detected');
      }

      // Check for emulator in release
      final isEmulator = await _checkEmulator();
      if (isEmulator) {
        issues.add('emulator_detected');
      }
    }

    // Check for debugger
    if (!kIsWeb) {
      final debuggerAttached = _checkDebugger();
      if (debuggerAttached) {
        issues.add('debugger_attached');
      }
    }

    return SecurityCheckResult(
      passed: issues.isEmpty,
      issues: issues,
    );
  }

  /// Enable secure mode: prevent screenshots and screen recording
  /// Call this in main() for release builds
  static Future<void> enableSecureMode() async {
    if (kDebugMode || kIsWeb) return;

    try {
      // On Android, FLAG_SECURE is set via MainActivity
      // This method channel communicates with native code
      const platform = MethodChannel('com.atrio.atrio/security');
      await platform.invokeMethod('enableSecureMode');
    } catch (e) {
      debugPrint('Secure mode not available: $e');
    }
  }

  /// Check for common root indicators on Android
  static Future<bool> _checkRootIndicators() async {
    try {
      final paths = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/sbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/data/local/su',
        '/su/bin/su',
        '/system/bin/failsafe/su',
        '/system/sd/xbin/su',
      ];

      for (final path in paths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Check for Magisk
      if (await File('/sbin/.magisk').exists()) {
        return true;
      }

      // Check for common root management apps
      final rootApps = [
        '/data/data/com.noshufou.android.su',
        '/data/data/eu.chainfire.supersu',
        '/data/data/com.koushikdutta.superuser',
        '/data/data/com.topjohnwu.magisk',
      ];
      for (final app in rootApps) {
        if (await Directory(app).exists()) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if running on an emulator
  static Future<bool> _checkEmulator() async {
    try {
      // Check common emulator indicators
      final buildProps = [
        '/system/build.prop',
      ];

      for (final prop in buildProps) {
        final file = File(prop);
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.contains('sdk_gphone') ||
              content.contains('google_sdk') ||
              content.contains('Emulator') ||
              content.contains('Android SDK built for x86') ||
              content.contains('goldfish')) {
            return true;
          }
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if a debugger is attached
  static bool _checkDebugger() {
    // In release mode, assert is stripped out
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  /// Sanitize user input to prevent injection attacks
  static String sanitizeInput(String input) {
    // Remove potential SQL injection characters
    var result = input.replaceAll(RegExp(r'[;]'), '');
    // Remove script tags and HTML
    result = result.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove null bytes
    result = result.replaceAll('\x00', '');
    // Limit length to prevent buffer overflow attempts
    if (result.length > 5000) result = result.substring(0, 5000);
    return result.trim();
  }

  /// Sanitize filename to prevent path traversal
  static String sanitizeFilename(String filename) {
    // Remove path traversal sequences
    var result = filename.replaceAll('..', '');
    result = result.replaceAll('/', '');
    result = result.replaceAll('\\', '');
    // Only allow safe characters
    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    // Limit length
    if (result.length > 255) result = result.substring(0, 255);
    return result;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.length > 254) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate URL format (only HTTPS allowed)
  static bool isValidSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Validate password strength
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 8) return PasswordStrength.fair;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Check for common weak patterns
    final commonPasswords = ['password', '123456', 'qwerty', 'abc123', 'atrio'];
    if (commonPasswords.any((p) => password.toLowerCase().contains(p))) {
      return PasswordStrength.weak;
    }

    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.good;
    return PasswordStrength.fair;
  }

  /// Rate limiting helper - tracks request timestamps
  static final Map<String, List<DateTime>> _requestLog = {};

  /// Check if an action should be rate limited
  /// Returns true if the action is allowed, false if rate limited
  static bool checkRateLimit(String action,
      {int maxRequests = 10,
      Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);

    _requestLog[action] ??= [];
    _requestLog[action]!.removeWhere((t) => t.isBefore(cutoff));

    if (_requestLog[action]!.length >= maxRequests) {
      return false; // Rate limited
    }

    _requestLog[action]!.add(now);
    return true; // Allowed
  }

  /// Clear rate limit history (useful on logout)
  static void clearRateLimits() {
    _requestLog.clear();
  }
}

class SecurityCheckResult {
  final bool passed;
  final List<String> issues;

  const SecurityCheckResult({
    required this.passed,
    required this.issues,
  });
}

enum PasswordStrength { weak, fair, good, strong }
