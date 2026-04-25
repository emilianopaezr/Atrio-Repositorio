import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isDarkMode => theme.brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('MMM d, yyyy').format(this);
  String get formattedTime => DateFormat('h:mm a').format(this);
  String get formattedDateTime => DateFormat('MMM d, yyyy h:mm a').format(this);
  String get formattedShort => DateFormat('MMM d').format(this);
  String get dayOfWeek => DateFormat('EEEE').format(this);
  String get monthYear => DateFormat('MMMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
}

extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return length >= 2 ? substring(0, 2).toUpperCase() : toUpperCase();
  }
}

extension DoubleExtensions on double {
  String get asCurrency => NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CL', name: 'CLP').format(this);
  String get asCompactCurrency => NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0).format(this);
  String get asPercentage => '${(this * 100).toStringAsFixed(0)}%';
}

/// CLP formatter for num (int or double). Returns e.g. "$25.000"
extension NumCLP on num {
  static final _fmt = NumberFormat('#,##0', 'es_CL');
  String get toCLP => '\$${_fmt.format(this)}';
}

/// Haptic feedback helpers
class Haptics {
  Haptics._();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
}
