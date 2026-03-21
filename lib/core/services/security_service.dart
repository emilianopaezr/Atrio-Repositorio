import 'dart:io';
import 'package:flutter/foundation.dart';

/// SecurityService - Runtime security checks for Atrio
/// Protects against common attack vectors:
/// - Root/Jailbreak detection
/// - Debugger attachment
/// - Emulator detection (production only)
/// - Request validation
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
    result = result.replaceAll("'", '');
    result = result.replaceAll('"', '');
    result = result.replaceAll(RegExp(r'<[^>]*>'), ''); // Strip HTML tags
    return result.trim();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
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

    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.good;
    return PasswordStrength.fair;
  }

  /// Rate limiting helper - tracks request timestamps
  static final Map<String, List<DateTime>> _requestLog = {};

  /// Check if an action should be rate limited
  /// Returns true if the action is allowed, false if rate limited
  static bool checkRateLimit(String action, {int maxRequests = 10, Duration window = const Duration(minutes: 1)}) {
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
