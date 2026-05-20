import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public URLs hosted at github.com/emilianopaezr/atrio-legal.
/// GitHub renders the markdown automatically — no Pages config required.
class LegalUrls {
  static const String terms =
      'https://github.com/emilianopaezr/atrio-legal/blob/main/terms.md';
  static const String privacy =
      'https://github.com/emilianopaezr/atrio-legal/blob/main/privacy.md';

  /// Opens [url] in the platform's default browser. Returns `true` if the
  /// launcher accepted the request. Logs (debug only) on failure.
  static Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('LegalUrls.open failed for $url: $e');
      return false;
    }
  }
}
