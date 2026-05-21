import 'package:atrio/core/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [SecurityService] — validators and sanitizers used during
/// signup, profile editing, file uploads. These guard the borders of the
/// app against malformed/malicious input.
void main() {
  group('isValidEmail', () {
    test('accepts standard email formats', () {
      expect(SecurityService.isValidEmail('user@example.com'), isTrue);
      expect(SecurityService.isValidEmail('first.last@example.cl'), isTrue);
      expect(SecurityService.isValidEmail('a+b@example.io'), isTrue);
      expect(SecurityService.isValidEmail('user_name@sub.domain.com'),
          isTrue);
    });

    test('rejects obviously malformed addresses', () {
      expect(SecurityService.isValidEmail(''), isFalse);
      expect(SecurityService.isValidEmail('plainaddress'), isFalse);
      expect(SecurityService.isValidEmail('@nodomain.com'), isFalse);
      expect(SecurityService.isValidEmail('user@'), isFalse);
      expect(SecurityService.isValidEmail('user@.com'), isFalse);
      expect(SecurityService.isValidEmail('user@domain'), isFalse);
    });

    test('rejects emails over 254 chars', () {
      final long = '${'a' * 250}@x.co';
      expect(SecurityService.isValidEmail(long), isFalse);
    });
  });

  group('checkPasswordStrength', () {
    test('flags short passwords as weak', () {
      expect(SecurityService.checkPasswordStrength('abc'), PasswordStrength.weak);
      expect(SecurityService.checkPasswordStrength('hello'), PasswordStrength.weak);
    });

    test('flags common passwords as weak even if long', () {
      expect(
        SecurityService.checkPasswordStrength('password123'),
        PasswordStrength.weak,
      );
      expect(
        SecurityService.checkPasswordStrength('qwerty12345'),
        PasswordStrength.weak,
      );
    });

    test('strong password requires length + variety', () {
      // 12+ chars, upper, lower, digit, symbol → score 5+
      expect(
        SecurityService.checkPasswordStrength('Tigre2025!Bosque'),
        PasswordStrength.strong,
      );
    });

    test('returns good for 8-char alphanumeric', () {
      // 8 chars + lower + digit + length≥8 = 3 score → good
      expect(
        SecurityService.checkPasswordStrength('abcd1234'),
        PasswordStrength.good,
      );
    });
  });

  group('sanitizeInput', () {
    test('strips <script> tags', () {
      final dirty = 'hi <script>alert(1)</script> there';
      expect(SecurityService.sanitizeInput(dirty), 'hi  there');
    });

    test('strips arbitrary HTML', () {
      expect(
        SecurityService.sanitizeInput('<b>bold</b> text'),
        'bold text',
      );
    });

    test('removes semicolons (SQL injection vector)', () {
      expect(
        SecurityService.sanitizeInput("Robert'); DROP TABLE users--"),
        "Robert') DROP TABLE users--",
      );
    });

    test('truncates inputs over 5000 chars', () {
      final huge = 'x' * 6000;
      expect(SecurityService.sanitizeInput(huge).length, 5000);
    });
  });

  group('sanitizeFilename', () {
    test('strips path traversal sequences', () {
      expect(
        SecurityService.sanitizeFilename('../../etc/passwd'),
        'etcpasswd',
      );
    });

    test('replaces unsafe characters with underscore', () {
      expect(
        SecurityService.sanitizeFilename('hello world!.png'),
        'hello_world_.png',
      );
    });

    test('keeps safe filenames intact', () {
      expect(
        SecurityService.sanitizeFilename('photo_2025.jpg'),
        'photo_2025.jpg',
      );
    });
  });

  group('isValidSecureUrl', () {
    test('accepts https URLs', () {
      expect(SecurityService.isValidSecureUrl('https://atrio.app'), isTrue);
      expect(
        SecurityService.isValidSecureUrl('https://api.example.com/v1/foo'),
        isTrue,
      );
    });

    test('rejects http (insecure)', () {
      expect(
        SecurityService.isValidSecureUrl('http://atrio.app'),
        isFalse,
      );
    });

    test('rejects malformed URLs', () {
      expect(SecurityService.isValidSecureUrl('not a url'), isFalse);
      expect(SecurityService.isValidSecureUrl('https://'), isFalse);
    });
  });
}
