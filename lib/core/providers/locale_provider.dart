import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'app_locale';
const String _defaultLocale = 'es';

/// Persisted app locale. Defaults to Spanish.
///
/// The Notifier reads the saved value on build and exposes `setLocale` /
/// `setLanguageCode` to switch between Spanish and English.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Kick off async load; start with default until prefs are read.
    _load();
    return const Locale(_defaultLocale);
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final code = p.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {
      // Prefs unavailable → keep default.
    }
  }

  Future<void> setLanguageCode(String code) async {
    if (state.languageCode == code) return;
    state = Locale(code);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, code);
    } catch (_) {
      // Non-fatal; memory state still updated.
    }
  }
}
