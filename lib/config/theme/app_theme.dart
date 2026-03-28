import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AtrioTheme {
  AtrioTheme._();

  // === Guest Theme (Light — white + warm gray, lime green as accent only) ===
  static ThemeData get guestTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AtrioColors.guestBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AtrioColors.electricViolet,
      onPrimary: Colors.white,
      secondary: AtrioColors.neonLime,
      onSecondary: Colors.black,
      surface: AtrioColors.guestSurface,
      onSurface: AtrioColors.guestTextPrimary,
      surfaceContainerHighest: AtrioColors.warmGray,
      error: AtrioColors.error,
      onError: Colors.white,
      outline: AtrioColors.guestCardBorder,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AtrioColors.guestBackground,
      foregroundColor: AtrioColors.guestTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AtrioTypography.headingMedium,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AtrioColors.guestNavBar,
      selectedItemColor: AtrioColors.electricViolet,
      unselectedItemColor: AtrioColors.guestTextTertiary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: AtrioTypography.caption,
      unselectedLabelStyle: AtrioTypography.caption,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: AtrioColors.guestSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AtrioColors.guestCardBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AtrioColors.guestInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.guestCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.electricViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: AtrioTypography.bodyMedium.copyWith(
        color: AtrioColors.guestTextTertiary,
      ),
      labelStyle: AtrioTypography.labelMedium.copyWith(
        color: AtrioColors.guestTextSecondary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AtrioColors.electricViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AtrioTypography.buttonLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AtrioColors.electricViolet,
        side: const BorderSide(color: AtrioColors.electricViolet),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AtrioTypography.buttonLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AtrioColors.electricViolet,
        textStyle: AtrioTypography.buttonMedium,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AtrioColors.warmGray,
      selectedColor: AtrioColors.electricViolet.withValues(alpha: 0.12),
      side: const BorderSide(color: AtrioColors.guestCardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: AtrioTypography.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? Colors.white : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.electricViolet : AtrioColors.guestSurfaceVariant),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.electricViolet : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.electricViolet : AtrioColors.guestTextTertiary),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AtrioColors.electricViolet,
      thumbColor: AtrioColors.electricViolet,
      inactiveTrackColor: AtrioColors.guestSurfaceVariant,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AtrioColors.electricViolet,
    ),
    dividerTheme: const DividerThemeData(
      color: AtrioColors.guestDivider,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AtrioColors.guestBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AtrioColors.guestBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AtrioColors.guestTextPrimary,
      contentTextStyle: AtrioTypography.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // === Host Theme (Dark — lime green only as accent for CTAs/badges) ===
  static ThemeData get hostTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AtrioColors.hostBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AtrioColors.electricViolet,
      onPrimary: Colors.white,
      secondary: AtrioColors.neonLime,
      onSecondary: Colors.black,
      surface: AtrioColors.hostSurface,
      onSurface: AtrioColors.hostTextPrimary,
      error: AtrioColors.error,
      onError: Colors.white,
      outline: AtrioColors.hostCardBorder,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AtrioColors.hostBackground,
      foregroundColor: AtrioColors.hostTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AtrioTypography.headingMedium,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AtrioColors.hostNavBar,
      selectedItemColor: AtrioColors.neonLime,
      unselectedItemColor: AtrioColors.hostTextTertiary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: AtrioTypography.caption,
      unselectedLabelStyle: AtrioTypography.caption,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AtrioColors.hostSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AtrioColors.hostCardBorder, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AtrioColors.hostInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.hostCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.electricViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AtrioColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: AtrioTypography.bodyMedium.copyWith(
        color: AtrioColors.hostTextTertiary,
      ),
      labelStyle: AtrioTypography.labelMedium.copyWith(
        color: AtrioColors.hostTextSecondary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AtrioColors.electricViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AtrioTypography.buttonLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AtrioColors.electricViolet,
        side: const BorderSide(color: AtrioColors.electricViolet),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AtrioTypography.buttonLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AtrioColors.electricViolet,
        textStyle: AtrioTypography.buttonMedium,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AtrioColors.hostSurface,
      selectedColor: AtrioColors.electricViolet.withValues(alpha: 0.25),
      side: const BorderSide(color: AtrioColors.hostCardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: AtrioTypography.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? Colors.black : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.neonLime : AtrioColors.hostSurfaceVariant),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.neonLime : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AtrioColors.neonLime : AtrioColors.hostTextTertiary),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AtrioColors.neonLime,
      thumbColor: AtrioColors.neonLime,
      inactiveTrackColor: AtrioColors.hostSurfaceVariant,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AtrioColors.neonLime,
    ),
    dividerTheme: const DividerThemeData(
      color: AtrioColors.hostDivider,
      thickness: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AtrioColors.hostSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AtrioColors.hostSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AtrioColors.hostSurface,
      contentTextStyle: AtrioTypography.bodyMedium.copyWith(
        color: AtrioColors.hostTextPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
