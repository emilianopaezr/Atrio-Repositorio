import 'package:flutter/material.dart';
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
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
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
  String get asCurrency => NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(this);
  String get asCompactCurrency => NumberFormat.compactCurrency(symbol: '\$').format(this);
  String get asPercentage => '${(this * 100).toStringAsFixed(0)}%';
}
