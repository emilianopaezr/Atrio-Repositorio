import 'package:shared_preferences/shared_preferences.dart';

/// Reads the user's notification category toggles from SharedPreferences and
/// decides whether an incoming push of a given `type` should be displayed.
///
/// The same keys are written by the Settings screen:
///   notif_bookings, notif_messages, notif_reminders, notif_promos, notif_updates
///
/// If the pref for a category hasn't been set yet, the default from the
/// Settings UI is used (matches what the user sees on first launch).
class NotificationPrefs {
  NotificationPrefs._();

  static const String _kBookings = 'notif_bookings';
  static const String _kMessages = 'notif_messages';
  static const String _kReminders = 'notif_reminders';
  static const String _kPromos = 'notif_promos';
  static const String _kUpdates = 'notif_updates';

  /// Returns `true` when a notification of the given `type` should be shown.
  /// An empty / unknown `type` defaults to shown (safer than hiding).
  static Future<bool> shouldShow(String? type) async {
    final key = _keyForType(type);
    if (key == null) return true;
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(key) ?? _defaultFor(key);
    } catch (_) {
      return true;
    }
  }

  static String? _keyForType(String? type) {
    if (type == null || type.isEmpty) return null;
    final t = type.toLowerCase();
    // Bookings / reservations
    if (t.contains('booking') ||
        t.contains('reserv') ||
        t == 'reserva' ||
        t == 'reservation') {
      return _kBookings;
    }
    // Messages / chat
    if (t.contains('message') ||
        t.contains('mensaje') ||
        t.contains('chat') ||
        t == 'msg') {
      return _kMessages;
    }
    // Reminders
    if (t.contains('reminder') || t.contains('recordatorio')) {
      return _kReminders;
    }
    // Promotions
    if (t.contains('promo') || t.contains('offer') || t.contains('oferta')) {
      return _kPromos;
    }
    // App updates
    if (t.contains('update') || t.contains('actualiz')) {
      return _kUpdates;
    }
    // Unknown type → show
    return null;
  }

  static bool _defaultFor(String key) {
    // Match defaults used in settings_screen.dart.
    switch (key) {
      case _kPromos:
        return false;
      default:
        return true;
    }
  }
}
